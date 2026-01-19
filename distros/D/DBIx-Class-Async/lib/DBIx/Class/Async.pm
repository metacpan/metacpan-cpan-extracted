package DBIx::Class::Async;

$DBIx::Class::Async::VERSION   = '0.40';
$DBIx::Class::Async::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

DBIx::Class::Async - Asynchronous database operations for DBIx::Class

=head1 VERSION

Version 0.40

=cut

use strict;
use warnings;
use utf8;

use v5.14;

use CHI;
use Carp;
use Try::Tiny;
use IO::Async::Loop;
use IO::Async::Function;
use Time::HiRes qw(time);
use Digest::MD5 qw(md5_hex);
use Type::Params qw(compile);
use Types::Standard qw(Str ScalarRef HashRef ArrayRef Maybe Int CodeRef);

our $METRICS;

use constant {
    DEFAULT_WORKERS       => 4,
    DEFAULT_CACHE_TTL     => 300,
    DEFAULT_QUERY_TIMEOUT => 30,
    DEFAULT_RETRIES       => 3,
    HEALTH_CHECK_INTERVAL => 300,
};

=head1 DISCLAIMER

B<This is pure experimental currently.>

You are encouraged to try and share your suggestions.

=head1 SYNOPSIS

    use IO::Async::Loop;
    use DBIx::Class::Async;

    my $loop = IO::Async::Loop->new;
    my $db   = DBIx::Class::Async->new(
        schema_class => 'MyApp::Schema',
        connect_info => [
            'dbi:SQLite:dbname=my.db',
            undef,
            undef,
            { sqlite_unicode => 1 },
        ],
        workers   => 2,
        cache_ttl => 60,
        loop      => $loop,
    );

    my $f = $db->search('User', { active => 1 });

    $f->on_done(sub {
        my ($rows) = @_;
        for my $row (@$rows) {
            say $row->{name};
        }
        $loop->stop;
    });

    $f->on_fail(sub {
        warn "Query failed: @_";
        $loop->stop;
    });

    $loop->run;

    $db->disconnect;

=head1 DESCRIPTION

C<DBIx::Class::Async> provides asynchronous access to L<DBIx::Class> using a
process-based worker pool built on L<IO::Async::Function>.

Each worker maintains a persistent database connection and executes blocking
DBIx::Class operations outside the main event loop, returning results via
L<Future> objects.

Returned rows are plain Perl data structures (hashrefs), making results safe
to pass across process boundaries.

Features include:

=over 4

=item * Process-based worker pool using L<IO::Async>

=item * Persistent L<DBIx::Class> connections per worker

=item * Non-blocking CRUD operations via L<Future>

=item * Optional result caching via L<CHI>

=item * Transaction support (single worker only)

=item * Optional retry with exponential backoff

=item * Health checks and graceful shutdown

=back

=head1 CONSTRUCTOR

=head2 new

Creates a new C<DBIx::Class::Async> instance.

    my $async_db = DBIx::Class::Async->new(
        schema_class   => 'MyApp::Schema', # Required
        connect_info   => $connect_info,   # Required
        workers        => 4,               # Optional, default 4
        loop           => $loop,           # Optional IO::Async::Loop
        cache_ttl      => 300,             # Optional cache TTL in secs
        cache          => $chi_object,     # Optional custom cache
        enable_retry   => 1,               # Optional, default 0
        max_retries    => 3,               # Optional, default 3
        retry_delay    => 1,               # Optional, default 1 sec
        query_timeout  => 30,              # Optional, default 30 secs
        enable_metrics => 1,               # Optional, default 0
        health_check   => 300,             # Optional health check interval
        on_connect_do  => $sql_commands,   # Optional SQL to run on connect
    );

Parameters:

=over 4

=item * B<schema_class> (Required)

The L<DBIx::Class::Schema> class name.

=item * B<connect_info> (Required)

Arrayref of connection parameters passed to C<< $schema_class->connect() >>.

=item * B<workers> (Optional, default: 4)

Number of worker processes for the connection pool.

=item * B<loop> (Optional)

L<IO::Async::Loop> instance. A new loop will be created if not provided.

=item * B<cache_ttl> (Optional, default: 300)

Cache time-to-live in seconds. Set to 0 to disable caching.

=item * B<cache> (Optional)

L<CHI> cache object for custom cache configuration.

=item * B<enable_retry> (Optional, default: 0)

Enable automatic retry for deadlocks and timeouts.

=item * B<max_retries> (Optional, default: 3)

Maximum number of retry attempts.

=item * B<retry_delay> (Optional, default: 1)

Initial delay between retries in seconds (uses exponential backoff).

=item * B<query_timeout> (Optional, default: 30)

Query timeout in seconds.

=item * B<enable_metrics> (Optional, default: 0)

Enable metrics collection (requires L<Metrics::Any>).

=item * B<health_check> (Optional, default: 300)

Health check interval in seconds. Set to 0 to disable health checks.

=item * B<on_connect_do> (Optional)

Arrayref of SQL statements to execute after connecting.

=back

=cut

sub new {
    my ($class, %args) = @_;

    my $schema_class = $args{schema_class} or croak "schema_class required";
    my $connect_info = $args{connect_info} or croak "connect_info required";
    my $workers      = $args{workers} || DEFAULT_WORKERS;

    unless (eval { $schema_class->can('connect') } || eval "require $schema_class") {
        croak "Cannot load schema class $schema_class: $@";
    }

    # Handle cache_ttl - default to 300, but if explicitly set to 0, use undef
    my $cache_ttl = $args{cache_ttl};
    if (defined $cache_ttl) {
        $cache_ttl = undef if $cache_ttl == 0;
    }
    else {
        $cache_ttl = DEFAULT_CACHE_TTL;
    }

    my $self = bless {
        schema_class    => $schema_class,
        connect_info    => $connect_info,
        loop            => $args{loop} || IO::Async::Loop->new,
        workers         => [],
        workers_config  => {
            count          => $workers,
            query_timeout  => $args{query_timeout} || DEFAULT_QUERY_TIMEOUT,
            on_connect_do  => $args{on_connect_do} || [],
        },
        cache           => $args{cache} || _build_default_cache($cache_ttl),
        cache_ttl       => $cache_ttl,  # undef means no expiration
        enable_retry    => $args{enable_retry} // 0,
        retry_config    => {
            max_retries => $args{max_retries} || DEFAULT_RETRIES,
            delay       => $args{retry_delay} || 1,
            factor      => 2,  # Exponential backoff
        },
        enable_metrics  => $args{enable_metrics} // 0,
        is_connected    => 1,
        worker_idx      => 0,
        stats           => {
            queries      => 0,
            errors       => 0,
            cache_hits   => 0,
            cache_misses => 0,
            deadlocks    => 0,
            retries      => 0,
        },
    }, $class;

    $self->_init_metrics if $self->{enable_metrics};

    $self->_init_workers;

    if (my $interval = $args{health_check} // HEALTH_CHECK_INTERVAL) {
        $self->_start_health_checks($interval);
    }

    return $self;
}

=head1 METHODS

=head2 count

Counts rows matching conditions.

    my $count = await $async_db->count(
        $resultset_name,
        { active => 1, status => 'pending' }  # Optional
    );

Returns: Integer count.

=cut

sub count {
    my ($self, $resultset, $search_args) = @_;

    # Allow Hash (standard), Array (OR/AND logic), or ScalarRef (Literal SQL)
    state $check = compile(Str, Maybe[ HashRef | ArrayRef | ScalarRef ]);
    $check->($resultset, $search_args);

    $self->{stats}{queries}++;
    $self->_record_metric('inc', 'db_async_queries_total');

    my $start_time = time;

    return $self->_call_worker('count', $resultset, $search_args)->then(sub {
        my ($result) = @_;
        my $duration = time - $start_time;
        $self->_record_metric('observe', 'db_async_query_duration_seconds', $duration);
        return Future->done($result);
    });
}

=head2 create

Creates a new row.

    my $new_row = await $async_db->create(
        $resultset_name,
        { name => 'John', email => 'john@example.com' }
    );

Returns: Hashref of created row data.

=cut

sub create {
    my ($self, $resultset, $data) = @_;

    state $check = compile(Str, HashRef);
    $check->($resultset, $data);

    $self->{stats}{queries}++;
    $self->_record_metric('inc', 'db_async_queries_total');

    $self->_invalidate_cache_for($resultset);

    my $start_time = time;

    return $self->_call_worker('create', $resultset, $data)->then(sub {
        my ($result) = @_;
        my $duration = time - $start_time;
        $self->_record_metric('observe', 'db_async_query_duration_seconds', $duration);
        return Future->done($result);
    });
}

=head2 delete

Deletes a row.

    my $success = await $async_db->delete($resultset_name, $id);

Returns: 1 if deleted, 0 if row not found.

=cut

sub delete {
    my ($self, $resultset, $id) = @_;

    state $check = compile(Str, Int|Str);
    $check->($resultset, $id);

    $self->{stats}{queries}++;
    $self->_record_metric('inc', 'db_async_queries_total');

    $self->_invalidate_cache_for($resultset);
    $self->_invalidate_cache_for("$resultset:$id");

    my $start_time = time;

    return $self->_call_worker('delete', $resultset, $id)->then(sub {
        my ($result) = @_;
        my $duration = time - $start_time;
        $self->_record_metric('observe', 'db_async_query_duration_seconds', $duration);
        return Future->done($result);
    });
}

=head2 deploy

    my $future = $schema->deploy(\%sqlt_args?, $dir?);

    $future->on_done(sub {
        my $self = shift;
        print "Database schema deployed successfully.\n";
    });

=over 4

=item Arguments: C<\%sqlt_args?>, C<$dir?>

=item Return Value: L<Future> resolving to C<$self>

=back

Asynchronously deploys the schema to the database.

This method dispatches the deployment task to a background worker process via
the internal worker pool. This ensures that the often-slow process of
generating SQL (via L<SQL::Translator>) and executing DDL statements does
not block the main application thread or event loop.

The arguments are passed directly to the underlying L<DBIx::Class::Schema/deploy>
method in the worker. Common C<%sqlt_args> include:

=over 4

=item * C<add_drop_table> - Add a C<DROP TABLE> before each C<CREATE>.

=item * C<quote_identifiers> - Toggle database-specific identifier quoting.

=back

If the deployment fails (e.g., due to permission issues or missing dependencies
like L<SQL::Translator>), the returned L<Future> will fail with the error
string returned by the worker.

=cut

sub deploy {
    my ($self, $sqlt_args, $dir) = @_;

    # Use the internal bridge discovered in your search method
    return $self->_call_worker('deploy', $sqlt_args, $dir);
}

=head2 disconnect

Gracefully disconnects all workers and cleans up resources.

    $async_db->disconnect;

=cut

sub disconnect {
    my $self = shift;

    return unless $self->{is_connected};

    # Stop health checks
    if ($self->{health_check_timer}) {
        $self->{loop}->remove($self->{health_check_timer});
        undef $self->{health_check_timer};
    }

    # Stop all workers
    for my $worker (@{$self->{workers}}) {
        if (defined $worker->{instance}) {
            $self->{loop}->remove($worker->{instance});
        }
    }

    $self->{workers} = [];
    $self->{is_connected} = 0;

    # Clear cache
    if (defined $self->{cache}) {
        $self->{cache}->clear;
    }
}

=head2 find

Finds a single row by primary key.

    my $row = await $async_db->find($resultset_name, $id);

Returns: Hashref of row data or undef if not found.

=cut

sub find {
    my ($self, $resultset, $id) = @_;

    state $check = compile(Str, Int|Str);
    $check->($resultset, $id);

    $self->{stats}{queries}++;
    $self->_record_metric('inc', 'db_async_queries_total');

    my $start_time = time;

    return $self->_call_worker('find', $resultset, $id)->then(sub {
        my ($result) = @_;
        my $duration = time - $start_time;
        $self->_record_metric('observe', 'db_async_query_duration_seconds', $duration);
        return Future->done($result);
    });
}

=head2 health_check

Performs health check on all workers.

    my $healthy_workers = await $async_db->health_check;

Returns: Number of healthy workers.

=cut

sub health_check {
    my $self = shift;

    my @checks = map {
        my $worker_info = $_;
        my $worker = $worker_info->{instance};
        $worker->call(
            args => [
                $self->{schema_class},
                $self->{connect_info},
                $self->{workers_config},
                'health_check',
            ],
            timeout => 5,
        )->then(sub {
            $worker_info->{healthy} = 1;
            return Future->done(1);
        }, sub {
            $worker_info->{healthy} = 0;
            return Future->done(0);
        })
    } @{$self->{workers}};

    return Future->wait_all(@checks)->then(sub {
        my @results = @_;
        my $healthy_count = grep { $_->get } @results;

        $self->_record_metric('set', 'db_async_workers_active', $healthy_count);

        return Future->done($healthy_count);
    });
}

=head2 loop

Returns the L<IO::Async::Loop> instance.

    my $loop = $async_db->loop;

=cut

sub loop {
    my $self = shift;
    return $self->{loop};
}

=head2 raw_query

Executes raw SQL query.

    my $results = await $async_db->raw_query(
        'SELECT * FROM users WHERE age > ? AND status = ?',
        [25, 'active']  # Optional bind values
    );

Returns: Arrayref of hashrefs.

=cut

sub raw_query {
    my ($self, $query, $bind_values) = @_;

    state $check = compile(Str, Maybe[ArrayRef]);
    $check->($query, $bind_values);

    $self->{stats}{queries}++;
    $self->_record_metric('inc', 'db_async_queries_total');

    my $start_time = time;

    return $self->_call_worker('raw_query', $query, $bind_values)->then(sub {
        my ($result) = @_;
        my $duration = time - $start_time;
        $self->_record_metric('observe', 'db_async_query_duration_seconds', $duration);
        return Future->done($result);
    });
}

=head2 schema_class

Returns the schema class name.

    my $class = $async_db->schema_class;

=cut

sub schema_class {
    my $self = shift;
    return $self->{schema_class};
}

=head2 search

Performs a search query.

    my $results = await $async_db->search(
        $resultset_name,
        $search_conditions,    # Optional hashref
        $attributes,           # Optional hashref
    );

Attributes may include:

    {
        order_by  => 'name DESC',
        rows      => 50,
        page      => 2,
        columns   => [qw/id name/],
        prefetch  => 'relation',
        cache     => 1,
        cache_key => 'custom_key',
    }

All results are returned as arrayrefs of hashrefs.

=cut

sub search {
    my ($self, $resultset, $search_args, $attrs) = @_;

    # Change HashRef to allow ArrayRef and ScalarRef (for literal SQL)
    state $check = compile(Str, Maybe[ HashRef | ArrayRef | ScalarRef ], Maybe[HashRef]);
    $check->($resultset, $search_args, $attrs);

    $self->{stats}{queries}++;
    $self->_record_metric('inc', 'db_async_queries_total');

    my $cache_key = delete $attrs->{cache_key} // _generate_cache_key('search', $resultset, $search_args, $attrs);
    my $use_cache = exists $attrs->{cache} ? delete $attrs->{cache} : defined $self->{cache_ttl};

    if ($use_cache) {
        my $cached = $self->{cache}->get($cache_key);
        if ($cached) {
            $self->{stats}{cache_hits}++;
            $self->_record_metric('inc', 'db_async_cache_hits_total');
            return Future->done($cached);
        }
        $self->{stats}{cache_misses}++;
        $self->_record_metric('inc', 'db_async_cache_misses_total');
    }

    my $start_time = time;

    my $future = $self->{enable_retry}
        ? $self->_call_with_retry('search', $resultset, $search_args, $attrs)
        : $self->_call_worker('search', $resultset, $search_args, $attrs);

    return $future->then(sub {
        my ($result) = @_;

        my $duration = time - $start_time;
        $self->_record_metric('observe', 'db_async_query_duration_seconds', $duration);

        if ($use_cache && defined $self->{cache_ttl}) {
            $self->{cache}->set($cache_key, $result, $self->{cache_ttl});
        }

        return Future->done($result);
    });
}

=head2 search_multi

Executes multiple search queries concurrently.

    my @results = await $async_db->search_multi(
        ['User',    { active => 1 }, { rows => 10 }],
        ['Product', { category => 'books' }],
        ['Order',   undef, { order_by => 'created_at DESC', rows => 5 }],
    );

Returns: Array of results in the same order as queries.

=cut

sub search_multi {
    my ($self, @queries) = @_;

    $self->{stats}{queries} += scalar @queries;
    $self->_record_metric('inc', 'db_async_queries_total', scalar @queries);

    my @futures = map {
        my ($resultset, $search_args, $attrs) = @$_;
        $self->_call_worker('search', $resultset, $search_args, $attrs)
    } @queries;

    my $start_time = time;

    return Future->wait_all(@futures)->then(sub {
        my @results = @_;

        my $duration = time - $start_time;
        $self->_record_metric('observe', 'db_async_query_duration_seconds', $duration);

        # Extract values from completed futures
        my @values = map { $_->get } @results;

        return Future->done(@values);
    });
}

=head2 search_with_prefetch

    my $future = $async_db->search_with_prefetch(
        $source_name,
        \%condition,
        $prefetch_spec,
        \%extra_attributes
    );

Performs an asynchronous search while eager-loading related data. This method
is specifically designed to solve the "N+1 query" problem in an asynchronous
environment.

Arguments:

=over 4

=item * C<$source_name>: The name of the ResultSource (e.g., 'User').

=item * C<\%condition>: A standard C<DBIx::Class> search condition.

=item * C<$prefetch_spec>: A standard C<prefetch> attribute (string, arrayref, or hashref).

=item * C<\%extra_attributes>: Optional search attributes (order_by, rows, etc.).

=back

This method performs "Deep Serialiisation." Since C<DBIx::Class> row objects
contain live database handles that cannot be sent across process boundaries,
this method ensures that the background worker:

=over 4

=item 1. Executes the join and B<collapses> the result set to avoid duplicate parent rows.

=item 2. Recursively converts the nested object tree into a transportable data structure.

=item 3. Transports the data to the parent process where it is re-inflated into
L<DBIx::Class::Async::Row> objects, with the relationship data accessible
via standard accessors.

=back

B<Note:> Unlike standard C<DBIx::Class>, accessing a relationship that was
B<not> prefetched will fail, as the result row does not have a persistent
connection to the database in the parent process.

=cut

sub search_with_prefetch {
    my ($self, $source_name, $cond, $prefetch, $attrs) = @_;
    $attrs ||= {};

    # We force these into the attributes so execute_operation sees them
    $attrs->{prefetch} = $prefetch;
    $attrs->{collapse} = 1;

    # We call our existing async search, which eventually
    # triggers execute_operation in the worker
    return $self->search($source_name, $cond, $attrs);
}

=head2 stats

Returns statistics about database operations.

    my $stats = $async_db->stats;

Returns: Hashref with query counts, cache hits, errors, etc.

=cut

sub stats {
    my $self = shift;
    return { %{$self->{stats}} };  # Return copy
}

=head2 txn_batch

Executes a batch of operations within a transaction. This is the recommended
alternative to C<txn_do> as it avoids CODE reference serialisation issues.

    my $result = await $async_db->txn_batch(
        # Update operations
        { type => 'update', resultset => 'Account', id => 1,
          data => { balance => \'balance - 100' } },
        { type => 'update', resultset => 'Account', id => 2,
          data => { balance => \'balance + 100' } },

        # Create operation
        { type => 'create', resultset => 'Log',
          data => { event => 'transfer', amount => 100, timestamp => \'NOW()' } },
    );

    # Returns count of successful operations
    say "Executed $result operations in transaction";

Supported operation types:

=over 4

=item * B<update> - Update an existing record

    {
        type      => 'update',
        resultset => 'User',       # ResultSet name
        id        => 123,          # Primary key value
        data      => { name => 'New Name', status => 'active' }
    }

=item * B<create> - Create a new record

    {
        type      => 'create',
        resultset => 'Order',
        data      => { user_id => 1, amount => 99.99, status => 'pending' }
    }

=item * B<delete> - Delete a record

    {
        type      => 'delete',
        resultset => 'Session',
        id        => 456
    }

=item * B<raw> - Execute raw SQL (Atomic)

    {
        type => 'raw',
        sql  => 'UPDATE accounts SET balance = balance - ? WHERE id = ?',
        bind => [100, 1]
    }

Executes a raw SQL statement via the worker's database handle. B<Note:> Always
use placeholders (C<?> and the C<bind> attribute) to prevent SQL injection.

=back

B<Literal SQL Support>

All C<data> hashes support standard L<DBIx::Class> literal SQL via scalar
references, for example: C<< data => { updated_at => \'NOW()' } >>. These are
safely serialized and executed within the worker transaction.

B<Atomicity and Error Handling>

All operations within the batch are wrapped in a single database transaction.
If any operation fails (e.g., a constraint violation or a missing record),
the worker will immediately:

=over 4

=item 1. Roll back all changes made within that batch.

=item 2. Fail the L<Future> in the parent process with the specific error message.

=back

=cut

sub txn_batch {
    my $self = shift;

    # Allow both txn_batch([$h1, $h2]) and txn_batch($h1, $h2)
    my @operations = (ref $_[0] eq 'ARRAY') ? @{$_[0]} : @_;

    # 1. Validate operations
    for my $op (@operations) {
        unless (ref $op eq 'HASH' && $op->{type}) {
            croak "Each operation must be a hashref with 'type' key";
        }

        if ($op->{type} eq 'update' || $op->{type} eq 'delete') {
            croak "Operation type '$op->{type}' requires 'id' parameter"
                unless exists $op->{id};
        }

        if ($op->{type} eq 'update' || $op->{type} eq 'create') {
            croak "Operation type '$op->{type}' requires 'data' parameter"
                unless ref $op->{data} eq 'HASH';
        }

        if ($op->{type} eq 'raw') {
            croak "Operation type 'raw' requires 'sql' parameter"
                unless $op->{sql};
        }
    }

    # 2. Stats and Cache
    $self->{stats}{queries}++;
    $self->_record_metric('inc', 'db_async_queries_total');

    if (defined $self->{cache_ttl} && $self->{cache_ttl} > 0) {
        $self->{cache}->clear;
    }

    my $start_time = time;

    # 3. Execution
    return $self->_call_worker('txn_batch', \@operations)->then(sub {
        my ($result) = @_;
        my $duration = time - $start_time;
        $self->_record_metric('observe', 'db_async_query_duration_seconds', $duration);
        return Future->done($result);
    })->catch(sub {
        my ($error) = @_;
        return Future->fail("Batch Transaction Failed: $error");
    });
}

=head2 txn_do

Executes a transaction.

    my $result = await $async_db->txn_do(sub {
        my $schema = shift;

        # Multiple operations that should succeed or fail together
        $schema->resultset('Account')->find(1)->update({ balance => \'balance - 100' });
        $schema->resultset('Account')->find(2)->update({ balance => \'balance + 100' });

        return 'transfer_complete';
    });

The callback receives a L<DBIx::Class::Schema> instance and should return the
transaction result.

B<IMPORTANT:> This method has limitations due to serialisation constraints.
The CODE reference passed to C<txn_do> must be serialisable by L<Sereal>,
which may not support anonymous subroutines or CODE references with closed
over variables in all configurations.

If you encounter serialisation errors, consider:

=over 4

=item * Using named subroutines instead of anonymous ones

=item * Recompiling L<Sereal> with C<ENABLE_SRL_CODEREF> support

=item * Using individual async operations instead of transactions

=item * Using the C<txn_batch> method for predefined operations

=back

Common error: C<Found type 13 CODE(...), but it is not representable by the
Sereal encoding format>

=cut

sub txn_do {
    my ($self, $code) = @_;

    state $check = compile(CodeRef);
    $check->($code);

    $self->{stats}{queries}++;
    $self->_record_metric('inc', 'db_async_queries_total');

    if (defined $self->{cache_ttl} && $self->{cache_ttl} > 0) {
        $self->{cache}->clear;
    }

    my $start_time = time;

    # Try to pass the CODE ref directly - this might fail with Sereal
    # but let the error propagate naturally
    return $self->_call_worker('txn_do', $code)->then(sub {
        my ($result) = @_;
        my $duration = time - $start_time;
        $self->_record_metric('observe', 'db_async_query_duration_seconds', $duration);
        return Future->done($result);
    })->catch(sub {
        my $error = shift;
        # If it fails due to serialisation, provide a better error message
        if ($error =~ /not representable by the Sereal encoding format/) {
            return Future->fail(
                "txn_do cannot serialise CODE references through IO::Async workers. " .
                "Consider using individual async methods or a different approach."
            );
        }
        return Future->fail($error);
    });
}

=head2 update

Updates an existing row.

    my $updated_row = await $async_db->update(
        $resultset_name,
        $id,
        { name => 'Jane', status => 'active' }
    );

Returns: Hashref of updated row data or undef if row not found.

=cut

sub update {
    my ($self, $resultset, $id, $data) = @_;

    state $check = compile(Str, Int|Str, HashRef);
    $check->($resultset, $id, $data);

    $self->{stats}{queries}++;
    $self->_record_metric('inc', 'db_async_queries_total');

    $self->_invalidate_cache_for($resultset);
    $self->_invalidate_cache_for("$resultset:$id");

    my $start_time = time;

    return $self->_call_worker('update', $resultset, $id, $data)->then(sub {
        my ($result) = @_;
        my $duration = time - $start_time;
        $self->_record_metric('observe', 'db_async_query_duration_seconds', $duration);
        return Future->done($result);
    });
}

=head2 update_bulk

    $db->update_bulk($table, $condition, $data);

Performs a bulk update operation on multiple rows in the specified table.

This method updates all rows in the given table that match the specified
conditions with the provided data values. It is particularly useful for
batch operations where multiple records need to be modified with the same
set of changes.

=over 4

=item Parameters

=over 8

=item C<$table>

The name of the table to update (String, required).

=item C<$condition>

A hash reference specifying the WHERE conditions for selecting rows to update.
Each key-value pair in the hash represents a column and its required value.
Rows matching ALL conditions will be updated (HashRef, required).

Example: C<< { status => 'pending', active => 1 } >>

=item C<$data>

A hash reference containing the column-value pairs to update.
Each key-value pair specifies a column and its new value (HashRef, required).

Example: C<< { status => 'processed', updated_at => '2024-01-01 10:00:00' } >>

=back

=item Returns

Returns the result of the update operation from the worker. Typically this
would be the number of rows affected or a success indicator, depending on
your worker implementation.

=item Exceptions

=over 4

=item *

Throws a validation error if any parameter does not match the expected type.

=item *

Throws an exception if the underlying worker call fails.

=back

=item Examples

    # Update all pending orders from a specific customer
    my $result = $db->update_bulk(
        'orders',
        { customer_id => 123, status => 'pending' },
        { status      => 'processed', processed_at => \'NOW()' }
    );

    print "Updated $result rows\n";

    # Deactivate all users who haven't logged in since 2023
    $db->update_bulk(
        'users',
        { last_login => { '<' => '2023-01-01' } },
        { active     => 0, deactivation_date => \'CURRENT_DATE' }
    );

=back

=cut

sub update_bulk {
    my ($self, $table, $condition, $data) = @_;

    state $check = compile(Str, HashRef, HashRef);
    $check->($table, $condition, $data);

    return $self->_call_worker('update_bulk', $table, $condition, $data);
}

#
#
# INTERNAL METHODS

sub _record_metric {
    my ($self, $type, $name, @args) = @_;

    return unless $self->{enable_metrics} && defined $METRICS;

    if ($type eq 'inc') {
        $METRICS->inc($name, @args);
    } elsif ($type eq 'observe') {
        $METRICS->observe($name, @args);
    } elsif ($type eq 'set') {
        $METRICS->set($name, @args);
    }
}

sub _generate_cache_key {
    my ($operation, @args) = @_;

    # The first element of @args is almost always the ResultSource name
    # (e.g., 'User', 'Order'). We extract it to use as a searchable prefix.
    my $source_prefix = (defined $args[0] && !ref $args[0]) ? $args[0] : 'global';

    my @clean_args = map {
        if (!defined $_) {
            'UNDEF';
        } elsif (ref $_ eq 'HASH') {
            my $hashref = $_;
            join(',', sort map { "$_=>$hashref->{$_}" } keys %$hashref);
        } elsif (ref $_ eq 'ARRAY') {
            # Deep join for nested arrays (prefetch/columns)
            join(',', map { ref $_ ? 'REF' : ($_ // 'UNDEF') } @$_);
        } elsif (ref $_ eq 'SCALAR') {
            # Handle Literal SQL like \'NOW()'
            ${$_};
        } else {
            $_;
        }
    } @args;

    return join(':', $source_prefix, $operation, md5_hex(join('|', @clean_args)));
}

sub _build_default_cache {
    my ($ttl) = @_;

    my %params = (
        driver => 'Memory',
        global => 1,
    );

    # Add expires_in only if ttl is defined (undef means never expire in CHI)
    $params{expires_in} = $ttl if defined $ttl;

    return CHI->new(%params);
}

sub _init_metrics {
    my $self = shift;

    # Try to load Metrics::Any
    eval {
        require Metrics::Any;
        Metrics::Any->import('$METRICS');

        # Initialise metrics
        $METRICS->make_counter('db_async_queries_total');
        $METRICS->make_counter('db_async_cache_hits_total');
        $METRICS->make_counter('db_async_cache_misses_total');
        $METRICS->make_histogram('db_async_query_duration_seconds');
        $METRICS->make_gauge('db_async_workers_active');

    };

    # Silently ignore if Metrics::Any is not available
    if ($@) {
        $self->{enable_metrics} = 0;
        undef $METRICS;
    }
}

sub _init_workers {
    my $self = shift;

    for my $worker_id (1..$self->{workers_config}{count}) {
        my $worker = IO::Async::Function->new(
            code => sub {
                use feature 'state';
                my ($schema_class, $connect_info, $worker_config, $operation, @op_args) = @_;

                # Get worker PID for state management
                my $pid = $$;

                # Create or reuse schema connection
                state $schema_cache = {};

                unless (exists $schema_cache->{$pid}) {
                    # Load schema class in worker process
                    eval "require $schema_class; 1;" or do {
                        my $error = $@ || 'Unknown error loading schema class';
                        die "Failed to load schema class $schema_class: $error";
                    };

                    # Verify the class loaded correctly
                    unless ($schema_class->can('connect')) {
                        die "Schema class $schema_class does not provide 'connect' method";
                    }

                    # Connect to database with error handling
                    my $schema = eval {
                        $schema_class->connect(@$connect_info);
                    };

                    if ($@) {
                        die "Failed to connect to database: $@";
                    }

                    unless (defined $schema) {
                        die "Schema connection returned undef";
                    }

                    $schema_cache->{$pid} = $schema;

                    # Execute on_connect_do statements
                    if (@{$worker_config->{on_connect_do}}) {
                        eval {
                            my $storage = $schema_cache->{$pid}->storage;
                            my $dbh = $storage->dbh;
                            $dbh->do($_) for @{$worker_config->{on_connect_do}};
                        };
                        if ($@) {
                            warn "on_connect_do failed: $@";
                        }
                    }

                    # Set connection attributes
                    eval {
                        $schema_cache->{$pid}->storage->debug(0) unless $ENV{DBIC_TRACE};
                    };

                    # Verify schema instance has sources
                    eval {
                        my @instance_sources = $schema_cache->{$pid}->sources;
                        unless (@instance_sources) {
                            # Try to force reload the schema
                            delete $schema_cache->{$pid};
                            die "Connected schema instance has no registered sources";
                        }
                    };
                    if ($@) {
                        # If sources check failed, don't cache this connection
                        delete $schema_cache->{$pid};
                        die "Schema validation failed: $@";
                    }
                }

                # Execute operation with timeout
                local $SIG{ALRM} = sub {
                    die "Query timeout after $worker_config->{query_timeout} seconds\n"
                };

                alarm($worker_config->{query_timeout});

                my $result;
                eval {
                    $result = _execute_operation($schema_cache->{$pid}, $operation, @op_args);
                };
                my $error = $@;

                alarm(0);

                if ($error) {
                    die $error;
                }

                return $result;
            },
            max_workers => 1,  # One process per worker
        );

        $self->{loop}->add($worker);
        push @{$self->{workers}}, {
            instance => $worker,
            healthy  => 1,
            pid      => undef,  # Will be set on first use
        };
    }
}

sub _start_health_checks {
    my ($self, $interval) = @_;

    return if $interval <= 0;

    # Try to create the timer
    eval {
        $self->{health_check_timer} = $self->{loop}->repeat(
            interval => $interval,
            code => sub {
                # Don't use async here - just fire and forget
                $self->health_check->retain;
            },
        );
    };

    if ($@) {
        # If repeat fails, try a different approach or disable health checks
        warn "Failed to start health checks: $@" if $ENV{DBIC_ASYNC_DEBUG};
    }
}

sub _serialise_row_with_prefetch {
    my ($row, $prefetch) = @_;
    return unless $row;

    # 1. Get the base columns
    my %data = $row->get_columns;

    # 2. Process Prefetches
    if ($prefetch) {
        # Normalise prefetch into a hash for easier recursion
        # (Handles strings, arrays, and nested hashes like { comments => 'user' })
        my $spec = _normalise_prefetch($prefetch);

        foreach my $rel (keys %$spec) {
            # Check if DBIC actually prefetched this relationship
            # we check if the object has the related object already 'inflated'
            if ($row->has_column_loaded($rel) || $row->can($rel)) {
                my $related = eval { $row->$rel };
                next if $@ || !defined $related;

                if (ref($related) eq 'DBIx::Class::ResultSet' || eval { $related->isa('DBIx::Class::ResultSet') }) {
                    # has_many relationship
                    # Only call ->all if we are sure we want to fetch/serialise these
                    my @items = $related->all;
                    $data{$rel} = [
                        map { _serialise_row_with_prefetch($_, $spec->{$rel}) } @items
                    ];
                } elsif (eval { $related->isa('DBIx::Class::Row') }) {
                    # single relationship (belongs_to / might_have)
                    $data{$rel} = _serialise_row_with_prefetch($related, $spec->{$rel});
                }
            }
        }
    }

    return \%data;
}

sub _normalise_prefetch {
    my $p = shift;
    return {} unless $p;
    return { $p => undef } if !ref $p;
    return { map { $_ => undef } @$p } if ref $p eq 'ARRAY';
    return $p if ref $p eq 'HASH';
    return {};
}

sub _execute_operation {
    my ($schema, $operation, @args) = @_;

    if ($operation eq 'search') {
        my ($resultset, $search_args, $attrs) = @args;

        my $results = eval {
            my $rs = $schema->resultset($resultset);

            # Use collapse if prefetch is present to avoid duplicate parent rows
            if ($attrs->{prefetch}) {
                $attrs->{collapse} = 1;
            }

            $rs = $rs->search($search_args || {}, $attrs || {});
            my @rows = $rs->all;

            # 1. If user used HashRefInflator, rows are already plain hashes
            if (($attrs->{result_class} || '') =~ /HashRefInflator/) {
                return [ map { { %$_, _in_storage => 1 } } @rows ];
            }

            # 2. Otherwise, we must recursively turn Objects into Nested Hashes
            my @results = map {
                _serialise_row_with_prefetch($_, $attrs->{prefetch})
            } @rows;

            \@results;
        };

        if ($@) {
            die "Search operation failed: $@";
        }

        return $results;
    }
    elsif ($operation eq 'find') {
        my ($source_name, $id, $attrs) = @args;

        my $row = eval {
            $schema->resultset($source_name)->find($id, $attrs || {})
        };

        if ($@) { die "Find operation failed on $source_name: $@"; }

        return $row ? _serialise_row_with_prefetch($row, $attrs->{prefetch}) : undef;
    }
    elsif ($operation eq 'create') {
        my ($source_name, $data) = @args;
        try {
            my $rs  = $schema->resultset($source_name);
            my $row = $rs->create($data);

            $row->discard_changes;

            return { $row->get_columns };
        }
        catch {
            return { __error => $_ };
        }
    }
    elsif ($operation eq 'populate') {
        my ($source_name, $data) = @args;
        try {
            my $rs = $schema->resultset($source_name);

            # DBIC's populate returns objects or data depending on context.
            # Here we call it and ensure we return the column data for the async side
            # to re-inflate into objects.
            my @rows = $rs->populate($data);

            return [ map { { $_->get_columns } } @rows ];
        }
        catch {
            return { __error => $_ };
        }
    }
    elsif ($operation eq 'populate_bulk') {
        my ($source_name, $data) = @args;
        try {
            # Calling in void context triggers DBIC's fast path
            $schema->resultset($source_name)->populate($data);
            return { success => 1 };
        }
        catch {
            return { __error => $_ };
        }
    }
    elsif ($operation eq 'update') {
        # @args contains (source_name, id, data_to_update, attrs)
        my ($source_name, $id, $data, $attrs) = @args;

        my $results = eval {
            my $rs  = $schema->resultset($source_name);
            my $row = $rs->find($id);

            return undef unless $row;

            $row->update($data);

            return _serialise_row_with_prefetch($row, $attrs->{prefetch});
        };

        if ($@) { die "Update operation failed on $source_name: $@"; }
        return $results;
    }
    elsif ($operation eq 'update_bulk') {
        my ($source_name, $condition, $data) = @args;

        # Use eval or your try/catch, but ensure the error propagates
        my $count = eval {
            my $rs = $schema->resultset($source_name);
            $rs = $rs->search($condition) if $condition && %$condition;

            # This executes a single UPDATE statement in the DB
            $rs->update($data);
        };

        if ($@) {
            # Log the error or re-throw so the Future in the main process fails
            die "Bulk update failed on $source_name: $@";
        }

        return $count; # Returns number of rows updated
    }
    elsif ($operation eq 'delete') {
        # @args: (source_name, id, attrs)
        my ($source_name, $id, $attrs) = @args;

        my $result = eval {
            my $rs = $schema->resultset($source_name);
            my $row = $rs->find($id);

            unless ($row) {
                return 0;
            }

            $row->delete;
            return 1;
        };

        # CRITICAL: Only die if there is an actual exception in $@
        if ($@) {
            my $err = $@ || 'No error message captured';
            # Check if the error is a reference (like a DBIC error object)
            $err = $err->{msg} if ref $err eq 'HASH' && $err->{msg};
            die "Delete operation failed on $source_name for ID $id: $err";
        };

        return $result;
    }
    elsif ($operation eq 'count') {
        my ($source_name, $search_args, $attrs) = @args;

        my $count = eval {
            my $rs = $schema->resultset($source_name);
            # Ensure we have hashes to avoid "Not a HASH reference" errors in DBIC
            $rs->search($search_args || {}, $attrs || {})->count;
        };

        if ($@) {
            my $err = $@ || 'Unknown DBIC count error';
            die "Count operation failed on $source_name: $err";
        }

        return $count;
    }
    elsif ($operation eq 'raw_query') {
        my ($query, $bind_values) = @args;
        my $sth = $schema->storage->dbh->prepare($query);
        $sth->execute(@{$bind_values || []});
        return $sth->fetchall_arrayref({});
    }
    elsif ($operation eq 'txn_do') {
        my ($code) = @args;
        return $schema->txn_do($code);
    }
    elsif ($operation eq 'txn_batch') {
        my ($operations) = @args;

        return $schema->txn_do(sub {
            my $success_count = 0;

            foreach my $op (@$operations) {
                if ($op->{type} eq 'update') {
                    my $row = $schema->resultset($op->{resultset})->find($op->{id});
                    croak "Record not found for update: $op->{resultset} ID $op->{id}"
                        unless $row;
                    $row->update($op->{data});
                    $success_count++;
                }
                elsif ($op->{type} eq 'create') {
                    $schema->resultset($op->{resultset})->create($op->{data});
                    $success_count++;
                }
                elsif ($op->{type} eq 'delete') {
                    my $row = $schema->resultset($op->{resultset})->find($op->{id});
                    croak "Record not found for delete: $op->{resultset} ID $op->{id}"
                        unless $row;
                    $row->delete;
                    $success_count++;
                }
                elsif ($op->{type} eq 'raw') {
                    my $sth = $schema->storage->dbh->prepare($op->{sql});
                    $sth->execute(@{$op->{bind} || []});
                    $success_count++;
                }
                else {
                    croak "Unknown operation type: $op->{type}";
                }
            }

            return $success_count;
        });
    }
    elsif ($operation eq 'search_with_prefetch') {
        my ($resultset, $search_args, $prefetch, $attrs) = @args;
        $attrs ||= {};
        $attrs->{prefetch} = $prefetch;

        my $rs = $schema->resultset($resultset)->search($search_args || {}, $attrs);
        return [ map { _inflate_row_with_prefetch($_, $prefetch) } $rs->all ];
    }
    elsif ($operation eq 'health_check') {
        eval {
            $schema->storage->dbh->ping;
            $schema->storage->dbh->do('SELECT 1');
        };
        return $@ ? 0 : 1;
    }
    elsif ($operation eq 'deploy') {
        my ($sqlt_args, $dir) = @args;

        eval {
            $schema->deploy($sqlt_args || {}, $dir);
        };

        if ($@) {
            return { __error => "Deploy operation failed: $@" };
        }

        return { success => 1 };
    }
    else {
        die "Unknown operation: $operation";
    }
}

sub _inflate_row_with_prefetch {
    my ($row, $prefetch) = @_;

    my $result = {$row->get_columns};

    # Handle both single relationship and array of relationships
    my @rel_names = ref $prefetch eq 'ARRAY' ? @$prefetch : ($prefetch);

    foreach my $rel_name (@rel_names) {
        # Check if prefetched data exists in related_resultsets
        if (my $related_resultsets = $row->{related_resultsets}) {
            if (my $prefetched_data = $related_resultsets->{$rel_name}) {
                # If it has an all() method (ResultSet), call it to get rows
                if (ref $prefetched_data && $prefetched_data->can('all')) {
                    my @related_rows = $prefetched_data->all;
                    if (@related_rows) {
                        $result->{$rel_name} = [ map { {$_->get_columns} } @related_rows ];
                    }
                }
                # Already have rows (arrayref)
                elsif (ref $prefetched_data eq 'ARRAY') {
                    $result->{$rel_name} = [ map { {$_->get_columns} } @$prefetched_data ];
                }
                # Single row object
                elsif (ref $prefetched_data) {
                    $result->{$rel_name} = {$prefetched_data->get_columns};
                }
            }
        }
    }

    return $result;
}

sub _next_worker {
    my $self = shift;

    # Simple round-robin selection
    my $idx    = $self->{worker_idx};
    my $worker = $self->{workers}[$idx];

    $self->{worker_idx} = ($idx + 1) % @{$self->{workers}};

    return $worker->{instance};
}

sub _call_worker {
    my ($self, $operation, @args) = @_;

    my $worker = $self->_next_worker;

    return $worker->call(
        args => [
            $self->{schema_class},
            $self->{connect_info},
            $self->{workers_config},
            $operation,
            @args,
        ],
        timeout => $self->{workers_config}{query_timeout},
    );
}

sub _call_with_retry {
    my ($self, $operation, @args) = @_;

    my $retry_config = $self->{retry_config};
    my $max_retries  = $retry_config->{max_retries};
    my $delay        = $retry_config->{delay};
    my $factor       = $retry_config->{factor};

    # Start with the initial call
    my $future = $self->_call_worker($operation, @args);

    # Add retry handlers
    for my $retry_num (1..$max_retries) {
        $future = $future->catch(sub {
            my $error = shift;

            # Check if this error should be retried
            return Future->fail($error) unless $self->_should_retry_error($error);

            $self->{stats}{retries}++;

            # Calculate delay with exponential backoff
            my $current_delay = $delay * ($factor ** ($retry_num - 1));

            # Delay then retry with a fresh call
            return $self->{loop}->delay_future(after => $current_delay)
                ->then(sub {
                    return $self->_call_worker($operation, @args);
                });
        });
    }

    return $future;
}

sub _should_retry_error {
    my ($self, $error) = @_;

    # Retry on deadlocks, lock timeouts, and connection issues
    return 1 if $error =~ /deadlock|lock wait timeout exceeded|timeout/i;
    return 1 if $error =~ /MySQL server has gone away|Lost connection to MySQL server/i;
    return 1 if $error =~ /connection.*closed|socket.*closed/i;

    # Don't retry on validation errors or other application errors
    return 0 if $error =~ /unique constraint|duplicate entry|validation failed/i;
    return 0 if $error =~ /syntax error|unknown column|table.*doesn't exist/i;

    return 0;
}

sub _invalidate_cache_for {
   my ($self, $pattern) = @_;

   return unless defined $self->{cache_ttl} && $self->{cache_ttl} > 0;

   # Simple pattern-based invalidation
   my @keys = grep { /$pattern/ } $self->{cache}->get_keys;
   $self->{cache}->remove($_) for @keys;
}

sub DESTROY {
    my $self = shift;
    $self->disconnect if $self->{is_connected};
}

=head1 PERFORMANCE TIPS

=over 4

=item * Worker Count

Adjust the C<workers> parameter based on your database connection limits and
expected concurrency. Typically 2-4 workers per CPU core works well.

=item * Caching

Use caching for read-heavy workloads. Set C<cache_ttl> appropriately for your
data volatility.

=item * Batch Operations

Use C<search_multi> for fetching unrelated data concurrently rather than
sequential C<await> calls.

=item * Connection Pooling

Each worker maintains its own persistent connection. Monitor database
connection counts if using many instances.

=item * Timeouts

Set appropriate C<query_timeout> values to prevent hung queries from
blocking workers.

=back

=head1 ERROR HANDLING

All methods throw exceptions on failure. Common error scenarios:

=over 4

=item * Database connection failures

Thrown during initial connection or health checks.

=item * Query timeouts

Thrown when queries exceed C<query_timeout>.

=item * Deadlocks

Automatically retried if C<enable_retry> is true.

=item * Invalid SQL/schema errors

Passed through from DBIx::Class.

=back

Use C<try/catch> blocks or C<< ->catch >> on futures to handle errors.

=head1 METRICS

When C<enable_metrics> is true and L<Metrics::Any> is installed, the module
collects:

=over 4

=item * C<db_async_queries_total> - Total query count

=item * C<db_async_cache_hits_total> - Cache hit count

=item * C<db_async_cache_misses_total> - Cache miss count

=item * C<db_async_query_duration_seconds> - Query duration histogram

=item * C<db_async_workers_active> - Active worker count

=back

=head1 LIMITATIONS

=over 4

=item * Result objects

Returned rows are plain hashrefs, not L<DBIx::Class> row objects.

=item * Transactions

Transactions execute on a single worker only.

=item * Large result sets

All rows are loaded into memory. Use pagination for large datasets.

=back

=head1 DEDICATION

This module is dedicated to the memory of B<Matt S. Trout (mst)>,
a brilliant contributor to the Perl community, L<DBIx::Class> core developer,
and friend who is deeply missed.

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/DBIx-Class-Async>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/DBIx-Class-Async/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Async

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/DBIx-Class-Async/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Async>

=item * Search MetaCPAN

L<https://metacpan.org/dist/DBIx-Class-Async/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of DBIx::Class::Async
