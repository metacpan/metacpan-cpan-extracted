package DBIx::Class::Async::ResultSet;

$DBIx::Class::Async::ResultSet::VERSION   = '0.64';
$DBIx::Class::Async::ResultSet::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

DBIx::Class::Async::ResultSet - Non-blocking resultset proxy with Future-based execution

=head1 VERSION

Version 0.64

=head1 SYNOPSIS

    my $rs = $schema->resultset('User')->search({ active => 1 });

    # Async execution using Futures
    $rs->all->then(sub {
        my $users = shift; # Arrayref of DBIx::Class::Async::Row objects
        foreach my $user (@$users) {
            print "Found: " . $user->username . "\n";
        }
    })->retain;

    # Using the await helper
    my $count = $schema->await( $rs->count );

=head1 DESCRIPTION

This class provides an asynchronous interface to L<DBIx::Class::ResultSet>. Most
methods that would normally perform I/O (like C<all>, C<count>, or C<create>)
return a L<Future> object instead of raw data.

=cut

use strict;
use warnings;
use utf8;
use v5.14;

use Carp;
use Future;
use Data::Dumper;
use Scalar::Util 'blessed';
use DBIx::Class::Async;
use DBIx::Class::Async::Row;
use DBIx::Class::Async::ResultSetColumn;
use DBIx::Class::Async::SelectNormaliser;

use constant ASYNC_TRACE => $ENV{ASYNC_TRACE} || 0;

my %ACCUMULATING_ATTRS = map { $_ => 1 } qw(
    join
    prefetch
    columns
    +columns
    select
    as
    order_by
    group_by
    having
);

my %DATETIME_COLUMN_TYPES = map { $_ => 1 } qw(
    datetime timestamp timestamptz
    timestamp\ with\ time\ zone
    timestamp\ without\ time\ zone
    date time
);

=head1 METHODS

=head2 new

    my $rs = DBIx::Class::Async::ResultSet->new(
        schema_instance => $schema,
        source_name     => 'User',
        cond            => { is_active => 1 },
        attrs           => { order_by => 'created_at' },
    );

Instantiates a new asynchronous ResultSet. While typically called internally
by C<< $schema->resultset('Source') >>, it can be used to manually construct
a result set with a specific state.

=over 4

=item * Required Arguments

=over 4

=item * C<schema_instance>: The L<DBIx::Class::Async::Schema> object.

=item * C<source_name>: The string name of the ResultSource (e.g., 'User').

=back

=item * Optional Arguments

=over 4

=item * C<async_db>: The worker bridge. If omitted, it defaults to the bridge
        associated with the C<schema_instance>.

=item * C<cond>: A hashref of search conditions (the C<WHERE> clause).

=item * C<attrs>: A hashref of query attributes (C<join>, C<prefetch>, C<rows>, etc.).

=item * C<result_class>: The class used to inflate rows. Defaults to C<DBIx::Class::Core>.

=back

=item * Internal State

The constructor initialises buffers for rows (C<_rows>) and iteration
cursors (C<_pos>), ensuring that newly created ResultSets are always
in a "clean" state ready for fresh execution.

=back

=cut

sub new {
    my ($class, %args) = @_;

    # 1. Validation
    croak "Missing required argument: schema_instance" unless $args{schema_instance};
    croak "Missing required argument: source_name"     unless $args{source_name};

    # 2. Blessing the unified state
    return bless {
        # Core Infrastructure
        _schema_instance => $args{schema_instance},
        _async_db        => $args{async_db} // $args{_schema_instance}->{_async_db},

        # Source Metadata
        _source_name     => $args{source_name},
        _result_class    => $args{result_class} // 'DBIx::Class::Core',

        # Query State
        _cond            => $args{cond}  // {},
        _attrs           => $args{attrs} // {},

        # Result State (Usually reset on clone)
        _rows            => $args{rows} // undef,
        _pos             => $args{pos}  // 0,

        # Prefetch/Pager logic
        _is_prefetched   => $args{is_prefetched} // 0,
        _pager           => $args{pager},
    }, $class;
}

=head2 new_result

Internal method used to turn a raw database hashref into a L<DBIx::Class::Async::Row> object. It handles:

=over 4

=item * Dotted Key Expansion

Expands C<< {'user.name' => 'Bob'} >> into nested hashes for prefetched relationships.

=item * Relationship Inflation

Automatically turns prefetched relationship data into nested Row objects.

=item * Class Hijacking

If a custom C<result_class> is used, it dynamically creates an anonymous class
inheriting from both the async row and your custom class.

=back

=cut

sub new_result {
    my ($self, $data, $attrs) = @_;
    return unless defined $data;

    my $in_storage = (ref $attrs eq 'HASH' && exists $attrs->{in_storage})
                     ? $attrs->{in_storage}
                     : 0;  # Default to NOT in storage

    # Ensure we are working with a hash copy
    my %raw_data = ref $data eq 'HASH' ? %$data : ();
    my %col_data;
    my %rel_data;

    # It converts {'user.id' => 2, 'user.name' => 'Bob'}
    # into { user => { id => 2, name => 'Bob' } }
    my @all_keys = keys %raw_data;

    foreach my $key (@all_keys) {
        # Check for dots (e.g., 'user.name')
        if ($key =~ /^(.+)\.(.+)$/) {
            my ($rel, $subcol) = ($1, $2);

            # Initialise the nested hash if it doesn't exist
            $raw_data{$rel} //= {};

            # Move the value into the nested hash
            $raw_data{$rel}{$subcol} = $raw_data{$key};

            # Delete the original dotted key safely
            delete $raw_data{$key};
        }
    }

    foreach my $key (keys %raw_data) {
        my $val = $raw_data{$key};

        # Only treat as a relationship if the source explicitly says it is
        if ($self->result_source->has_relationship($key) &&
            !$self->result_source->has_column($key)) {

            my $rel_info = $self->result_source->relationship_info($key);
            if (defined $val) {
                if ($rel_info->{attrs}{accessor} eq 'multi') {
                    $rel_data{$key} = $self->_new_prefetched_dataset($val, $key);
                }
                else {
                    # belongs_to / might_have: Inflate into a Row object immediately
                    if (ref $val eq 'HASH' && grep { defined } values %$val) {
                        my $rel_rs = $self->result_source->schema->resultset($rel_info->{source});
                        $rel_data{$key} = $rel_rs->new_result($val);
                    }
                    else {
                        $rel_data{$key} = undef;
                    }
                }
            }
        }
        else {
            # Regular database column
            $col_data{$key} = $val;
        }
    }

    # Create Row using the proper constructor
    my $new_row = DBIx::Class::Async::Row->new(
        schema_instance => $self->{_schema_instance},
        async_db        => $self->{_async_db},
        source_name     => $self->{_source_name},
        result_source   => $self->result_source,
        row_data        => \%col_data,
        in_storage      => $in_storage,
    );

    # Set the relationship data
    $new_row->{_relationship_data} = { %rel_data };

    # Dynamic Class Hijacking - handle custom result_class
    my $target_class   = $self->{_attrs}->{result_class} || $self->result_class;
    my $base_row_class = ref($new_row);

    if ($target_class && $target_class ne $base_row_class) {
        # Create anonymous class name
        my $safe_target = $target_class =~ s/::/_/gr;
        my $anon_class = "DBIx::Class::Async::Anon::${safe_target}";

        no strict 'refs';
        unless (@{"${anon_class}::ISA"}) {
            # Load the custom class if not already loaded
            unless ($target_class->can('can')) {
                eval "require $target_class" or die "Could not load $target_class: $@";
            }

            # Set up inheritance: Anon -> AsyncRow -> CustomClass
            @{"${anon_class}::ISA"} = ($base_row_class, $target_class);
        }

        # Re-bless into the anonymous class
        bless $new_row, $anon_class;

        # Ensure accessors are created
        $new_row->_ensure_accessors if $new_row->can('_ensure_accessors');
    }

    # ACTIVATE the accessors in Row.pm
    if ($new_row->can('_install_prefetch_accessors')) {
        $new_row->_install_prefetch_accessors;
    }

    return $new_row;
}

=head2 new_result_set

    my $new_rs = $rs->new_result_set({ cond => { active => 1 } });

An internal but critical factory method used to spawn new instances of the
ResultSet while preserving the asynchronous execution context.

This method performs a "smart clone" of the current object's state, ensuring
that the background worker pool and metadata links are carried over to the
derived ResultSet.

=over 4

=item * State Mapping

It automatically maps internal underscored attributes
(e.g., C<_source_name>) to clean constructor arguments (C<source_name>).

=item * Infrastructure Persistence

Explicitly carries over the C<async_db> (the worker bridge) and the C<schema_instance>.

=item * Override Injection

Accepts a hashref of overrides to modify the state of the new instance (commonly
used for merging new search conditions or attributes).

=back

Example: Manual ResultSet Cloning

If you were extending this library and needed to create a specialised ResultSet
that shares the same worker pool:

    sub specialised_search {
        my ($self, $extra_logic) = @_;

        # This ensures the new RS knows how to talk to the workers
        return $self->new_result_set({
            cond  => { %{$self->{_cond}},  %$extra_logic },
            attrs => { %{$self->{_attrs}}, cache_for => '1 hour' }
        });
    }

=cut

sub new_result_set {
    my ($self, $overrides) = @_;

    my %args;
    foreach my $internal_key (keys %$self) {
        # 1. Only process keys starting with an underscore
        next unless $internal_key =~ /^_/;

        # 2. Strip leading underscore for the "clean" argument name
        my $clean_key = $internal_key;
        $clean_key =~ s/^_//;

        $args{$clean_key} = $self->{$internal_key};
    }

    $args{async_db}        = $self->{_async_db};
    $args{schema_instance} = $self->{_schema_instance};

    # 3. Apply overrides
    if ($overrides) {
        @args{keys %$overrides} = values %$overrides;
    }

    # 4. Call new() with a flat list (%args)
    return (ref $self)->new(%args);
}

=head2 all

    my $future = $rs->all;
    $future->on_done(sub {
        my $rows = shift; # Arrayref of row objects
        say $_->name for @$rows;
    });

The primary method for retrieving all results from the ResultSet. It returns a
L<Future> that resolves to an arrayref of L<DBIx::Class::Async::Row> objects.

=over 4

=item * Tier 1: Prefetched/Injected Data

If data was manually injected via C<set_cache> or arrived as raw hashrefs,
C<all> automatically inflates them into full Row objects, injecting the necessary
C<async_db> bridge and metadata into each.

=item * Tier 2: Local Buffer

If the ResultSet has already been executed and the rows are held in memory
(C<_rows>), it returns them immediately wrapped in a resolved Future.

=item * Tier 3: Shared Query Cache

Before hitting the database, it consults the C<_query_cache> using a surgical
lookup based on the source name and query signature.

=item * Tier 4: Non-Blocking Fetch

On a cache miss, it dispatches the request to the worker pool via C<all_future>.
Once results return, they are indexed in the cache for future requests.

=back

B<Efficiency Note:> This method is highly optimised to prevent redundant IPC
(Inter-Process Communication). Multiple calls to C<all> on the same ResultSet
will only ever trigger a single network request.

=cut

sub all {
    my ($self) = @_;
    my $db = $self->{_async_db};

    # 1. Check if caching is explicitly disabled for this query
    if (exists $self->{_attrs}{cache} && !$self->{_attrs}{cache}) {
        return $self->all_future;
    }

    if ($self->can('_has_dynamic_sql') && $self->_has_dynamic_sql) {
        return $self->all_future;
    }

    # 2. Check cache_ttl (use both _cache_ttl and cache_ttl for compatibility)
    my $cache_ttl = $self->{_attrs}{cache_ttl}
                 // $db->{_cache_ttl}
                 // 0;

    # 3. If no caching, skip to query
    if (!$cache_ttl) {
        return $self->all_future;
    }

    # 4. Check for dynamic SQL
    if ($self->can('_has_dynamic_sql') && $self->_has_dynamic_sql) {
        return $self->all_future;
    }

    # 5. Check for prefetched data first
    if ($self->{_is_prefetched} && $self->{_entries}) {
        my @blessed_rows = map {
            if (ref($_) eq 'HASH') {
                $self->_inflate_row($_, { in_storage => 1 })
            }
            else {
                $_; # Already a Row object
            }
        } @{$self->{_entries}};

        $self->{_entries} = \@blessed_rows;
        $self->{_rows}    = \@blessed_rows;
        return Future->done($self->{_entries});
    }

    # 6. Check in-memory cache (_rows)
    if ($self->{_rows} && ref($self->{_rows}) eq 'ARRAY' && @{$self->{_rows}}) {
        return Future->done($self->{_rows});
    }

    # 7. Generate cache key
    my $cache_key = $self->_generate_cache_key(0);

    if ($db->{_cache} && defined $cache_key) {
        my $cached_data = eval { $db->{_cache}->get($cache_key) };
        if (defined $cached_data && ref($cached_data) eq 'ARRAY') {
            $db->{_stats}{_cache_hits}++;

            my @rows = map {
                $self->new_result($_, { in_storage => 1 })
            } @$cached_data;

            $self->{_rows} = \@rows;
            return Future->done(\@rows);
        }
    }

    # 9. Cache miss - increment counter and fetch from database
    $db->{_stats}{_cache_misses}++;

    return $self->all_future->on_done(sub {
        my $rows = shift;

        # Store UNBLESSED data in CHI
        if ($db->{_cache} && defined $cache_key && $cache_ttl) {
            my @cache_data;

            # Check if rows are already hashrefs (from HashRefInflator)
            if (@$rows && ref($rows->[0]) eq 'HASH' && !blessed($rows->[0])) {
                # Already hashrefs, use directly
                @cache_data = @$rows;
            }
            else {
                # Blessed Row objects, extract columns
                @cache_data = map {
                    my %cols = $_->get_columns;
                    \%cols;
                } @$rows;
            }

            eval { $db->{_cache}->set($cache_key, \@cache_data) };
        }


        $self->{_rows} = $rows;
        return $rows;
    });
}

=head2 all_future

    my $future = $rs->all_future($cond?, \%attrs?);

The low-level execution engine for searches. Dispatches a search request to the
background worker and returns a L<Future>.

=over 4

=item * Payload Construction

Merges the ResultSet's internal state (C<cond> and C<attrs>) with any temporary
overrides passed to the method. It uses C<_build_payload> to ensure the data
is serialisable for IPC.

=item * Worker Dispatch

Calls the C<search> method on the background worker pool via the internal C<_call_worker>
bridge.

=item * Post-Fetch Inflation (Tier 1)

Before creating objects, it runs custom column inflators. This is where database
strings (like JSON or custom types) are converted back into Perl structures.

=item * Inflation Logic (Tier 2)

=over 4

=item * If C<HashRefInflator> is requested, it returns the raw data structures
        for maximum performance.

=item * Otherwise, it maps the data through C<_inflate_row> to produce fully
        functional L<DBIx::Class::Async::Row> objects.

=back

=back

=cut

sub all_future {
    my ($self, $cond, $attrs) = @_;

    my $db      = $self->{_async_db};
    my $payload = $self->_build_payload();
    $payload->{source_name} = $self->{_source_name};

    $payload->{cond}  = $cond  // $self->{_cond}  // {};
    $payload->{attrs} = $attrs // $self->{_attrs} // {};

    return DBIx::Class::Async::_call_worker(
        $db,
        'search',
        $payload,
    )->then(sub {
        my $rows_data = shift;

        if (!ref($rows_data) || ref($rows_data) ne 'ARRAY') {
            return [];
        }

        # 1. Apply Column Inflators (JSON -> HASH) to the raw data first
        my $moniker      = $self->{_source_name};
        my $source_class = $self->result_source->result_class;

        my $inflators = $db->{_custom_inflators}{$moniker}
                     || $db->{_custom_inflators}{$source_class}
                     || {};

        if (keys %$inflators) {
            foreach my $row (@$rows_data) {
                foreach my $col (keys %$inflators) {
                    if (exists $row->{$col} && defined $row->{$col} && !ref $row->{$col}) {
                        $row->{$col} = $inflators->{$col}{inflate}->($row->{$col});
                    }
                }
            }
        }

        # 2. Decide based on result_class
        my $result_class = $self->{_attrs}{result_class} || '';

        if ($result_class eq 'DBIx::Class::ResultClass::HashRefInflator') {
            $self->{_rows} = $rows_data;
            return $rows_data;
        }

        # 3. Otherwise, turn into Row objects
        my @objects = map { $self->_inflate_row($_, { in_storage => 1 }) } @$rows_data;
        $self->{_rows} = \@objects;
        return \@objects;
    });
}

=head2 as_query

    my ($sql, @bind) = @{ $rs->as_query };

Returns a representation of the SQL query and its bind parameters that would be
executed by this ResultSet.

Unlike most other methods in this package, C<as_query> is B<synchronous> and
returns a standard DBIC query arrayref immediately. It does not communicate
with the worker pool.

=over 4

=item * Shadow Schema Execution

Internally, it maintains a C<dbi:NullP:> (Null Proxy) connection. This allows
the L<DBIx::Class> SQL generator to function in the parent process without
requiring a real database socket.

=item * Metadata Awareness

It automatically loads your C<schema_class> if it isn't already in memory to
ensure relationships and column types are correctly mapped to SQL.

=item * Warning Suppression

It intelligently silences "Generic Driver" warnings (like C<undetermined_driver>)
that typically occur when generating SQL without an active database handle, keeping
your logs clean while preserving actual errors if C<ASYNC_TRACE> is enabled.

=back

Example: Debugging a complex join

    my $rs = $schema->resultset('User')->search(
        { 'orders.status' => 'shipped' },
        { join => 'orders' }
    );

    my ($sql, @bind) = @{ $rs->as_query };
    print "Generated SQL: $sql\n";

=cut

sub as_query {
    my $self = shift;

    my $bridge       = $self->{_async_db};
    my $schema_class = $bridge->{_schema_class};

    unless ($schema_class->can('resultset')) {
        eval "require $schema_class" or die "as_query: $@";
    }

    # Silence the "Generic Driver" warnings for the duration of this method
    local $SIG{__WARN__} = sub {
        if (ASYNC_TRACE) {
            warn @_ unless $_[0] =~ /undetermined_driver|sql_limit_dialect|GenericSubQ/
        }
    };

    unless ($bridge->{_metadata_schema}) {
        $bridge->{_metadata_schema} = $schema_class->connect('dbi:NullP:');
    }

    # Handle empty select => [] by generating SQL manually
    if (exists $self->{_attrs}{select} &&
        ref $self->{_attrs}{select} eq 'ARRAY' &&
        @{$self->{_attrs}{select}} == 0) {

        return $self->_generate_empty_select_query();
    }

    # SQL is generated lazily; warnings often trigger here or at as_query()
    my $real_rs = $bridge->{_metadata_schema}
                         ->resultset($self->{_source_name})
                         ->search($self->{_cond}, $self->{_attrs});

    return $real_rs->as_query;
}

=head2 as_subselect_rs

    my $subquery_rs = $rs->as_subselect_rs;

Returns a new ResultSet with the current query wrapped as a subselect in
the FROM clause. This is useful for applying further operations on top of
an already-filtered or aggregated result set.

    # Get active users, then find those over 18 in the subquery
    my $active_users = $schema->resultset('User')->search({ active => 1 });
    my $adult_active = $active_users->as_subselect_rs->search({ age => { '>' => 18 }});

B<Note:> Unlike upstream L<DBIx::Class::ResultSet>, this implementation
correctly preserves the column list from the original ResultSet.
When you select a subset of columns, the subselect will only include those
columns, not all columns from the table.

    # This works correctly - subselect only has id and name
    my $rs = $schema->resultset('User')
                    ->search({}, { columns => ['id', 'name'] })
                    ->as_subselect_rs;

    # Further searches on the subselect can only reference id and name
    my $filtered = $rs->search({ name => { -like => 'A%' }});

This is particularly useful for:

=over 4

=item * Creating derived tables for complex queries

=item * Applying LIMIT in a subquery before joining

=item * Building multi-stage aggregations

=item * Optimising queries with window functions

=back

=cut

sub as_subselect_rs {
    my $self = shift;

    my $subquery = $self->as_query;
    my $columns  = $self->{_attrs}{columns} || $self->{_attrs}{select};

    my %new_attrs = (
        alias => 'me',
        from  => { me => $subquery },    # Key: alias the subquery
    );

    if ($columns) {
        $new_attrs{columns} = $columns;  # Key: preserve columns
    }

    return bless({
        _schema_instance => $self->{_schema_instance},
        _async_db        => $self->{_async_db},
        _source_name     => $self->{_source_name},
        _result_class    => $self->{_result_class},
        _cond            => {},
        _attrs           => \%new_attrs,
        _rows            => undef,
        _pos             => 0,
        _is_prefetched   => 0,
        _pager           => undef,
    }, ref($self));
}

=head2 clear_cache

Clears both the local ResultSet buffer and the central query cache for this
specific source.

=cut

sub clear_cache {
    my ($self, $cache_key) = @_;
    my $db = $self->{_async_db};

    # Clear local in-memory cache
    delete $self->{_rows};

    # Clear surgical query cache
    if ($db->{_query_cache}) {
        my $source = $self->{_source_name};
        delete $db->{_query_cache}->{$source};
    }

    if ($db->{_cache}) {
        if (defined $cache_key) {
            $db->{_cache}->remove($cache_key);
        }
        else {
            $db->{_cache}->clear();
        }
    }

    return $self;
}

=head2 cursor

    my $cursor = $rs->cursor;

Returns a storage-level cursor object for the current ResultSet.

This is a low-level method typically used when you need to handle extremely
large result sets that would exceed memory limits if fetched all at once via
C<all>.

=over 4

=item * Async Integration

The returned cursor is not a standard DBI cursor; it is wrapped by
C<DBIx::Class::Async::Storage>, ensuring that calls to C<next> or C<all>
on the cursor itself are still routed through the non-blocking worker pool.

=item * Efficiency

Use this when you intend to process thousands of rows and want to maintain a
constant memory footprint.

=back

Example: Manual Cursor Iteration

    my $cursor = $rs->search({ type => 'heavy_report' })->cursor;

    # While this looks synchronous, the underlying storage handle
    # manages the async state transitions.
    while (my @row = $cursor->next) {
        process_data(@row);
    }

=cut

sub cursor {
    my $self = shift;

    return $self->{_schema_instance}->storage->cursor($self);
}

=head2 create

    my $future = $rs->create({
        username => 'jdoe',
        profile  => { theme => 'dark' } # Automatically deflated if configured
    });

Asynchronously inserts a new record into the database. Returns a L<Future>
that resolves to a L<DBIx::Class::Async::Row> object representing the
persisted data (including database-generated defaults and IDs).

=over 4

=item * Auto-Deflation

Before sending data to the worker pool, the method strips table aliases (C<me.>,
C<self.>) and applies custom deflation logic (e.g., serialising a hashref to
a JSON string).

=item * Cache Invalidation

Calling C<create> automatically clears the ResultSet's internal cache via
L</clear_cache> to ensure subsequent queries reflect the new state of the
database.

=item * Lifecycle Management

Upon a successful insert, the worker returns  the raw record data. The parent process then:

=over 4

=item 1. Re-inflates complex types (e.g., strings back to objects).

=item 2. Instantiates a Row object via L</new_result>.

=item 3. Marks the object as C<in_storage>, making it ready for immediate updates or deletions.

=back

=back

Example: Handling a New User Signup

    $schema->resultset('User')->create({ email => 'new@user.com' })
        ->then(sub {
            my $user = shift;
            say "Created user with ID: " . $user->id;
        })
        ->catch(sub {
            warn "Failed to create user: " . shift;
        });

=cut

sub create {
    my ($self, $raw_data) = @_;

    my $db          = $self->{_async_db};
    my $source_name = $self->{_source_name};

    $self->clear_cache;

    # Guard against scalar-ref values on primary key columns.
    # Scalar refs are used to embed raw SQL expressions (e.g. \'UUID()'),
    # but these cannot cross the async worker IPC boundary -- they are
    # stringified during serialisation and the SQL expression is lost.
    # DBIC then falls back to last_insert_id() on a non-autoincrement
    # char column, returning a wrong value ('1' on SQLite, undef on MySQL).
    # Generate the PK value in Perl instead:
    #   e.g. Data::UUID->new->create_str instead of \'UUID()'

    my @pk_cols = $self->result_source->primary_columns;
    for my $pk (@pk_cols) {
        if (exists $raw_data->{$pk} && ref($raw_data->{$pk}) eq 'SCALAR') {
            Carp::croak(
                "DBIx::Class::Async: Cannot use a scalar-ref (inline SQL) "
              . "for primary key column '$pk' on source '$source_name'. "
              . "Scalar references cannot be serialised across the async "
              . "worker IPC boundary. "
              . "Generate the value in Perl before calling create() -- "
              . "e.g. use Data::UUID->new->create_str instead of \\'UUID()'."
            );
        }
    }

    # 1. Fetch inflators
    my $inflators = $db->{_custom_inflators}{$source_name} || {};

    # 2. Deflate the incoming data (Parent Side)
    my %deflated_data;
    while (my ($k, $v) = each %$raw_data) {
        my $clean_key = $k;
        $clean_key =~ s/^(?:foreign|self|me)\.//;
        if ($inflators->{$clean_key} && $inflators->{$clean_key}{deflate}) {
            $v = $inflators->{$clean_key}{deflate}->($v);
        }
        $deflated_data{$clean_key} = $v;
    }

    # 3. Leverage specialised payload builder
    my $payload = {
        source_name => $self->{_source_name},
        data        => \%deflated_data,
        attrs       => $self->{_attrs} || {},
    };

    # 4. Dispatch with correct signature
    return DBIx::Class::Async::_call_worker(
        $db,
        'create',
        $payload
    )->then(sub {
        my $db_row = shift;
        return Future->done(undef) unless $db_row;

        # 5. Inflation of return data
        for my $col (keys %$inflators) {
            if (exists $db_row->{$col} && $inflators->{$col}{inflate}) {
                $db_row->{$col} = $inflators->{$col}{inflate}->($db_row->{$col});
            }
        }

        # 6. Use new_result to create new row
        my $obj = $self->new_result($db_row, { in_storage => 1 });
        return Future->done($obj);
    });
}

=head2 count

    my $future = $rs->count({ status => 'active' });
    $future->on_done(sub {
        my $count = shift;
        say "Found $count active records.";
    });

Executes a C<SELECT COUNT(*)> query against the database asynchronously. Returns
a L<Future> resolving to the integer count.

=over 4

=item * Optimisation - Row Limit

If the ResultSet has a fixed number of C<rows> defined in its attributes and
no additional conditions are passed to C<count>, the method returns the C<rows>
value immediately without hitting the database.

=item * Caching

Uses a specialised cache key (suffix C<:count>) to store results in the
C<async_db> cache. Aggregate queries are often expensive; this ensures that
multiple count requests for the same criteria are served from memory.

=item * Worker Dispatch

Dispatches the C<count> command to the background worker pool, keeping the
parent process non-blocking.

=back

Example: Conditional Counting

    $rs->count({ category_id => 5 })->then(sub {
        my $count = shift;
        return $count > 0 ? $rs->all : Future->done([]);
    });

=cut

sub count {
    my ($self, $cond, $attrs) = @_;

    if (!defined $cond && exists $self->{_attrs}{rows}) {
        return Future->done($self->{_attrs}{rows});
    }

    my $db = $self->{_async_db};

    my $payload = $self->_build_payload($cond, $attrs);

    warn "[PID $$] STAGE 1 (Parent): Dispatching count" if ASYNC_TRACE;

    # This returns a Future that will be resolved by the worker
    return DBIx::Class::Async::_call_worker(
        $db, 'count', $payload);
}

=head2 count_future

    my $future = $rs->count_future;

Returns a L<Future> that resolves to the row count, bypassing all parent-process
caching mechanisms.

Unlike the standard L</count> method, which may return a cached result or an
in-memory attribute value, C<count_future> always dispatches a C<SELECT COUNT(*)>
request directly to the worker pool.

=over 4

=item * Bypasses Cache

Ignores any data stored in the C<_query_cache> or the shared C<_cache> bucket.

=item * Stateless

Does not inspect C<$rs->{_attrs}->{rows}>. It forces the database to perform
the calculation.

=item * Direct Dispatch

Uses the low-level C<_call_worker> interface to ensure the smallest possible
overhead between the method call and the IPC (Inter-Process Communication) layer.

=back

Example: Forcing a fresh count in a high-concurrency environment

    # count() might return a cached value from 2 seconds ago
    # count_future() hits the metal

    $rs->count_future->on_done(sub {
        my $exact_count = shift;
        print "Live DB Count: $exact_count\n";
    });

=cut

sub count_future {
    my $self = shift;
    my $db   = $self->{_async_db};

    return DBIx::Class::Async::_call_worker(
        $db, 'count', {
        source_name => $self->{_source_name},
        cond        => $self->{_cond},
        attrs       => $self->{_attrs},
    });
}

=head2 count_literal

    my $future = $rs->count_literal('age > ? AND status = "active"', 21);

Performs a count operation using a raw SQL fragment. This is useful for complex
filtering that is difficult to express via standard L<SQL::Abstract> syntax.

Returns a L<Future> resolving to the integer count.

=over 4

=item * Fluent Chaining

Internally, this method calls C<search_literal> to generate a transient, specialised
ResultSet and then immediately calls C<count> on it.

=item * Infrastructure Inheritance

The transient ResultSet automatically inherits the C<_async_db> worker bridge
and C<_schema_instance> from the parent, ensuring the raw SQL is executed in
the correct worker process.

=item * Security

Always pass parameters as a bind list (e.g., C<@bind>) rather than interpolating
variables directly into the SQL string to prevent SQL injection.

=back

Example: Using Database-Specific Functions

    # Using Postgres-specific ILIKE for case-insensitive counting
    my $future = $rs->count_literal('email ILIKE ?', '%@GMAIL.COM');

    $future->on_done(sub {
        my $gmail_users = shift;
        print "Found $gmail_users Gmail accounts.\n";
    });

=cut

sub count_literal {
    my ($self, $sql_fragment, @bind) = @_;

    # 1. search_literal() creates a NEW ResultSet instance.
    # 2. Because we fixed search_literal/new_result_set, this new RS
    #    already shares the same _async_db and _schema_instance.
    # 3. We then chain the count() call which returns the Future.

    return $self->search_literal($sql_fragment, @bind)->count;
}

=head2 count_rs

    my $count_rs = $rs->count_rs($cond?, \%attrs?);

Returns a new L<DBIx::Class::Async::ResultSet> specifically configured to
perform a C<COUNT(*)> operation.

Unlike L</count>, which returns a B<Future> that executes immediately,
C<count_rs> is synchronous and returns a B<ResultSet>. This allows you to
pre-define a count query and pass it around your application or combine it with
further search modifiers before execution.

=over 4

=item * Chainability

Because it returns a ResultSet, you can continue chaining methods like C<search>
or C<attr> before eventually calling C<all> or C<next> to get the value.

=item * Infrastructure Guarantee

Internally calls C<search>, ensuring the newly created ResultSet remains pinned to
the same C<async_db> worker bridge and parent C<schema_instance>.

=item * Automatic Projection

Automatically sets the C<select> attribute to C<{ count => '*' }> and the
C<as> alias to C<'count'>.

=back

Example: Defining a count query for later execution

    # Create the count-specific ResultSet
    my $pending_count_rs = $rs->count_rs({ status => 'pending' });

    # ... later in the code ...

    # Execute it via the standard async 'all' or 'next'
    $pending_count_rs->next->then(sub {
        my $row = shift;
        print "Pending count: " . $row->get_column('count') . "\n";
    });

=cut

sub count_rs {
    my ($self, $cond, $attrs) = @_;

    # By calling $self->search, we guarantee the new RS
    # inherits the pinned _async_db and _schema_instance.
    return $self->search($cond, {
        %{ $attrs || {} },
        select => [ { count => '*' } ],
        as     => [ 'count' ],
    });
}

=head2 count_total

    my $total_future = $rs->count_total($extra_cond?, \%extra_attrs?);

Returns a L<Future> resolving to the total number of records matching the current
filter, specifically ignoring any pagination or sorting attributes.

This is primarily used to calculate the "Total Pages" in a paginated UI, where
the current ResultSet might be sliced to only 20 rows, but you need to know
that 5,000 total records match the criteria.

=over 4

=item * Attribute Stripping

Automatically removes C<rows>, C<offset>, C<page>, and C<order_by> from the
query. This ensures the database doesn't perform unnecessary sorting or slicing,
resulting in a much faster count.

=item * Parameter Merging

Allows passing in C<$cond> and C<$attrs> which are merged with the existing
ResultSet state before execution.

=item * Direct Execution

Like L</count_future>, this bypasses any local result buffers and asks the
worker to perform a fresh C<COUNT(*)> on the un-sliced dataset.

=back

Example: Implementing Pagination Metadata

    my $paged_rs = $rs->search({ category => 'electronics' })
                      ->page(1)
                      ->rows(10);

    # This resolves to 10 (the current page size)
    my $current_count_f = $paged_rs->count;

    # This resolves to the absolute total (e.g., 450)
    my $grand_total_f = $paged_rs->count_total;

    Future->needs_all($current_count_f, $grand_total_f)->then(sub {
        my ($current, $total) = @_;
        print "Showing $current of $total total items.\n";
    });

=cut

sub count_total {
    my ($self, $cond, $attrs) = @_;

    # 1. Merge incoming parameters with existing ResultSet state
    my %merged_cond  = ( %{ $self->{_cond}  || {} }, %{ $cond  || {} } );
    my %merged_attrs = ( %{ $self->{_attrs} || {} }, %{ $attrs || {} } );

    # 2. Strip slicing/ordering attributes to get the absolute total
    delete @merged_attrs{qw(rows offset page order_by)};

    # 3. Use the static call exactly like your other count() implementations
    return DBIx::Class::Async::_call_worker(
        $self->{_async_db},
        'count',
        {
            source_name => $self->{_source_name},
            cond        => \%merged_cond,
            attrs       => \%merged_attrs,
        });
}

=head2 delete

    my $future = $rs->search({ status => 'obsolete' })->delete;

Asynchronously removes records matching the ResultSet's criteria from the database.
Returns a L<Future> resolving to the number of rows deleted.

=over 4

=item * Auto-Routing Logic

=over 4

=item * Direct Path

If the query is a simple attribute-free HASH (e.g., C<< { id => 5 } >>), it
dispatches a single C<DELETE> command directly to the worker.

=item * Safe Path (delete_all)

If the ResultSet contains complex logic (joins, limits, or offsets), it automatically
delegates to L</delete_all> to avoid database-specific restrictions on
multi-table deletes.

=back

=item * Cache Invalidation

Immediately calls L</clear_cache> on the ResultSet to prevent the application
from reading stale data that has been removed from the physical storage.

=item * Non-Blocking

Like all write operations in this library, the process is handed off to the
worker pool, allowing your main application to continue processing other
requests.

=back

Example: Safe Deletion of Limited Sets

    # This uses the 'Safe Path' because of the 'rows' attribute
    $rs->search({ type => 'log' }, { rows => 100 })->delete
       ->on_done(sub {
           my $count = shift;
           say "Cleaned up $count log entries.";
       });

=cut

sub delete {
    my $self = shift;

    $self->clear_cache;

    my $attrs = $self->{_attrs} || {};
    my $cond  = $self->{_cond};

    # Attributes that make a direct single-query DELETE unsafe.
    # For each of these we must take the two-step path: fetch matching PKs
    # via a clean search, then DELETE WHERE pk IN (...).
    #
    # - rows / offset / page : LIMIT on DELETE is non-standard SQL
    # - join                 : multi-table DELETE syntax varies by database
    # - group_by / having    : DBIC drops GROUP BY when generating the DELETE
    #                          subquery, producing invalid SQL. Additionally,
    #                          a grouped search does not return individual
    #                          rows -- it returns aggregate results -- so we
    #                          must re-fetch the actual rows using only the
    #                          WHERE condition (stripping group_by/having)
    #                          before deleting.

    my $has_limit   = exists $attrs->{rows}
                   || exists $attrs->{offset}
                   || exists $attrs->{page};
    my $has_join    = exists $attrs->{join};
    my $has_grouped = exists $attrs->{group_by}
                   || exists $attrs->{having};

    if ( $has_grouped ) {
        # Strip group_by and having entirely -- we only want the WHERE
        # condition to identify which rows to delete.  Keeping them would
        # cause all() to return aggregate results with no usable PKs.
        my %safe_attrs = %$attrs;
        delete @safe_attrs{qw(group_by having)};

        return $self->new_result_set({
            cond  => $cond,
            attrs => \%safe_attrs,
        })->delete_all;
    }

    if ( $has_limit || $has_join ) {
        return $self->delete_all;
    }

    # Simple condition with no dangerous attrs: single-query direct DELETE.
    if ( ref($cond) eq 'HASH' && keys %$cond ) {
        return DBIx::Class::Async::_call_worker(
            $self->{_async_db},
            'delete',
            {
                source_name => $self->{_source_name},
                cond        => $cond,
            }
        );
    }

    # No condition, or non-HASH condition (literal SQL): use delete_all for
    # safety to avoid accidental full-table wipe on malformed input and to
    # handle literal SQL conditions correctly.
    return $self->delete_all;
}

=head2 delete_all

    my $future = $rs->search({ status => 'expired' })->delete_all;

Performs a two-stage asynchronous deletion. First, it retrieves the records
matching the criteria to identify their unique Primary Keys, then it issues a
targeted bulk delete for those specific records.

=over 4

=item * Precision

This method is safer than a direct C<delete> when dealing with ResultSets
that use C<rows>, C<offset>, or complex C<join> attributes, as it ensures
only the specific records visible to the ResultSet are removed.

=item * Composite Key Support

Automatically detects and handles tables with multiple primary keys, constructing
a complex C<-or> condition to ensure the correct rows are targeted.

=item * Short-Circuiting

If the initial search yields no results, the method returns a resolved Future
with a value of C<0>, saving an unnecessary round-trip to the database worker.

=item * Return Value

Resolves to the number of rows that were successfully identified and sent for
deletion.

=back

Example: Safely Deleting with Relationships

    # Delete orders for inactive users (complex join)
    $schema->resultset('Order')->search({ 'user.is_active' => 0 }, { join => 'user' })
           ->delete_all
           ->on_done(sub {
               my $deleted = shift;
               print "Purged $deleted orders from inactive accounts.\n";
           });

=cut

sub delete_all {
    my $self = shift;

    # Step 1: Use our working 'all' method to get the targets
    return $self->all->then(sub {
        my $rows = shift;

        return Future->done(0) unless $rows && @$rows;

        # Step 2: Identify Primary Keys
        my @pks   = $self->result_source->primary_columns;
        my $count = scalar @$rows;
        my $condition;

        if (scalar @pks == 1) {
            my $pk_col = $pks[0];
            my @ids    = map { $_->get_column($pk_col) } @$rows;
            $condition = { $pk_col => { -in => \@ids } };
        }
        else {
            # Handle Composite Keys
            $condition = { -or => [
                map {
                    my $row = $_;
                    { map { $_ => $row->get_column($_) } @pks }
                } @$rows
            ]};
        }

        # Step 3: Send the targeted delete to the worker
        return DBIx::Class::Async::_call_worker(
            $self->{_async_db},
            'delete',
            {
                source_name => $self->{_source_name},
                cond        => $condition
            }
        )->then(sub {
            return Future->done($count);
        });
    });
}

=head2 delete_query

    my ($sql, @bind) = $rs->delete_query;
    my $query = $rs->delete_query;

Returns the SQL and bind values that would be generated by a delete operation
without actually executing it.

    my $rs = $schema->resultset('User')->search({ inactive => 1 });
    my ($sql, @bind) = $rs->delete_query;
    # $sql = \'DELETE FROM users WHERE inactive = ?'
    # @bind = (1)

    # Verify before deleting
    if ($$sql =~ /WHERE/) {
        $rs->delete->get;  # Safe to execute
    } else {
        die "Refusing to DELETE without WHERE clause!";
    }

=cut

sub delete_query {
    my $self = shift;

    my $bridge       = $self->{_async_db};
    my $schema_class = $bridge->{_schema_class};

    unless ($schema_class->can('resultset')) {
        eval "require $schema_class" or die "delete_query: $@";
    }

    # Silence warnings
    local $SIG{__WARN__} = sub {
        if (ASYNC_TRACE) {
            warn @_ unless $_[0] =~ /undetermined_driver|sql_limit_dialect|GenericSubQ/
        }
    };

    unless ($bridge->{_metadata_schema}) {
        $bridge->{_metadata_schema} = $schema_class->connect('dbi:NullP:');
    }

    # Create a sync ResultSet with the same conditions
    my $real_rs = $bridge->{_metadata_schema}
                         ->resultset($self->{_source_name})
                         ->search($self->{_cond}, $self->{_attrs});

    # Generate SQL using DBIC's internal delete SQL generator
    my $storage = $bridge->{_metadata_schema}->storage;

    my ($sql, @bind);

    eval {
        my $source = $real_rs->result_source;
        my $cond   = $real_rs->{cond};

        # Build WHERE clause
        my ($where_sql, @where_bind) = $storage->sql_maker->where($cond);

        # Construct DELETE statement
        my $table = $source->from;
        $sql  = \"DELETE FROM $table$where_sql";
        @bind = @where_bind;
    };

    if ($@) {
        croak("Failed to generate delete SQL: $@");
    }

    return wantarray ? ($sql, @bind) : \[ $sql, @bind ];
}

=head2 first_future

An alias for L</first>. This naming convention is provided for consistency with
other C<*_future> methods in the library, signaling that the return value is
an asynchronous L<Future>.

Example: Retrieving the most recent login

    my $future = $schema->resultset('UserLog')->search(
        { user_id => 42 },
        { order_by => { -desc => 'login_at' } }
    )->first;

    $future->on_done(sub {
        my $log = shift;
        print "Last seen: " . $log->login_at if $log;
    });

=cut

sub first_future  { shift->first(@_) }

=head2 first

    my $future = $rs->first;

Returns a L<Future> resolving to the first L<DBIx::Class::Async::Row> object in
the ResultSet, or C<undef> if the set is empty.

=over 4

=item * Memory First

If the ResultSet has already been populated (e.g. via a previous call to C<all>),
this method returns the first element from the internal C<_rows> buffer immediately
without a database hit.

=item * Auto-Inflation

If the internal buffer contains raw data (hashrefs), it is automatically inflated
into a proper Row object before the Future resolves.

=item * Optimised Fetch

If no data is in memory, it executes a targeted query with C<< rows => 1 >> (SQL C<LIMIT 1>).
This is significantly faster and more memory-efficient than fetching the entire result set.

=back

=cut

sub first {
    my $self = shift;

    # 1. If we already have data in memory, use it!
    if ($self->{_rows} && @{$self->{_rows}}) {
        my $data = $self->{_rows}[0];
        my $row = (ref($data) eq 'HASH') ? $self->_inflate_row($data, { in_storage => 1 }) : $data;
        return Future->done($row);
    }

    # 2. If no cache, force a LIMIT 1 query to be fast
    return $self->search(undef, { rows => 1 })->next;
}

=head2 find

    # Find by Primary Key scalar
    my $user_f = $rs->find(123);

    # Find by unique constraint hashref
    my $user_f = $rs->find({ email => 'gemini@example.com' });

Retrieves a single row from the database based on a unique identifier. Returns
a L<Future> resolving to a single L<DBIx::Class::Async::Row> object or C<undef>
if no match is found.

=over 4

=item * Scalar Lookup

If a single value is provided, it is automatically mapped to the table's
Primary Key column. Note: This only works for tables with a single Primary Key.

=item * HashRef Lookup

If a hashref is provided, it is used as a specific search condition. This is
useful for finding records by unique columns other than the primary key
(e.g., C<username> or C<slug>).

=item * Short-Circuiting

If C<undef> is passed as the identifier, the method immediately returns a
resolved Future containing C<undef>, avoiding a pointless database round-trip.

=item * Under the Hood

This method is a wrapper around L</search> and L</single>, ensuring that a
C<LIMIT 1> is always applied to the query for maximum performance.

=back

=cut

sub find {
    my ($self, $id_or_cond) = @_;

    return Future->done(undef) unless defined $id_or_cond;

    my $cond;
    if (ref($id_or_cond) eq 'HASH') {
        $cond = $id_or_cond;
    }
    else {
        # GET THE REAL PK NAME
        my @pks = $self->result_source->primary_columns;
        die "find() with scalar only works on single PK tables" if @pks > 1;
        $cond = { $pks[0] => $id_or_cond };
    }

    return $self->search($cond)->single;
}

=head2 find_or_new

    my $future = $rs->find_or_new({ email => 'user@example.com' }, \%attrs?);

Attempts to find a record in the database using unique constraints. If found,
it returns the existing row. If not, it returns a new, **in-memory** row object
populated with the provided data.

Returns a L<Future> resolving to a L<DBIx::Class::Async::Row> object.

=over 4

=item * Unique Lookup

Uses an internal helper to extract unique identifiers (Primary Keys or Unique
Constraints) from the provided data for the initial C<find> call.

=item * Data Merging

If the record is not found, the new object is created by merging the provided
C<$data> with any existing constraints (C<where> clauses) currently on the ResultSet.

=item * Namespace Cleaning

Automatically strips DBIC aliases like C<me.>, C<foreign.>, or C<self.> from
column names to ensure the new object has clean, accessible attributes.

=item * Non-Blocking

Even though it may return a "new" object that hasn't hit the DB yet, it still
returns a L<Future> to maintain API consistency with the asynchronous C<find> operation.

=back

Example: Preparing a record for a form

    $schema->resultset('User')->find_or_new({
        username => 'jdoe'
    })->then(sub {
        my $user = shift;

        # If $user->in_storage is false, we know this is a fresh object
        say "Welcome back, " . $user->username if $user->in_storage;
        say "Sign up now, "  . $user->username unless $user->in_storage;
    });

=cut

sub find_or_new {
    my ($self, $data, $attrs) = @_;
    $attrs //= {};

    # 1. Identify what makes this record unique
    my $lookup = $self->_extract_unique_lookup($data, $attrs);

    # 2. Call our newly ported find()
    return $self->find($lookup, $attrs)->then(sub {
        my ($row) = @_;

        # If found, return it immediately
        return Future->done($row) if $row;

        # 3. Otherwise, prepare data for a new local object
        # We merge existing constraints with the provided data
        my %new_data = ( %{$self->{_cond} || {}}, %$data );
        my %clean_data;
        while (my ($k, $v) = each %new_data) {
            (my $clean_key = $k) =~ s/^(?:me|foreign|self)\.//;
            $clean_data{$clean_key} = $v;
        }

        # 4. Return a "new" result object (local memory only)
        # Note: new_result should handle passing the _async_db to the row
        return Future->done($self->new_result(\%clean_data));
    });
}

=head2 find_or_create

    my $future = $rs->find_or_create({
        email => 'user@example.com',
        name  => 'John Doe'
    });

Ensures a record exists in the database. Returns a L<Future> resolving to a
L<DBIx::Class::Async::Row> object.

=over 4

=item * Optimistic Strategy

First attempts to locate the record using L</find>. If the record is found,
it is returned immediately.

=item * Atomic Creation

If the record is missing, it attempts to L</create> it.

=item * Race Condition Recovery

In distributed systems, a "Time-of-Check to Time-of-Use" (TOCTOU) race can
occur. If another process inserts the record after our C<find> but before
our C<create>, the database will throw a Unique Constraint error. This
method catches that error and performs one final C<find> to retrieve the
"winning" record.

=item * Payload Handling

Automatically extracts unique constraints from the provided data to build
the lookup criteria.

=back

Example: Safe Tagging System

    # Multiple workers might try to create the 'perl' tag at once
    $schema->resultset('Tag')->find_or_create({ name => 'perl' })
           ->then(sub {
               my $tag = shift;
               return $post->add_to_tags($tag);
           });

=cut

sub find_or_create {
    my ($self, $data, $attrs) = @_;
    $attrs //= {};

    my $lookup = $self->_extract_unique_lookup($data, $attrs);

    # 1. First attempt: Find
    return $self->find($lookup, $attrs)->then(sub {
        my ($row) = @_;
        return Future->done($row) if $row;

        # 2. Second attempt: Create
        # This calls your async create() which goes through the bridge
        return $self->create($data)->catch(sub {
            my ($error) = @_;

            # 3. Race Condition Recovery
            # If the error is about a unique constraint, someone else inserted it
            # between our 'find' and 'create' calls.
            if ("$error" =~ /unique constraint|already exists/i) {
                warn "[PID $$] Race condition detected in find_or_create, retrying find"
                    if ASYNC_TRACE;
                return $self->find($lookup, $attrs);
            }

            # If it's a real error (connection, etc.), fail forward
            return Future->fail($error);
        });
    });
}

=head2 get_attribute

    my $rows_limit = $rs->get_attribute('rows');

Returns the value of a specific attribute (e.g., C<rows>, C<offset>, C<join>)
currently set on the ResultSet. This is a synchronous read from the internal
C<_attrs> hashref.

=cut

sub get_attribute {
    my ($self, $key) = @_;
    return $self->{_attrs}->{$key};
}

=head2 get

    my $data = $rs->get;

Returns the current "raw" state of the ResultSet's data buffer.

=over 4

=item * Returns the arrayref of inflated B<Row objects> if they exist.

=item * Falls back to returning B<raw hashrefs> (C<_entries>) if they have been
        fetched from a worker but not yet inflated.

=item * Returns an empty arrayref C<[]> if no data has been fetched.

=back

=cut

sub get {
    my $self = shift;
    # 1. Check for inflated objects first
    return $self->{_rows} if $self->{_rows} && ref($self->{_rows}) eq 'ARRAY';

    # 2. Check for raw data awaiting inflation
    return $self->{_entries} if $self->{_entries} && ref($self->{_entries}) eq 'ARRAY';

    return [];
}

=head2 get_cache

    my $rows = $rs->get_cache;

Specifically returns the internal buffer of B<inflated Row objects>. Unlike C<get>,
this will return C<undef> if the objects haven't been created yet, adhering
to the standard DBIC behaviour where "cache" implies fully realised results.

=cut

sub get_cache {
    my $self = shift;
    # Align with your all() logic: Return _rows if populated, otherwise undef
    return $self->{_rows} if $self->{_rows} && ref($self->{_rows}) eq 'ARRAY';

    # Optional: If you want get_cache to be "smart" like your line 85,
    # you could return _entries here, but usually get_cache implies inflated rows.
    return undef;
}

=head2 get_column

    my $col_obj = $rs->get_column('price');

Returns a L<DBIx::Class::Async::ResultSetColumn> object for the specified
column.

This pivots the API from row-based operations to column-based aggregate
functions. The returned object allows you to perform asynchronous math
directly on the database:

    $rs->get_column('age')->func_future('AVG')->on_done(sub {
        my $avg = shift;
        print "Average Age: $avg\n";
    });

=over 4

=item * Context Preservation

The column object inherits the ResultSet's current filters (C<where> clause)
and the C<async_db> worker bridge.

=back

=cut

sub get_column {
    my ($self, $column) = @_;

    return DBIx::Class::Async::ResultSetColumn->new(
        resultset => $self,
        column    => $column,
        async_db  => $self->{_async_db},
    );
}

=head2 is_cache_found

    my $cached_rows = $rs->is_cache_found($cache_key);

Queries the shared async infrastructure to see if a specific query result is
already available in the C<_query_cache>.

This is a "surgical" cache lookup. Instead of searching a flat global cache,
it first identifies the "bucket" for the current B<source_name> and then
looks for the specific B<key>.

=over 4

=item * Returns

The cached arrayref of rows if found, or C<undef> if the cache is empty or expired.

=item * Scope

This lookup is scoped to the C<_async_db> instance, allowing multiple ResultSets
to benefit from the same background fetch.

=back

=cut

sub is_cache_found {
    my ($self, $key) = @_;

    my $db     = $self->{_async_db};
    my $source = $self->{_source_name};

    # Return only if both the source bucket and the specific key exist
    return $db->{_query_cache}->{$source}->{$key}
        if exists $db->{_query_cache}->{$source}
        && exists $db->{_query_cache}->{$source}->{$key};

    return undef;
}

=head2 is_ordered

    if ($rs->is_ordered) { ... }

Returns a boolean indicating whether the ResultSet has an C<order_by> attribute
defined.

This is used internally by methods like L</pager> to issue warnings when
pagination is attempted on unordered data, which can lead to non-deterministic
results in distributed systems.

=cut

sub is_ordered {
    my $self = shift;
    # Check if 'order_by' exists in the attributes hashref
    return (exists $self->{_attrs}->{order_by} && defined $self->{_attrs}->{order_by}) ? 1 : 0;
}

=head2 is_paged

    say "This is a subset" if $rs->is_paged;

Returns a boolean indicating whether the ResultSet has a C<page> attribute
defined. This is a reliable way to check if the current ResultSet represents
a "slice" of data rather than the full set.

=cut

sub is_paged {
    my $self = shift;
    return (exists $self->{_attrs}->{page} && defined $self->{_attrs}->{page}) ? 1 : 0;
}

=head2 next

    $rs->next->then(sub {
        my $row = shift;
        return unless $row;
        # Process row...
    });

Iterates through the resultset. If the buffer is empty, it triggers an C<all>
call internally to populate the local cache and then returns the first element.

=cut

sub next {
    my $self = shift;

    # 1. Check if the buffer already exists (Memory Hit)
    if ($self->{_rows}) {
        $self->{_pos} //= 0;

        if ($self->{_pos} >= @{$self->{_rows}}) {
            return Future->done(undef);
        }

        my $data = $self->{_rows}[$self->{_pos}++];

        # Inflate if it's raw data
        my $row = (ref($data) eq 'HASH')
            ? $self->_inflate_row($data)
            : $data;

        return Future->done($row);
    }

    # 2. Buffer empty: Trigger 'all' (Database Hit)
    return $self->all->then(sub {
        # $self->all already inflated the rows into $self->{_rows}
        # and returns an arrayref of objects.
        my $rows = shift;

        if (!$rows || !@$rows) {
            return Future->done(undef);
        }

        # Reset position and return the first inflated result
        $self->{_rows} = $rows;
        $self->{_pos}  = 0;
        my $row = $self->{_rows}[$self->{_pos}++];

        $row = $self->_inflate_row($row) if ref($row) eq 'HASH';

        return Future->done($row);
    });
}

=head2 page / pager

    my $paged_rs = $rs->page(2);
    my $pager    = $paged_rs->pager; # Returns DBIx::Class::Async::ResultSet::Pager

C<page> returns a cloned RS with paging attributes. C<pager> provides an object
for UI pagination logic (e.g., C<last_page>, C<entries_per_page>).

=cut

sub page {
    my ($self, $page_number) = @_;

    # 1. Ensure we have a valid page number (default to 1)
    my $page = $page_number || 1;

    # 2. Capture existing rows attribute from _attrs, or default to 10
    # This matches your old design's requirement
    my $rows = $self->{_attrs}->{rows} || 10;

    # 3. Delegate to search() for cloning and state preservation
    # This passes through your bridge validation logic
    return $self->search(undef, {
        page => $page,
        rows => $rows,
    });
}

sub pager {
    my $self = shift;

    # 1. Return cached pager if it exists
    return $self->{_pager} if $self->{_pager};

    # 2. Strict check for paging attributes
    unless ($self->is_paged) {
        die "Cannot call ->pager on a non-paged resultset. Call ->page(\$n) first.";
    }

    # 3. Warning for unordered results (crucial for consistent pagination)
    # Checks if we are NOT in a test environment (HARNESS_ACTIVE)
    if (!$self->is_ordered && !$ENV{HARNESS_ACTIVE}) {
        warn "DBIx::Class::Async Warning: Calling ->pager on an unordered ResultSet. " .
             "Results may be inconsistent across pages.\n" if ASYNC_TRACE;
    }

    # 4. Lazy-load and instantiate the Async Pager
    require DBIx::Class::Async::ResultSet::Pager;
    return $self->{_pager} = DBIx::Class::Async::ResultSet::Pager->new(resultset => $self);
}

=head2 populate / populate_bulk

    $rs->populate([
        { name => 'Alice', age => 30 },
        { name => 'Bob',   age => 25 },
    ]);

High-speed bulk insertion. Deflates all rows in the parent process before sending
a single batch request to the worker. Returns a L<Future> resolving to an arrayref
of created objects.

=cut

sub populate {
    my ($self, $data) = @_;
    return $self->_do_populate('populate', $data);
}

sub populate_bulk {
    my ($self, $data) = @_;
    return $self->_do_populate('populate_bulk', $data);
}

sub _do_populate {
    my ($self, $operation, $data) = @_;

    croak("data required") unless defined $data;
    croak("data must be an arrayref") unless ref $data eq 'ARRAY';
    croak("data cannot be empty") unless @$data;

    # 1. Build payload and STRICTLY validate
    my $payload = $self->_build_payload();

    croak("Failed to build payload: _build_payload returned undef")
        unless ref $payload eq 'HASH';

    croak("Missing source_name in ResultSet")
        unless $payload->{source_name} || $self->{_source_name};

    # 2. Deflate the data for the Worker
    my $db          = $self->{_async_db};
    my $source_name = $self->{_source_name};
    my $inflators   = $db->{_custom_inflators}{$source_name} || {};

    # 1. Deflate the data for the Worker
    my @deflated_data;

    # Check if this is the "Array of Arrays" format (first element is an arrayref)
    if (ref $data->[0] eq 'ARRAY') {
        # This is the header-style populate: [['col1', 'col2'], [val1, val2]]
        # We pass it through raw, as the Worker should handle the mapping,
        # but we still want to keep our deflation logic if possible.
        my @rows = @$data; # Copy to avoid mutating original if needed
        my $header = shift @rows;
        my $expected_count = scalar @$header;

        foreach my $row (@rows) {
            if (scalar @$row != $expected_count) {
                croak("Row has a different number of columns than the header");
            }
        }
        @deflated_data = @$data;
    }
    else {
        # This is the "Array of Hashes" format
        # 1. Properly declare $source and %col_info
        my $source   = $self->result_source;
        my %col_info = %{ $source->columns_info };

        foreach my $row_data (@$data) {
            croak("populate row must be a HASH ref")
                unless ref $row_data eq 'HASH';

            # 2. Merge Default Values
            my %merged_row = %$row_data;
            while (my ($col, $info) = each %col_info) {
                if (!exists $merged_row{$col}
                    && exists $info->{default_value}) {
                    $merged_row{$col} = $info->{default_value};
                }
            }

            # 3. Deflate for Worker
            my %deflated_row;
            while (my ($k, $v) = each %merged_row) {
                my $clean_key = $k;
                $clean_key =~ s/^(?:foreign|self|me)\.//;

                if ($inflators->{$clean_key}
                    && $inflators->{$clean_key}{deflate}) {
                    $v = $inflators->{$clean_key}{deflate}->($v);
                }
                $deflated_row{$clean_key} = $v;
            }
            push @deflated_data, \%deflated_row;
        }
    }

    # 3. Patch and Dispatch
    $payload->{source_name} //= $source_name;
    $payload->{data}          = \@deflated_data;

    return DBIx::Class::Async::_call_worker(
        $db,
        $operation,
        $payload
    )->then(sub {
        my $results = shift;
        return Future->done([]) unless $results && ref $results eq 'ARRAY';

        my @objects = map { $self->_inflate_row($_) } @$results;
        return Future->done(\@objects);
    });
}

=head2 prefetch

    my $paged_rs = $rs->prefetch({ 'orders' => 'order_items' });

Informs the ResultSet to fetch related data alongside the primary records in a
single query.

This is an alias for calling C<< $rs->search(undef, { prefetch => $prefetch }) >>.

=over 4

=item * Efficiency

Reduces the number of round-trips to the worker pool. Without prefetch,
accessing a relationship on a row might trigger a new asynchronous request;
with it, the data is already present in the row's internal buffer.

=item * Deep Nesting

Supports the standard L<DBIx::Class> syntax for nested relationships (hashes
for single dependencies, arrays for multiple).

=item * Async Inflation

When the worker returns the data, the parent process's C<new_result> method
automatically identifies the prefetched columns and inflates them into nested
L<DBIx::Class::Async::Row> objects.

=back

Example: Eager Loading for an API Response

    # Fetch users and their profiles in one go
    $schema->resultset('User')->prefetch('profile')->all->then(sub {
        my $users = shift;
        foreach my $user (@$users) {
            # This is now a synchronous, in-memory call because of prefetch
            print $user->username . " lives in " . $user->profile->city . "\n";
        }
    });

=cut

sub prefetch {
    my ($self, $prefetch) = @_;
    return $self->search(undef, { prefetch => $prefetch });
}

=head2 result_class

    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');

Gets or sets the class used to inflate rows. If set to C<HashRefInflator>, C<all>
will return raw hashrefs instead of Row objects, which is significantly faster
for read-only APIs.

=cut

sub result_class {
    my $self = shift;

    if (@_) {
        my $new_class = shift;
        # Clone the RS to allow chaining: $rs->result_class('...')->search(...)
        my $cloned = { %$self };
        $cloned->{_attrs} = { %{ $self->{_attrs} || {} } }; # Shallow copy attributes
        $cloned->{_attrs}->{result_class} = $new_class;
        return bless $cloned, ref $self;
    }

    # Hierarchy:
    # 1. Attribute override
    # 2. Schema metadata (via source name)
    # 3. Default fallback
    return $self->{_attrs}->{result_class}
        || $self->{_result_class} # Value passed during construction
        || 'DBIx::Class::Core';
}

=head2 related_resultset

    my $orders_rs = $user_rs->related_resultset('orders');

Returns a new ResultSet representing a relationship. It automatically handles
the JOIN logic and prefixes existing conditions
(e.g., turning C<{ id = 5 }> into C<{ 'user.id' = 5 }>).

=cut

sub related_resultset {
    my ($self, $rel_name) = @_;

    unless (defined $rel_name && length $rel_name) {
        croak "relationship_name is required for related_resultset";
    }

    # 1. Get current source and schema link
    my $source        = $self->result_source;
    my $schema_inst   = $self->{_schema_instance};
    my $native_schema = $schema_inst->{_native_schema};

    # 2. Resolve relationship info
    my $rel_info = $source->relationship_info($rel_name)
        or die "No such relationship '$rel_name' on " . $source->source_name;

    # 3. Determine the Target Moniker
    # DBIC often returns full class names (TestSchema::Result::Order)
    # but ->source() and ->resultset() want the moniker (Order)
    my $target_moniker = $rel_info->{source};
    $target_moniker =~ s/^.*::Result:://;

    # 4. Resolve the target source object (for metadata/pivoting)
    my $rel_source_obj = eval { $native_schema->source($target_moniker) }
        || eval { $native_schema->source($rel_info->{source}) };

    unless ($rel_source_obj) {
        die "Could not resolve source for relationship '$rel_name' (target: $target_moniker)";
    }

    # 5. Find the reverse relationship (e.g., 'user') for the JOIN
    my $reverse_rel = $self->_find_reverse_relationship($source, $rel_source_obj, $rel_name)
        or die "Could not find reverse relationship for '$rel_name' to " . $source->source_name;

    # 6. Prefix existing conditions (Pivot logic)
    # Turns { age => 30 } into { 'user.age' => 30 }
    my %new_cond;
    if ($self->{_cond} && ref $self->{_cond} eq 'HASH') {
        while (my ($key, $val) = each %{$self->{_cond}}) {
            my $new_key = ($key =~ /\./) ? $key : "$reverse_rel.$key";
            $new_cond{$new_key} = $val;
        }
    }

    # 7. Build the new Async ResultSet using the MONIKER
    # We call resultset('Order'), NOT resultset('orders')
    return $schema_inst->resultset($target_moniker)->search(
        \%new_cond,
        { join => $reverse_rel }
    );
}

=head2 result_source

    my $source = $rs->result_source;

Returns the L<DBIx::Class::ResultSource> object for the current ResultSet.

This object contains the structural definition of the data source, including
column names, data types, relationships, and the primary key configuration.

=over 4

=item * Metadata Access

Use this to introspect the schema at runtime (e.g., checking if a column
exists or retrieving relationship metadata).

=item * Internal Proxy

This is a wrapper around the internal C<_get_source> method, which ensures
the metadata is lazily loaded from the schema definition if it isn't already
present in the parent process.

=item * Consistency

While the ResultSet handles the *query logic*, the ResultSource handles the
*data contract*.

=back

Example: Introspecting Column Types

    my $source = $rs->result_source;
    my $info   = $source->column_info('created_at');

    print "Column Type: " . $info->{data_type} . "\n";

=cut

sub result_source { shift->_get_source; }

sub _get_source {
    my $self = shift;

    $self->{_source} ||= $self->{_schema_instance}->source($self->{_source_name});

    return $self->{_source};
}

=head2 reset_stats

    $rs->reset_stats;

Clears all performance and telemetry counters within the associated asynchronous
bridge (C<_async_db>).

This resets counters such as query execution counts, worker round-trip times,
and cache hit/miss ratios to zero. It is typically used at the start of a
profiling block to measure the impact of a specific set of operations.

=over 4

=item * Global Scope

Note that because stats are stored on the C<async_db> object, calling this on
one ResultSet will reset the statistics for all ResultSets sharing that same
worker bridge.

=item * Chainable

Returns the ResultSet object to allow for fluent calling styles.

=back

=cut

sub reset_stats {
    my $self = shift;
    foreach my $key (keys %{ $self->{_async_db}->{_stats} }) {
        $self->{_async_db}->{_stats}->{$key} = 0;
    }
    return $self;
}

=head2 reset

    $rs->reset;

Resets the internal cursor position (C<_pos>) of the ResultSet to the beginning.

After calling C<reset>, the next call to C<next> or C<next_future> will return
the first row in the result set again. This is useful for re-iterating over
results already stored in the local buffer without re-fetching them from the
database.

=over 4

=item * Local Operation

This only affects the iteration state of the current ResultSet instance.

=back

Example: Measuring query impact

    $rs->reset_stats;

    $rs->search({ type => 'critical' })->all->then(sub {
        my $stats = $rs->{_async_db}->{_stats};
        print "Queries executed: " . $stats->{query_count} . "\n";
    });

=cut

sub reset {
    my $self = shift;
    $self->{_pos} = 0;
    return $self;
}

=head2 source

    my $source = $rs->source;

A convenient alias for L</result_source>.

Returns the L<DBIx::Class::ResultSource> object for the current ResultSet. This
object is the "source of truth" for the table's structure, including column
definitions and relationship mappings.

=cut

sub source {
    my $self = shift;
    return $self->_get_source;
}

=head2 source_name

    my $name = $rs->source_name;

Returns the string identifier of the ResultSource (e.g., C<'User'> or C<'Order'>).

This is a high-performance, synchronous accessor. In an asynchronous
architecture, the C<source_name> is the primary key used to tell the background
worker which table logic to load before executing a query.

=over 4

=item * Immutable

This value is set when the ResultSet is first instantiated and persists through
searches and clones.

=item * Lightweight

Unlike C<source>, this does not trigger any lazy-loading of metadata; it simply
returns the stored string from the internal state.

=back

Example: Dynamic Dispatch based on Source

    my $rs = get_some_resultset();

    if ($rs->source_name eq 'User') {
        # Perform user-specific async logic
        $rs->search({ is_active => 1 })->all->...
    }

=cut

sub source_name {
    my $self = shift;
    return $self->{_source_name};
}

=head2 search

    my $new_rs = $rs->search(\%cond);
    my $new_rs = $rs->search(\%cond, \%attrs);
    my $new_rs = $rs->search(\'literal sql');
    my $new_rs = $rs->search(\['sql with ?', @bind]);

Returns a new L<DBIx::Class::Async::ResultSet> with the given conditions
and attributes merged onto the existing ones.

Conditions are merged with C<-and> semantics. Empty or undef conditions
on either side are treated as no-ops and not included in the merge.

Attributes are deep-merged: scalar keys are overwritten by the new value,
while accumulating keys (C<join>, C<prefetch>, C<columns>, C<select>,
C<as>, C<order_by>, C<group_by>, C<having>) are concatenated and
deduplicated.

This is a synchronous, non-I/O operation that clones the current state.

B<Empty SELECT Lists>

As of version 0.62, empty column selection is supported via C<select =E<gt> []>.
This generates database-appropriate SQL for checking row existence without
fetching column data:

    my $rs = $schema->resultset('User')->search(
        { active => 1  },
        { select => [] },
    );

    my ($sql, @bind) = $rs->as_query;
    # PostgreSQL: SELECT FROM users WHERE active = ?
    # Others:     SELECT 1 FROM users WHERE active = ?

This is useful for existence checks with minimal overhead, though L</count>
is typically more appropriate for simple counting operations:

    # Check if any matching rows exist (minimal data fetch)
    my $result   = $rs->search({}, { select => [] })->all->get;
    my $has_rows = @$result > 0;

    # More efficient for simple counting
    my $count = $rs->count->get;

B<Note:> The PostgreSQL C<SELECT FROM> syntax is a PostgreSQL-specific
optimisation. Other databases use C<SELECT 1 FROM> which is portable
and equally efficient.

=cut

sub search {
    my ($self, $cond, $attrs) = @_;

    my $existing = $self->{_cond};
    my $new_cond;

    if (!defined $cond) {
        # No new condition — preserve existing as-is
        $new_cond = $existing;
    }
    elsif (ref $cond eq 'SCALAR') {
        # Literal SQL: \'SELECT ...'
        $new_cond = _merge_cond($existing, $cond);
    }
    elsif (ref $cond eq 'REF' && ref $$cond eq 'ARRAY') {
        # Literal SQL with bind: \['sql ?', @bind]
        $new_cond = _merge_cond($existing, $cond);
    }
    elsif (ref $cond eq 'HASH') {
        $new_cond = _merge_cond($existing, $cond);
    }
    elsif (ref $cond) {
        # Blessed object or unrecognised ref type — warn and treat as no-op
        carp(
            "search() received unrecognised condition type: "
            . ref($cond)
            . " — ignoring"
        );
        $new_cond = $existing;
    }
    else {
        # Plain scalar — not valid as a DBIx::Class condition
        croak(
            "search() received a plain scalar as condition: '$cond' "
            . "— did you mean \\\"$cond\" for literal SQL?"
        );
    }

    my $merged_attrs = $self->_merge_attrs($self->{_attrs}, $attrs);

    # Rewrite any { -ident => $col, -as => $alias } items in the select list
    # to bare column strings before the attrs are stored on the new ResultSet.
    # This must happen after _merge_attrs (so the full merged select/as arrays
    # are available) and before new_result_set (so the stored _attrs are clean
    # and every downstream method -- all_future, count, count_total, etc. --
    # sees correct attrs without needing their own normalisation call).
    $merged_attrs = DBIx::Class::Async::SelectNormaliser->normalise_attrs($merged_attrs);

    return $self->new_result_set({
        cond          => $new_cond,
        attrs         => $merged_attrs,
        pos           => 0,
        pager         => undef,
        entries       => undef,
        is_prefetched => 0,
    });
}

=head2 search_future

An alias for L</all_future>. Returns a L<Future> that resolves to the
full list of results matching the current ResultSet.

=cut

sub search_future { shift->all_future(@_)  }

=head2 search_literal

    my $new_rs = $rs->search_literal('price > ?', 100);

Adds a raw SQL fragment to the query criteria.

=over 4

=item * Safety

Parameters are passed as a bind list, preventing SQL injection.

=item * Chainability

Returns a new ResultSet, allowing you to chain further C<search> or
C<search_related> calls.

=back

=cut

sub search_literal {
    my ($self, $sql_fragment, @bind) = @_;

    # By passing it to $self->search, we guarantee:
    # 1. The new ResultSet gets the pinned _async_db and _schema_instance.
    # 2. Any existing 'where' or 'attrs' (like rows/order_by) are merged.
    return $self->search(
        \[ $sql_fragment, @bind ]
    );
}

=head2 search_rs

    my $new_rs = $rs->search_rs({ status => 'active' });

A synchronous method that returns a new ResultSet object with the added
search constraints. This is the standard way to chain query builders.

=cut

sub search_rs {
    my $self = shift;
    return $self->search(@_);
}

=head2 search_related

    my $future = $user_rs->search_related('orders');

Like C<search_related_rs>, but immediately triggers the database fetch.
Returns a L<Future> resolving to an arrayref of related Row objects.

=cut

sub search_related {
    my ($self, $rel_name, $cond, $attrs) = @_;

    # Use the helper to get the new configuration
    my $new_rs = $self->search_related_rs($rel_name, $cond, $attrs);

    # In an async context, search_related usually implies
    # wanting the ResultSet object to call ->all_future on later.
    return $new_rs->all;
}

=head2 search_related_rs

    my $orders_rs = $user_rs->search_related_rs('orders', { status => 'shipped' });

Pivots from the current ResultSet to a related data source. This is the core of
L<DBIx::Class> relational power.

=over 4

=item * Shadow Translation

Internally uses a temporary L<DBIx::Class::ResultSet> to calculate the complex
join logic and foreign key mappings.

=item * State Persistence

The resulting ResultSet inherits the C<async_db> and C<schema_instance>, allowing
it to execute the related query on the background worker.

=item * Namespace Resolution

Automatically resolves the target C<source_name> based on the relationship mapping.

=back

=cut

sub search_related_rs {
    my ($self, $rel_name, $cond, $attrs) = @_;

    # 1. Get the source. If _source is undef, pull it from the schema
    my $source = $self->{_result_source}
              || $self->{_schema_instance}->resultset($self->{_source_name})->result_source;

    # 2. Create the Shadow RS starting from the PARENT source
    require DBIx::Class::ResultSet;
    my $parent_shadow = DBIx::Class::ResultSet->new($source, {
         cond  => $self->{_cond}  || {},
         attrs => $self->{_attrs} || {},
    });

    # 3. Pivot
    # my $related_shadow = $shadow_rs->search_related($rel_name, $cond, $attrs);

    # 3. Pivot using the standard DBIC logic
    # This forces DBIC to calculate the JOIN or the subquery for 'orders'
    my $related_shadow = $parent_shadow->search_related($rel_name, $cond, $attrs);

    # 4. Wrap with ALL required keys
    return DBIx::Class::Async::ResultSet->new(
        schema_instance => $self->{_schema_instance},
        async_db        => $self->{_async_db},
        source_name     => $related_shadow->result_source->source_name,

        cond => $related_shadow->{attrs}{where} || $related_shadow->{cond},

        # Only pass serialisable attrs
        attrs => {
            where    => $related_shadow->{attrs}{where},
            join     => $related_shadow->{attrs}{join},
            order_by => $related_shadow->{attrs}{order_by},
            rows     => $related_shadow->{attrs}{rows},
            page     => $related_shadow->{attrs}{page},
        },
    );
}

=head2 search_with_pager

    my ($rows_f, $pager_f) = $rs->search_with_pager({ status => 'active' }, { rows => 20 });

Executes a paginated search and returns a L<Future> that resolves to both the
retrieved rows and a populated L<Data::Page> (or Async Pager) object.

This is the most efficient way to handle UI pagination because it dispatches
the data fetch and the total count calculation simultaneously to the background
workers.

=over 4

=item * Auto-Paging

If no C<page> or C<rows> attributes are provided in C<$attrs>, the method defaults
to C<page(1)> to ensure a pager can be instantiated.

=item * Parallel Execution

Unlike standard synchronous code which fetches rows and *then* counts them, this
method uses C<Future->needs_all> to maximise throughput by running both queries
at once.

=item * Pager Syncing

The returned pager object is fully "hydrated" with the total entry count, meaning
methods like C<last_page>, C<entries_on_this_page>, and C<next_page> are immediately
available for use in your templates or API responses.

=back

Example: Implementing a Paginated API Endpoint

    $rs->search_with_pager({ category => 'books' }, { page => 2, rows => 50 })
       ->then(sub {
           my ($rows, $pager) = @_;

           return Future->done({
               data => [ map { $_->TO_JSON } @$rows ],
               meta => {
                   total_records => $pager->total_entries,
                   current_page  => $pager->current_page,
                   total_pages   => $pager->last_page,
               }
           });
       });

=cut

sub search_with_pager {
    my ($self, $cond, $attrs) = @_;

    # 1. Create the paged resultset
    # This applies any search conditions and returns a new RS instance
    my $paged_rs = $self->search($cond, $attrs);

    # 2. Ensure paging is actually active
    # If the user didn't provide 'rows' or 'page' in $attrs, we force page 1
    if (!$paged_rs->is_paged) {
        $paged_rs = $paged_rs->page(1);
    }

    # 3. Instantiate the Async Pager (using your existing method)
    my $pager = $paged_rs->pager;

    # 4. Fire parallel requests to the worker pool
    # 'all' initiates the data fetch; 'total_entries' initiates the count(*)
    my $data_f  = $paged_rs->all;
    my $total_f = $pager->total_entries;

    # 5. Return a combined Future
    # This resolves only when BOTH the data and the count are back from workers
    return Future->needs_all($data_f, $total_f)->then(sub {
        my ($rows, $total) = @_;

        # At this point, $pager->total_entries is already resolved internally
        # so the user can immediately call $pager->last_page, etc.
        return Future->done($rows, $pager);
    });
}

=head2 single

    my $future = $rs->single($cond?);

An alias for L</first>. Retrieves the first row matching the ResultSet's
criteria.

=cut

sub single { shift->first }

=head2 single_future

    my $user_f = $rs->single_future({ username => 'm_smith' });

A convenience method that performs a search for a specific condition and
immediately calls L</first>. It returns a L<Future> resolving to a single
Row object or C<undef>.

=over 4

=item * Contextual Search

If a C<$cond> (hashref) is provided, it creates a temporary narrowed ResultSet
before fetching.

=item * Efficiency

Like C<first>, this automatically applies a C<LIMIT 1> if no data is already
cached, ensuring the worker doesn't fetch unnecessary rows.

=back

=cut

sub single_future {
    my ($self, $cond) = @_;

    # If a condition is provided, chain it.
    # Otherwise, just call first on the current resultset.
    return $cond ? $self->search($cond)->first : $self->first;
}

=head2 stats

    my $all_stats = $rs->stats;
    my $q_count   = $rs->stats('queries');

Returns performance metrics from the underlying asynchronous bridge.

=over 4

=item * Key Mapping

Automatically handles both "clean" keys (C<queries>) and internal
keys (C<_queries>).

=item * Metrics included

Usually contains C<queries> (execution count), C<cache_hits>, and C<errors>.

=back

=cut

sub stats {
    my ($self, $key) = @_;

    # Return the whole stats hash if no key is provided
    return $self->{_async_db}->{_stats} unless $key;

    # Otherwise return the specific metric (e.g., 'queries')
    # Note: We map the public 'queries' to the internal '_queries'
    my $internal_key = $key =~ /^_/ ? $key : "_$key";
    return $self->{_async_db}->{_stats}->{$internal_key};
}

=head2 schema

    my $schema = $rs->schema;

Returns the L<DBIx::Class::Async::Schema> instance that originally spawned
this ResultSet. This is useful for pivoting to other ResultSets from within
a row-processing callback.

=cut

sub schema { shift->{_schema}; }

=head2 slice

    # Scalar context: returns a new ResultSet
    my $sub_rs = $rs->slice(10, 19);

    # List context: triggers execution
    my $future = $rs->slice(0, 4);

Returns a subset of the ResultSet based on specific start and end indices.

=over 4

=item * Zero-Indexed

Unlike C<page>, C<slice> uses 0-based indexing. For example, C<slice(0, 9)>
retrieves the first 10 rows.

=item * Mathematical Translation

Automatically converts the indices into C<offset> and C<rows> attributes
for the SQL generator.

=item * Context Sensitivity

=over 4

=item * In scalar context, it returns a new ResultSet object. This is
        ideal for further chaining or passing to a view.

=item * In list context, it behaves like L</all> and initiates an
        asynchronous fetch, returning a B<Future>.

=back

=item * Validation

Strictly enforces that indices are non-negative and that the first index
does not exceed the last.

=back

Example: Retrieving a specific "chunk" for processing

    # Get rows 100 through 150 (inclusive)
    $rs->slice(100, 149)->all->then(sub {
        my $rows = shift;
        process_batch($rows);
    });

=cut

sub slice {
    my ($self, $first, $last) = @_;

    # 1. Validation logic (remains the same)
    croak("slice requires two arguments (first and last index)")
        unless defined $first && defined $last;
    croak("slice indices must be non-negative integers")
        if $first < 0 || $last < 0;
    croak("first index must be less than or equal to last index")
        if $first > $last;

    # 2. Calculate pagination parameters
    my $offset = $first;
    my $rows   = $last - $first + 1;

    # 3. Create the limited ResultSet
    # Since search() already handles cloning and attr merging, use it!
    my $sliced_rs = $self->search(undef, {
        offset => $offset,
        rows   => $rows,
    });

    # 4. Context-aware return
    if (!wantarray) {
        # Scalar context: Return the RS for further chaining
        return $sliced_rs;
    }

    # List context: This is tricky in Async.
    # In standard DBIC, slice() in list context executes immediately.
    # To keep your current test style, we'll return the results of 'all'.
    # Note: If your 'all' returns a Future, list context users must
    # be aware they are getting a single Future object, not the rows yet.
    return $sliced_rs->all;
}

=head2 set_cache

    $rs->set_cache(\@data);

Manually populates the internal data buffer of the ResultSet.

=over 4

=item * Input Format

Requires an arrayref of either raw hashrefs (column data) or already-inflated Row objects.

=item * Inflation Trigger

By setting the internal C<_is_prefetched> flag, this method ensures that the
next time L</all> or L</next> is called, the library will process these entries
through the standard inflation logic.

=item * State Reset

Automatically clears any previously cached rows (C<_rows>) and resets the
internal cursor position (C<_pos>) to zero. This ensures that iteration
starts fresh with the new dataset.

=item * Chainable

Returns the ResultSet object, allowing for fluent initialisation.

=back

Example: Hydrating a ResultSet from an external cache

    my $cached_data = $memcached->get("users_batch_1");

    if ($cached_data) {
        $rs->set_cache($cached_data);
    }

    # Now $rs acts like it just hit the DB
    $rs->all->then(sub {
        my $rows = shift;
        say $_->email for @$rows;
    });

=cut

sub set_cache {
    my ($self, $cache) = @_;

    require Carp;
    Carp::croak("set_cache expects an arrayref of entries/objects")
        unless defined $cache && ref $cache eq 'ARRAY';

    # 1. Store as raw entries
    # This feeds line 129 in your 'all' method
    $self->{_entries} = $cache;

    # 2. Mark as prefetched
    # This triggers the inflation logic in line 129
    $self->{_is_prefetched} = 1;

    # 3. Clear any existing inflated rows and reset position
    # This ensures that if the cache is updated, the inflation happens again
    $self->{_rows} = undef;
    $self->{_pos}  = 0;

    return $self;
}

=head2 update

    # Bulk update all rows in the current ResultSet
    $rs->search({ status => 'pending' })->update({ status => 'processing' });

    # Single targeted update ignoring current RS filters
    $rs->update({ id => 42 }, { status => 'archived' });

Performs an asynchronous C<UPDATE> operation on the database.

=over 4

=item * Set-Based Operation

Unlike a row-level update, this method acts on the entire scope of the
ResultSet in a single database round-trip.

=item * Cache Invalidation

Automatically calls C<clear_cache> on the ResultSet. This prevents the
parent process from serving stale data after the update has completed.

=item * Deflation Support

Automatically detects columns that require custom serialisation (e.g.,
JSON to string, DateTime to ISO string) by consulting the C<_custom_inflators> registry.

=item * Flexible Signature

=over 4

=item * C<update(\%updates)>: Uses the ResultSet's existing C<where> clause.

=item * C<update(\%cond, \%updates)>: Overrides the current filters with the provided C<%cond>.

=back

=back

Example: Atomic Batch Update with Deflation

    # Assuming 'metadata' is a column that deflates to JSON
    my $future = $rs->search({ active => 1 })
                    ->update({
                        last_updated => \'NOW()',
                        metadata     => { version => '2.0', source => 'api' }
                    });

    $future->on_done(sub { say "Batch update complete." });

=cut

sub update {
    my $self = shift;
    my ($cond, $updates);

    # Logic to handle both:
    #   ->update({ col => val })
    #   ->update({ id => 1 }, { col => val })
    if (@_ > 1) {
        ($cond, $updates) = @_;
    } else {
        $updates = shift;
        $cond    = $self->{_cond};
    }

    my @pk_cols = $self->result_source->primary_columns;
    my $cache_key;

    if (ref($cond) eq 'HASH' && @pk_cols) {
        my %pk_cond = map {
            $_ => $cond->{$_}
        } grep {
            exists $cond->{$_}
        } @pk_cols;

        if (%pk_cond) {
            $cache_key = $self->_generate_cache_key(0, \%pk_cond);
        }
    }

    $cache_key ||= $self->_generate_cache_key(0, $cond);

    my $db = $self->{_async_db};
    my $inflators = $db->{_custom_inflators}{ $self->{_source_name} } || {};

    # Ensure nested Hashes are turned back into Strings for the database
    foreach my $col (keys %$updates) {
        if ($inflators->{$col} && $inflators->{$col}{deflate}) {
            $updates->{$col} = $inflators->{$col}{deflate}->($updates->{$col});
        }
    }

    return DBIx::Class::Async::_call_worker(
        $db,
        'update',
        {
            source_name => $self->{_source_name},
            cond        => $cond,
            updates     => $updates,
        }
    );
}

=head2 update_all

    my $future = $rs->search({ type => 'temporary' })->update_all({ type => 'permanent' });

Performs a two-step asynchronous update. First, it retrieves all rows matching
the current criteria to identify their Primary Keys, then it issues a
bulk update targeting those specific IDs.

=over 4

=item * Precision

By fetching the IDs first, this method ensures that triggers or logic dependent
on the primary key are correctly handled.

=item * Safety

If no rows match the initial search, the method short-circuits and returns a
resolved Future with a value of C<0>, avoiding an unnecessary database trip
for the update phase.

=item * Traceability

Supports C<ASYNC_TRACE> logging to help debug empty sets or unexpected data
types during the fetch phase.

=item * Atomicity Note

Unlike C<update>, this involves two distinct database interactions. If the
data changes between the fetch and the update phase, only the rows identified
in the first phase will be updated.

=back

Example: Safe Batch Update

    $rs->update_all({ last_processed => \'NOW()' })->on_done(sub {
        my $count = shift;
        print "Successfully updated $count specific records.\n";
    });

=cut

sub update_all {
    my ($self, $updates) = @_;
    my $bridge = $self->{_async_db};

    return $self->all->then(sub {
        my $rows = shift;

        # Hard check: is it really an arrayref?
        unless ($rows && ref($rows) eq 'ARRAY' && @$rows) {
            warn "[PID $$] update_all found no rows to update or invalid data type"
                if ASYNC_TRACE;
            return Future->done(0);
        }

        my ($pk) = $self->result_source->primary_columns;
        my @ids  = map { $_->get_column($pk) } @$rows;

         my $payload = {
            source_name => $self->{_source_name},
            cond        => { $pk => { -in => \@ids } },
            updates     => $updates,
        };

        return DBIx::Class::Async::_call_worker(
            $bridge,
            'update',
            $payload)->then(sub {
            my $affected = shift;
            return Future->done($affected);
        });
    });
}

=head2 update_or_new

    my $future = $rs->update_or_new({
        email => 'dev@example.com',
        name  => 'Gemini'
    });

Attempts to locate a record using its unique constraints or primary key.

=over 4

=item * Action on Success

If the record is found, it immediately triggers an asynchronous C<update>
with the provided data and returns a L<Future> resolving to the updated Row object.

=item * Action on Failure

If no record is found, it creates a new B<in-memory> row object. This object
is B<not> yet saved to the database (C<in_storage> will be false).

=item * Data Sanitisation

Automatically strips table aliases (C<me.>, C<foreign.>) from the data keys
to ensure the Row object constructor receives clean column names.

=item * Consistency

This method always returns a B<Future>, regardless of whether it performed a
database update or a local object instantiation.

=back

Example: Syncing User Profiles

    $rs->update_or_new({
        external_id => $id,
        last_login  => \'NOW()'
    })->then(sub {
        my $user = shift;
        if ($user->in_storage) {
            say "Updated existing user: " . $user->id;
        } else {
            say "Prepared new user for registration.";
            # You must call ->insert on the new object to persist it
            return $user->insert;
        }
    });

=cut

sub update_or_new {
    my ($self, $data, $attrs) = @_;
    $attrs //= {};

    # Identify the primary key or unique constraint values for the lookup
    my $lookup = $self->_extract_unique_lookup($data, $attrs);

    return $self->find($lookup, $attrs)->then(sub {
        my ($row) = @_;

        if ($row) {
            # Object found in DB: trigger an async UPDATE
            return $row->update($data);
        }

        # Object NOT found: merge condition and data for a local 'new' object
        my %new_data = ( %{$self->{_cond} || {}}, %$data );
        my %clean_data;
        while (my ($k, $v) = each %new_data) {
            # Strip DBIC aliases so they don't crash the Row constructor
            (my $clean_key = $k) =~ s/^(?:me|foreign|self)\.//;
            $clean_data{$clean_key} = $v;
        }

        # Returns a Future wrapping the local Row object (in_storage = 0)
        return Future->done($self->new_result(\%clean_data));
    });
}

=head2 update_or_create

    my $future = $rs->update_or_create({
        username => 'coder123',
        last_seen => \'NOW()'
    });

Attempts to find a record by its unique constraints. If found, it updates it.
If not, it creates a new record in the database.

=over 4

=item * Atomic Strategy

This method manages the "Check-then-Act" pattern safely across asynchronous workers.

=item * Race Condition Recovery

In highly concurrent systems, a record might be inserted by another process
between this method's C<find> and C<create> steps. This method detects that
specific database conflict (Unique Constraint Violation) and automatically
recovers by re-finding the newly created record and updating it instead.

=item * Error Handling

While it handles "Already Exists" conflicts gracefully, other database errors
(like type mismatches or connection issues) will still trigger a C<fail>
state in the returned Future.

=back

Example: Distributed Token Sync

    # Multiple workers might run this for the same 'service_key'
    $schema->resultset('AuthToken')->update_or_create({
        service_key => 'worker_node_1',
        token       => $new_secure_token
    })->on_done(sub {
        my $row = shift;
        say "Token synced for ID: " . $row->id;
    })->on_fail(sub {
        die "Sync failed: " . shift;
    });

=cut

sub update_or_create {
    my ($self, $data, $attrs) = @_;
    $attrs //= {};

    my $lookup = $self->_extract_unique_lookup($data, $attrs);

    return $self->find($lookup, $attrs)->then(sub {
        my ($row) = @_;

        if ($row) {
            # 1. Standard Update Path
            return $row->update($data);
        }

        # 2. Not Found: Attempt Create
        return $self->create($data)->catch(sub {
            my ($error, $type) = @_;

            # If it's a DB unique constraint error, someone else beat us to the insert
            if ($type eq 'db_error' && "$error" =~ /unique constraint|already exists/i) {

                # 3. Race Recovery: Re-find the winner and update them
                return $self->find($lookup, $attrs)->then(sub {
                    my ($recovered) = @_;
                    return $recovered
                        ? $recovered->update($data)
                        : Future->fail("Race recovery failed: record vanished after conflict", "logic_error");
                });
            }

            # Otherwise, bubble up the original error
            return Future->fail($error, $type);
        });
    });
}

=head2 update_query

    my ($sql, @bind) = $rs->update_query(\%updates);
    my $query = $rs->update_query(\%updates);

Returns the SQL and bind values that would be generated by an update operation
without actually executing it. This is useful for debugging, logging, auditing,
or testing.

Returns the same structure as L</as_query>: a reference to an array containing
the SQL (as a scalar reference) and bind values.

    my $rs = $schema->resultset('User')->search({ active => 0 });
    my ($sql, @bind) = $rs->update_query({ active => 1 });
    # $sql = \'UPDATE users SET active = ? WHERE active = ?'
    # @bind = (1, 0)

    # Audit logging
    warn "About to execute: $$sql with binds: @bind";
    $rs->update({ active => 1 })->get;  # Now execute

=cut

sub update_query {
    my ($self, $values) = @_;

    my $bridge       = $self->{_async_db};
    my $schema_class = $bridge->{_schema_class};

    unless ($schema_class->can('resultset')) {
        eval "require $schema_class" or die "update_query: $@";
    }

    # Silence warnings
    local $SIG{__WARN__} = sub {
        if (ASYNC_TRACE) {
            warn @_ unless $_[0] =~ /undetermined_driver|sql_limit_dialect|GenericSubQ/
        }
    };

    unless ($bridge->{_metadata_schema}) {
        $bridge->{_metadata_schema} = $schema_class->connect('dbi:NullP:');
    }

    # Create a sync ResultSet with the same conditions
    my $real_rs = $bridge->{_metadata_schema}
                         ->resultset($self->{_source_name})
                         ->search($self->{_cond}, $self->{_attrs});

    # Generate SQL using DBIC's internal update SQL generator
    my $storage = $bridge->{_metadata_schema}->storage;

    # Get the update SQL - use DBIC's internal methods
    my ($sql, @bind);

    # DBIC stores the SQL generation in storage->update
    # We need to use the same path as actual execution but capture the SQL
    eval {
        # Get source and create update statement
        my $source = $real_rs->result_source;
        my $cond   = $real_rs->{cond};
        my $attrs  = $real_rs->{attrs};

        # Build WHERE clause from search conditions
        my ($where_sql, @where_bind) = $storage->sql_maker->where($cond);

        # Build SET clause from update values
        my (@set_parts, @set_bind);
        for my $col (sort keys %$values) {
            push @set_parts, "$col = ?";
            push @set_bind, $values->{$col};
        }
        my $set_sql = join(', ', @set_parts);

        # Construct full UPDATE statement
        my $table = $source->from;
        $sql  = \"UPDATE $table SET $set_sql$where_sql";
        @bind = (@set_bind, @where_bind);
    };

    if ($@) {
        croak("Failed to generate update SQL: $@");
    }

    return wantarray ? ($sql, @bind) : \[ $sql, @bind ];
}

#
#
# PRIVATE METHODS

sub _new_prefetched_dataset {
    my ($self, $data, $rel_name) = @_;

    # 1. Identify the target source for the relationship
    my $rel_info = $self->result_source->relationship_info($rel_name)
        or die "No relationship info found for: $rel_name";

    my $rel_source_class = $rel_info->{source};

    # Extract moniker: "TestSchema::Result::Order" -> "Order"
    my $rel_moniker = $rel_source_class;
    $rel_moniker    =~ s/^.*::Result:://;

    # 2. Build args - let the schema handle the source lookup
    my %new_args = (
        schema_instance => $self->{_schema_instance},
        async_db        => $self->{_async_db},
        source_name     => $rel_moniker,
        cond            => {},
        attrs           => {},
    );

    # 3. Create ResultSet via schema to ensure proper source binding
    my $new_rs = $self->{_schema_instance}->resultset($rel_moniker);

    # 4. Populate internal cache with inflated Row objects
    my @rows_data     = (ref $data eq 'ARRAY') ? @$data : ($data);
    my @inflated_rows = map { $new_rs->new_result($_) } grep { defined } @rows_data;

    $new_rs->{_entries} = \@inflated_rows;
    $new_rs->{_is_prefetched} = 1;

    return $new_rs;
}

sub _generate_cache_key {
    my ($self, $is_count_op, $specific_cond) = @_;

    # Don't cache if there's dynamic SQL
    if ($self->_has_dynamic_sql) {
        return undef;
    }

    # Force Data::Dumper to be a "pure" string generator
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Sortkeys = 1;

    my %clean_attrs;
    my $orig_attrs = $self->{_attrs} // {};

    # Whitelist only keys that affect SQL
    foreach my $key (qw(rows offset alias page order_by group_by select as join prefetch)) {
        $clean_attrs{$key} = $orig_attrs->{$key} if exists $orig_attrs->{$key};
    }

    if ($is_count_op && ($clean_attrs{rows} || $clean_attrs{offset})) {
         $clean_attrs{alias}       //= 'subquery_for_count';
         $clean_attrs{is_subquery} //= 1;
    }

    # Use specific condition if provided (for updates), otherwise fall back to internal
    my $cond = $specific_cond // $self->{_cond} // {};

    # Ensure key is based on Primary Key if possible
    my @pk_cols = $self->result_source->primary_columns;
    if (ref($cond) eq 'HASH' && @pk_cols && exists $cond->{$pk_cols[0]}) {
        $cond = { map { $_ => $cond->{$_} } @pk_cols };
    }

    # Format Dumper output cleanly
    my $dumped_cond  = Data::Dumper->new([$cond])->Dump;
    my $dumped_attrs = Data::Dumper->new([\%clean_attrs])->Dump;
    $dumped_cond  =~ s/\n/ /g;
    $dumped_attrs =~ s/\n/ /g;

    return join('|',
        $self->{_source_name} // '',
        $dumped_cond,
        $dumped_attrs,
    );
}

sub _has_dynamic_sql {
    my ($self) = @_;

    my $attrs = $self->{_attrs} || {};

    # List of non-deterministic SQL functions that should not be cached
    my $dynamic_functions = qr/\b(?:
    NOW|CURTIME|CURDATE|CURRENT_TIME|CURRENT_DATE|CURRENT_TIMESTAMP|
    SYSDATE|LOCALTIME|LOCALTIMESTAMP|UTC_TIME|UTC_DATE|UTC_TIMESTAMP|
    UNIX_TIMESTAMP|
    DATETIME|
    TIMESTAMP|
    RAND|RANDOM|
    UUID|UUID_SHORT
    )\s*\(/ix;

    # Helper to check if a value contains dynamic SQL
    my $check_value = sub {
        my ($val) = @_;

        # Check for ScalarRef (literal SQL)
        if (ref($val) eq 'SCALAR') {
            return 1 if $$val =~ $dynamic_functions;
        }
        # Check for RefRef (escaped literal)
        elsif (ref($val) eq 'REF' && ref($$val) eq 'SCALAR') {
            return 1 if $$$val =~ $dynamic_functions;
        }
        # Check for plain strings that might contain SQL
        elsif (!ref($val) && defined $val) {
            return 1 if $val =~ $dynamic_functions;
        }

        return 0;
    };

    # Check +select (additional columns)
    if ($attrs->{'+select'}) {
        my @selects = ref($attrs->{'+select'}) eq 'ARRAY'
                     ? @{$attrs->{'+select'}}
                     : ($attrs->{'+select'});

        for my $sel (@selects) {
            # Hash form: { '' => \'NOW()', -as => 'current_time' }
            if (ref($sel) eq 'HASH') {
                for my $key (keys %$sel) {
                    next if $key eq '-as';  # Skip alias
                    return 1 if $check_value->($sel->{$key});
                }
            }
            # Direct form: \'NOW()'
            else {
                return 1 if $check_value->($sel);
            }
        }
    }

    # Check select (column list)
    if ($attrs->{select}) {
        my @selects = ref($attrs->{select}) eq 'ARRAY'
                     ? @{$attrs->{select}}
                     : ($attrs->{select});

        for my $sel (@selects) {
            # Hash form: { count => 'id', -as => 'total' }
            if (ref($sel) eq 'HASH') {
                for my $key (keys %$sel) {
                    next if $key eq '-as';  # Skip alias
                    return 1 if $check_value->($sel->{$key});
                }
            }
            # Direct form
            else {
                return 1 if $check_value->($sel);
            }
        }
    }

    # Check +columns (similar to +select)
    if ($attrs->{'+columns'}) {
        my @cols = ref($attrs->{'+columns'}) eq 'ARRAY'
                  ? @{$attrs->{'+columns'}}
                  : ($attrs->{'+columns'});

        for my $col (@cols) {
            if (ref($col) eq 'HASH') {
                for my $val (values %$col) {
                    return 1 if $check_value->($val);
                }
            }
            else {
                return 1 if $check_value->($col);
            }
        }
    }

    # Check having clause (may contain aggregate functions with dynamic SQL)
    if ($attrs->{having}) {
        if (ref($attrs->{having}) eq 'HASH') {
            for my $val (values %{$attrs->{having}}) {
                return 1 if $check_value->($val);
            }
        }
    }

    # Check where conditions for literal SQL
    if ($self->{_cond}) {
        my $check_cond;
        $check_cond = sub {
            my ($cond) = @_;

            if (ref($cond) eq 'HASH') {
                for my $key (keys %$cond) {
                    my $val = $cond->{$key};

                    # Check the key itself (might be literal SQL)
                    return 1 if $check_value->($key);

                    # Recursively check nested conditions
                    if (ref($val) eq 'HASH') {
                        return 1 if $check_cond->($val);
                    }
                    elsif (ref($val) eq 'ARRAY') {
                        for my $item (@$val) {
                            return 1 if $check_value->($item);
                            return 1 if ref($item) eq 'HASH' && $check_cond->($item);
                        }
                    }
                    else {
                        return 1 if $check_value->($val);
                    }
                }
            }
            elsif (ref($cond) eq 'ARRAY') {
                for my $item (@$cond) {
                    return 1 if $check_cond->($item);
                }
            }

            return 0;
        };

        return 1 if $check_cond->($self->{_cond});
    }

    return 0;
}

sub _build_payload {
    my ($self, $cond, $attrs, $is_count_op) = @_;

    # 1. Condition Merging (Improved Literal Awareness)
    my $base_cond = $self->{_cond};
    my $new_cond  = $cond;
    my $merged_cond;

    if (ref($base_cond) eq 'HASH' && ref($new_cond) eq 'HASH') {
        $merged_cond = { %$base_cond, %$new_cond };
    }
    elsif (ref($new_cond) && ref($new_cond) ne 'HASH') {
        $merged_cond = $new_cond; # Literal SQL takes priority
    }
    else {
        $merged_cond = $new_cond // $base_cond // {};
    }

    # 2. Attribute Merging (Harden against non-HASH attrs)
    my $merged_attrs = (ref($self->{_attrs}) eq 'HASH' && ref($attrs) eq 'HASH')
        ? { %{$self->{_attrs}}, %{$attrs // {}} }
        : ($attrs // $self->{_attrs} // {});

    # 3. Only apply the Subquery Alias if we are specifically doing a COUNT
    # and there is a limit/offset involved.
    if ( $is_count_op
        && ( $merged_attrs->{rows}
             || $merged_attrs->{offset}
             || $merged_attrs->{limit} ) ) {
        $merged_attrs->{alias}       //= 'subquery_for_count';
        $merged_attrs->{is_subquery} //= 1;
    }

    return {
        source_name => $self->{_source_name},
        cond        => $merged_cond,
        attrs       => $merged_attrs,
    };
}

sub _find_reverse_relationship {
    my ($self, $source, $rel_source, $forward_rel) = @_;

    unless (ref $rel_source && $rel_source->can('relationships')) {
        confess("Critical Error: _find_reverse_relationship expected a ResultSource object but got: " . ($rel_source // 'undef'));
    }

    my @rel_names    = $rel_source->relationships;
    my $forward_info = $source->relationship_info($forward_rel);
    my $forward_cond = $forward_info->{cond};

    # 1. Extract keys from forward condition (e.g., 'foreign.user_id' => 'self.id')
    my ($forward_foreign, $forward_self);
    if (ref $forward_cond eq 'HASH') {
        my ($f, $s) = %$forward_cond;
        # Handle cases where value is a hash (like { -ident => 'id' })
        $s = $s->{'-ident'} // $s if ref $s eq 'HASH';

        $forward_foreign = $f =~ s/^foreign\.//r;
        $forward_self    = $s =~ s/^self\.//r;
    }

    # 2. Look for a relationship that points back to our source with matching keys
    foreach my $rev_rel (@rel_names) {
        my $rev_info       = $rel_source->relationship_info($rev_rel);
        my $rev_source_obj = $rel_source->related_source($rev_rel);

        # Check if this relationship points back to our original source
        next unless $rev_source_obj->source_name eq $source->source_name;

        # Validate the foreign keys match (in reverse)
        my $rev_cond = $rev_info->{cond};
        if (ref $rev_cond eq 'HASH') {
            my ($rev_foreign, $rev_self) = %$rev_cond;
            $rev_self = $rev_self->{'-ident'} // $rev_self if ref $rev_self eq 'HASH';

            my $rf_clean = $rev_foreign =~ s/^foreign\.//r;
            my $rs_clean = $rev_self    =~ s/^self\.//r;

            # The logic check:
            # If Forward is: Order(user_id) -> User(id)
            # Reverse must be: User(id) -> Order(user_id)
            if ($rf_clean eq $forward_self && $rs_clean eq $forward_foreign) {
                return $rev_rel;
            }
        }
    }

    # 3. Fallback: If we couldn't find it by key matching, try by source name only
    foreach my $rev_rel (@rel_names) {
        if ($rel_source->related_source($rev_rel)->source_name eq $source->source_name) {
            return $rev_rel;
        }
    }

    return undef;
}

sub _extract_unique_lookup {
    my ($self, $data, $attrs) = @_;

    my $source = $self->result_source;
    my $key_name = $attrs->{key} || 'primary';
    my @unique_cols = $source->unique_constraint_columns($key_name);

    # Alias-aware grep for primary check
    if (!grep { exists $data->{$_} || exists $data->{"me.$_"} } @unique_cols) {
        foreach my $constraint ($source->unique_constraint_names) {
            my @cols = $source->unique_constraint_columns($constraint);
            # Alias-aware grep for discovery loop
            if (grep { exists $data->{$_} || exists $data->{"me.$_"} } @cols) {
                @unique_cols = @cols;
                last;
            }
        }
    }

    # Build the lookup, checking for aliases
    my %lookup;
    foreach my $col (@unique_cols) {
        if (exists $data->{$col}) {
            $lookup{$col} = $data->{$col};
        }
        elsif (exists $data->{"me.$col"}) {
            $lookup{$col} = $data->{"me.$col"};
        }
    }

    # Absolute fallback
    return keys %lookup ? \%lookup : $data;
}

sub _inflate_row {
    my ($self, $hash) = @_;
    return undef unless $hash;

    # Apply Column Inflation
    my $db          = $self->{_async_db};
    my $source_name = $self->{_source_name};
    my $inflators   = $db->{_custom_inflators}{$source_name} || {};

    foreach my $col (keys %$inflators) {
        if (exists $hash->{$col} && $inflators->{$col}{inflate}) {
            # This turns your JSON string back into a HASH ref!
            $hash->{$col} = $inflators->{$col}{inflate}->($hash->{$col});
        }
    }

    # ------------------------------------------------------------------
    # Inflate datetime columns for result classes that load
    # InflateColumn::DateTime. The worker inflates correctly but sends
    # raw strings back to the parent. We re-inflate here using the
    # storage formatter detected from the DSN, since the parent process
    # holds no active DB connection and ->storage returns nothing.
    # This also applies the PR#138 fix by setting the formatter on the
    # resulting DateTime object.
    # ------------------------------------------------------------------
    my $result_source = $self->result_source;
    my $result_class  = $result_source->result_class;

    if ( $result_class->isa('DBIx::Class::InflateColumn::DateTime') ) {
        my $formatter = $db->{_datetime_formatter};
        my $parse_dt;

        if ($formatter) {
            $parse_dt = $formatter->isa('DateTime::Format::Pg')
                ? sub { $formatter->parse_timestamptz($_[0]) }
                : sub { $formatter->parse_datetime($_[0]) };
        }

        if ($parse_dt) {
            for my $col (keys %$hash) {
                next unless defined $hash->{$col};
                next if ref $hash->{$col};
                next if $inflators->{$col};

                my $col_info  = eval { $result_source->column_info($col) } // {};
                my $data_type = lc( $col_info->{data_type} // '' );
                next unless $DATETIME_COLUMN_TYPES{$data_type};
                next if exists $col_info->{inflate_datetime}
                    && !$col_info->{inflate_datetime};

                my $dt = eval { $parse_dt->( $hash->{$col} ) };
                next if $@ || !defined $dt;

                $dt->set_formatter($formatter)
                    if eval { $dt->isa('DateTime') } && !$dt->formatter;

                $hash->{$col} = $dt;
            }
        }
    }

    # Create the base row object
    my $row = $self->new_result($hash);
    $row->in_storage(1);

    # Inject Relationship Data (already perfect)
    for my $rel ($self->result_source->relationships) {
        if (exists $hash->{$rel}) {
            $row->{_relationship_data}{$rel} = $hash->{$rel};
        }
    }

    return $row;
}

# _merge_attrs
#
#    my $merged = $self->_merge_attrs(\%base, \%extra);
#
# Internal method. Deep-merges two attribute hashes.
#
# Accumulating keys (C<join>, C<prefetch>, C<columns>, C<+columns>,
# C<select>, C<as>, C<order_by>, C<group_by>, C<having>) are concatenated
# and deduplicated by string value. All other keys are overwritten by the
# extra value.

sub _merge_attrs {
    my ($self, $base, $extra) = @_;

    $base  //= {};
    $extra //= {};

    my %merged = %$base;

    for my $key (keys %$extra) {
        if ($ACCUMULATING_ATTRS{$key} && exists $merged{$key}) {
            # Normalise both sides to flat arrayrefs
            my $base_val  = ref $merged{$key}  eq 'ARRAY'
                                ? $merged{$key}
                                : [ $merged{$key} ];
            my $extra_val = ref $extra->{$key} eq 'ARRAY'
                                ? $extra->{$key}
                                : [ $extra->{$key} ];

            # Concatenate and deduplicate by string value.
            # We preserve order (first occurrence wins) to keep
            # join/prefetch ordering stable and avoid surprising
            # SQL changes on re-runs.
            my %seen;
            $merged{$key} = [
                grep { !$seen{ _dedup_key($_) }++ }
                     @$base_val, @$extra_val
            ];
        }
        else {
            # Scalar or non-accumulating key: extra wins
            $merged{$key} = $extra->{$key};
        }
    }

    return \%merged;
}

# Produce a stable string key for deduplication.
# Handles plain strings, hashrefs (e.g. { rel => 'sub_rel' }),
# and arrayrefs (nested join specs).

sub _dedup_key {
    my $val = shift;
    return 'undef' unless defined $val;
    return $val     unless ref $val;
    # Lean on Data::Dumper for a cheap stable serialisation of
    # nested join/prefetch specs like { orders => 'items' }.
    # Sorted keys ensures { a=>1, b=>1 } eq { b=>1, a=>1 }.
    require Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Terse    = 1;
    return Data::Dumper::Dumper($val);
}

sub _is_empty_cond {
    my $c = shift;
    return 1 unless defined $c;
    return 1 if ref $c eq 'HASH'  && !keys %$c;
    return 1 if ref $c eq 'ARRAY' && !@$c;
    return 0;
}

sub _merge_cond {
    my ($existing, $new) = @_;

    my $existing_empty = _is_empty_cond($existing);
    my $new_empty      = _is_empty_cond($new);

    return {}          if  $existing_empty &&  $new_empty;
    return $new        if  $existing_empty && !$new_empty;
    return $existing   if !$existing_empty &&  $new_empty;
    return { -and => [ $existing, $new ] };
}

sub _generate_empty_select_query {
    my $self = shift;

    my $bridge  = $self->{_async_db};
    my $storage = $bridge->{_metadata_schema}->storage;
    my $source  = $bridge->{_metadata_schema}->source($self->{_source_name});

    # Build WHERE clause if conditions exist
    my $cond = $self->{_cond} || {};
    my ($where_sql, @bind) = $storage->sql_maker->where($cond);

    # Get table name (handles joins, subqueries, etc.)
    my $table = $source->from;

    # Detect database type for optimal SQL generation
    my $driver = eval { $storage->sqlt_type } || '';

    my $sql;
    if ($driver =~ /^(PostgreSQL|Pg)$/i) {
        # PostgreSQL natively supports column-less SELECT
        $sql = \"SELECT FROM $table$where_sql";
    }
    else {
        # For other databases, use SELECT 1 as minimal portable query
        # SQLite, MySQL, Oracle, etc. all support this
        $sql = \"SELECT 1 FROM $table$where_sql";
    }

    # Return in same format as real as_query
    return wantarray ? ($sql, @bind) : \[$sql, @bind];
}

=head1 AUTOMATIC CACHE SAFETY

L<DBIx::Class::Async> automatically analyses your queries for non-deterministic
SQL functions (e.g., B<NOW()>, B<CURTIME()>, B<RAND()>, B<UUID()>).

If detected in the B<WHERE> clause, B<SELECT> list, or B<HAVING> clause, the
caching mechanism will be B<automatically bypassed> for that specific query,
even if B<cache_ttl> is enabled, to ensure data integrity.

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

    perldoc DBIx::Class::Async::ResultSet

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

1; # End of DBIx::Class::Async::ResultSet
