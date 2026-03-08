package DBIx::Class::Async;

$DBIx::Class::Async::VERSION   = '0.64';
$DBIx::Class::Async::AUTHORITY = 'cpan:MANWAR';

=encoding utf8

=head1 NAME

DBIx::Class::Async - Non-blocking, multi-worker asynchronous wrapper for DBIx::Class

=head1 VERSION

Version 0.64

=head1 DISCLAIMER

B<This is pure experimental currently.>

You are encouraged to try and share your suggestions.

=head1 QUICK START

This example demonstrates how to set up a small C<SQLite> database and
perform an asynchronous B<"Create and Count"> operation.

    use strict;
    use warnings;
    use IO::Async::Loop;
    use DBIx::Class::Async::Schema;

    my $loop = IO::Async::Loop->new;

    # 1. Connect to your database
    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=myapp.db", undef, undef, {},
        {
            workers      => 2,              # Keep 2 database connections ready
            schema_class => 'MyApp::Schema' # Your DBIC Schema name
        }
    );

    # 2. Deploy (Create tables if they don't exist)
    $schema->await($schema->deploy);

    # 3. Non-blocking workflow
    # We don't "wait" for the DB; we tell the loop what to do when it's done.
    $schema->resultset('User')
           ->create({ name => 'Starlight', email => 'star@perl.org' })
           ->then(
                sub {
                    return $schema->resultset('User')->count;
                })
           ->on_done(
                sub {
                    my $count = shift;
                    print "User saved! Total users now: $count\n";
                })
           ->on_fail(
                sub {
                    warn "Something went wrong: @_\n";
                });

    # 4. Start the engine
    $loop->run;

=head1 SYNOPSIS

    use IO::Async::Loop;
    use DBIx::Class::Async::Schema;

    my $loop = IO::Async::Loop->new;

    # Connect returns a "Virtual Schema" that behaves like DBIC
    # but returns Futures instead of data.
    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=app.db", undef, undef, {},
        {
            workers      => 4,             # Parallel database connections
            schema_class => 'My::Schema',  # Your standard DBIC Schema
            async_loop   => $loop,
        }
    );

    # 1. Simple CRUD (Returns a Future)
    my $future = $schema->resultset('User')->find(1);

    $future->on_done(sub {
        my $user = shift;
        print "Found: " . $user->name . "\n" if $user;
    });

    # 2. Modern Async/Await style
    async sub get_user_count {
        my $count = await $schema->resultset('User')->count;
        return $count;
    }

    # 3. Batch Transactions
    my $tx = await $schema->txn_do([
        { action => 'create', resultset => 'User', data => { name => 'Alice' }, name => 'new_user'  },
        { action => 'create', resultset => 'Log',  data => { msg  => "Created user \$new_user.id" } }
    ]);

=head1 THE ASYNC DESIGN APPROACH

The "Real Truth" about L<DBIx::Class> is that it is inherently synchronous. Under the hood, L<DBI> and most database drivers (like L<DBD::SQLite> or L<DBD::mysql>) block the entire Perl process while waiting for the database to respond.

=head2 How it used to be (The Old Design)

In traditional async Perl, developers often tried to wrap DBIC calls in a simple L<Future>. However, because the underlying L<DBI> call was still blocking, one slow query would "freeze" the entire event loop. Your UI would hang, and other network requests would stop.

=head2 How we do it now (The "Bridge & Worker" Design)

C<DBIx::Class::Async> uses a B<Worker-Pool Architecture>.

=over 4

=item * The Bridge (Main Process)

When you call C<find>, C<search>, or C<create>, the main process doesn't talk to the database. It packages your request and sends it over a pipe to an available worker. It then immediately returns a L<Future> and goes back to work handling other events.

=item * The Workers (Background Processes)

We maintain a pool of background processes. Each worker has its own dedicated connection to the database. The worker performs the blocking DBIC call, serialises the result, and sends it back to the Bridge.

=item * The Result

The Bridge receives the data, resolves the C<Future>, and your code continues.

=back

=head2 Why this is better:

=over 4

=item * Zero Loop Freezing

Even if a query takes 10 seconds, your main application loop remains 100% responsive.

=item * True Parallelism

With 4 workers, you can execute 4 heavy database queries simultaneously. Standard DBIC can only do 1 at a time.

=item * Automatic Serialisation

We handle the complex task of turning "live" DBIC objects into data structures that can safely travel between processes.

=back

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
use Scalar::Util qw(blessed);
use DBIx::Class::Async::Row;
use Types::Standard qw(Str ScalarRef HashRef ArrayRef Maybe Int CodeRef);

use DBIx::Class::Async::Exception::Factory;

use constant ASYNC_TRACE => $ENV{ASYNC_TRACE} || 0;
our $METRICS;

use constant {
    DEFAULT_WORKERS       => 4,
    DEFAULT_CACHE_TTL     => 0,
    DEFAULT_QUERY_TIMEOUT => 30,
    DEFAULT_RETRIES       => 3,
    HEALTH_CHECK_INTERVAL => 300,
};

=head1 METHODS

=head2 create_async_db

Initialises the async environment and spawns workers.

    my $db = DBIx::Class::Async->create_async_db(
        schema_class  => 'MyApp::Schema',
        connect_info  => [ 'dbi:SQLite:db.sqlite' ],
        workers       => 4,
        cache_ttl     => 300, # 5 minutes
        enable_retry  => 1,
    );

Set the default Time-To-Live for cached queries in seconds. Defaults to
B<0> (caching is B<disabled> by default).

To enable caching globally, set a positive integer. To enable it for a
specific query, use the B<cache> attribute in the search method.

B<Warning:> Be cautious enabling caching. Cached data can become stale, and
queries containing non-deterministic SQL functions (like B<NOW()>, B<RAND()>)
may produce incorrect results if cached.

=cut

sub create_async_db {
    my ($class, %args) = @_;

    my $schema_class = $args{schema_class} or croak "schema_class required";
    my $connect_info = $args{connect_info} or croak "connect_info required";
    my $workers      = $args{workers} || DEFAULT_WORKERS;

    unless (eval { $schema_class->can('connect') } || eval "require $schema_class") {
        croak "Cannot load schema class $schema_class: $@";
    }

    my $cache_ttl = exists $args{cache_ttl}
                    ? $args{cache_ttl}
                    : DEFAULT_CACHE_TTL;

    # 1. Extract Column Metadata (Inflators/Deflators)
    # We do this before creating the hashref so we can include it
    my $custom_inflators = {};
    if ($schema_class->can('sources')) {
        foreach my $source_name ($schema_class->sources) {
            my $source = $schema_class->source($source_name);
            foreach my $col ($source->columns) {
                my $info = $source->column_info($col);
                if ($info->{deflate} || $info->{inflate}) {
                    $custom_inflators->{$source_name}{$col} = {
                        deflate => $info->{deflate},
                        inflate => $info->{inflate},
                    };
                }
            }
        }
    }

    # 2. Build the async_db state hashref
    my $async_db = {
        _schema_class      => $schema_class,
        _connect_info      => $connect_info,
        _custom_inflators  => $custom_inflators,
        _loop              => $args{loop} || IO::Async::Loop->new,
        _workers           => [],
        _workers_config    => {
            _count         => $workers,
            _query_timeout => $args{query_timeout} || DEFAULT_QUERY_TIMEOUT,
            _on_connect_do => $args{on_connect_do} || [],
        },
        _cache             => $args{cache} || ($cache_ttl > 0 ? _build_default_cache($cache_ttl) : undef),
        _cache_ttl         => $cache_ttl,
        _enable_retry      => $args{enable_retry} // 0,
        _retry_config      => {
            _max_retries   => $args{max_retries} || DEFAULT_RETRIES,
            _delay         => $args{retry_delay} || 1,
            _factor        => 2,
        },
        _enable_metrics    => $args{enable_metrics} // 0,
        _is_connected      => 1,
        _worker_idx        => 0,
        _query_cache       => {},
        _stats             => {
            _queries       => 0,
            _errors        => 0,
            _cache_hits    => 0,
            _cache_misses  => 0,
            _deadlocks     => 0,
            _retries       => 0,
        },
        _debug             => $args{debug} || 0,
    };

    _init_metrics($async_db) if $async_db->{_enable_metrics};
    _init_workers($async_db);

    if (my $interval = $args{health_check} // HEALTH_CHECK_INTERVAL) {
        _start_health_checks($async_db, $interval);
    }

    return $async_db;
}

=head2 disconnect

Gracefully shuts down all background workers and clears timers. Always call this before your application exits.

    DBIx::Class::Async->disconnect($db);

=cut

sub disconnect {
    my ($db) = @_;

    return unless $db && ref $db eq 'HASH';

    # 1. Clear the health check timer
    if ($db->{_health_check_timer}) {
        $db->{_loop}->remove($db->{_health_check_timer});
        delete $db->{_health_check_timer};
    }

    # 2. Shutdown workers
    if ($db->{_workers}) {
        foreach my $worker_info (@{ $db->{_workers} }) {
            if (my $instance = $worker_info->{instance}) {
                $db->{_loop}->remove($instance);
            }
        }
        $db->{_workers} = [];
    }

    # 3. Final state update
    $db->{_is_connected} = 0;

    return 1;
}

#
#
# PRIVATE METHODS

sub _call_worker {
    my ($db, $operation, @args) = @_;

    warn "[PID $$] Bridge - sending '$operation' to worker." if ASYNC_TRACE;

    # ------------------------------------------------------------------
    # Derive result_class from the payload so it is available throughout
    # this method without changing the call signature at 13 call sites.
    #
    # Every call site passes a payload hashref as $args[0] containing a
    # source_name key.  We resolve that to a fully-qualified result class
    # via the schema, which is exactly what the Factory needs for its
    # relationship-detection logic.
    # ------------------------------------------------------------------
    my $result_class;
    if ( ref($args[0]) eq 'HASH' && $args[0]->{source_name} ) {
        $result_class = eval {
            $db->{_schema_class}->source( $args[0]->{source_name} )
                                ->result_class
        };
        # eval failure (unknown source, not yet loaded) leaves $result_class
        # undef -- both the pre-flight and the Factory handle undef gracefully.
    }

    # ------------------------------------------------------------------
    # Pre-flight: catch undef relationship keys before hitting the worker.
    # Returns a failed Future immediately so the caller's ->then/->catch
    # chain handles it the same way as any other async error.
    # ------------------------------------------------------------------
    if ( $result_class && ref($args[0]) eq 'HASH' ) {
        my $data_hashref = $args[0]->{data}          # create / populate
                        // $args[0]->{updates};      # update

        if ( ref($data_hashref) eq 'HASH' ) {
            my $exception = DBIx::Class::Async::Exception::Factory->validate_or_fail(
                args         => $data_hashref,
                schema       => $db->{_schema_class},
                result_class => $result_class,
                operation    => $operation,
            );
            return Future->fail($exception) if $exception;
        }
    }

    my $worker = _next_worker($db);

    my $worker_future = $worker->call(
        args => [
            $db->{_schema_class},
            $db->{_connect_info},
            $db->{_workers_config},
            $operation,
            @args,
            $db->{_debug} || 0,
        ],
    );

    # ------------------------------------------------------------------
    # Shared helper: translate any raw error (string, DBIC exception, or
    # already-typed exception) into a DBIx::Class::Async::Exception.
    # If the error is already one of ours, pass it through untouched.
    # ------------------------------------------------------------------
    my $make_exception = sub {
        my ($raw) = @_;
        return $raw
            if ref $raw && $raw->isa('DBIx::Class::Async::Exception');
        return DBIx::Class::Async::Exception::Factory->make_from_dbic_error(
            error        => $raw,
            schema       => $db->{_schema_class},
            result_class => $result_class,
            operation    => $operation,
        );
    };

    return $worker_future->followed_by(sub {
        my ($f) = @_;

        # ------------------------------------------------------------------
        # Worker future failed outright
        # ------------------------------------------------------------------
        if ( $f->is_failed ) {
            $db->{_stats}->{_errors}++;
            return Future->fail( $make_exception->( $f->failure ) );
        }

        my $result = ($f->get)[0];

        # ------------------------------------------------------------------
        # Result is itself a Future -- unwrap it
        # ------------------------------------------------------------------
        if ( Scalar::Util::blessed($result) && $result->isa('Future') ) {
            return $result->followed_by(sub {
                my ($inner_f) = @_;

                if ( $inner_f->is_failed ) {
                    $db->{_stats}->{_errors}++;
                    return Future->fail( $make_exception->( $inner_f->failure ) );
                }

                my $inner_result = ($inner_f->get)[0];

                if ( ref($inner_result) eq 'HASH' && exists $inner_result->{error} ) {
                    $db->{_stats}->{_errors}++;
                    return Future->fail( $make_exception->( $inner_result->{error} ) );
                }

                $db->{_stats}->{_queries}++
                    unless $operation =~ /^(?:ping|health_check|deploy)$/;
                return Future->done($inner_result);
            });
        }

        # ------------------------------------------------------------------
        # Non-Future result -- check for worker error hashref
        # ------------------------------------------------------------------
        if ( ref($result) eq 'HASH' && exists $result->{error} ) {
            $db->{_stats}->{_errors}++;
            return Future->fail( $make_exception->( $result->{error} ) );
        }

        $db->{_stats}->{_queries}++
            unless $operation =~ /^(?:ping|health_check|deploy)$/;
        return Future->done($result);
    });
}

sub _init_workers {
    my $db = shift;

    for my $worker_id (1..$db->{_workers_config}{_count}) {
        my $worker = IO::Async::Function->new(
            code => sub {
                use strict;
                use warnings;
                use feature 'state';


                my ($schema_class, $connect_info, $worker_config, $operation, $payload, $debug_flag) = @_;

                $debug_flag ||= 0;

                if (ASYNC_TRACE) {
                    warn "[PID $$] Worker CODE block started";
                    warn "[PID $$] Worker received " . scalar(@_) . " arguments";
                    warn "[PID $$] Schema class: $schema_class";
                    warn "[PID $$] Operation: $operation";
                    warn "[PID $$] Debug flag: $debug_flag";
                    warn "[PID $$] STAGE 4 (Worker): Received operation: $operation";
                }

                my $deflator;
                $deflator = sub {
                    my ($data) = @_;
                    return $data unless defined $data;

                    if ( eval { $data->isa('DBIx::Class::Row') } ) {
                        my %cols = $data->get_inflated_columns;
                        # Recurse for prefetched relations
                        foreach my $k (keys %cols) {
                            if (ref $cols{$k}) { $cols{$k} = $deflator->($cols{$k}) }
                        }
                        return \%cols;
                    }

                    if ( eval { $data->isa('DBIx::Class::ResultSet') } ) {
                        return [ map { $deflator->($_) } $data->all ];
                    }
                    if ( ref($data) eq 'ARRAY' ) {
                        return [ map { $deflator->($_) } @$data ];
                    }

                    return $data;
                };

                my $log_sql = sub {
                    my ($debug_enabled, $sql, $bind) = @_;
                    return unless $debug_enabled;

                    # Log to STDERR in the worker process
                    # The parent's debugobj won't be accessible in the worker
                    warn "SQL: $sql\n";
                    if ($bind && @$bind) {
                        warn "BIND: " . join(", ", map { defined $_ ? "'$_'" : "NULL" } @$bind) . "\n";
                    }
                };

                # Create or reuse schema connection
                state $schema_cache = {};
                my $pid = $$;

                warn "[PID $$] Checking schema cache for PID $pid" if ASYNC_TRACE;

                unless (exists $schema_cache->{$pid}) {
                    if (ASYNC_TRACE) {
                        warn "[PID $$] Worker initialising new schema connection";
                        warn "[PID $$] About to require $schema_class";
                    }


                    # Load schema class in worker process
                    my $require_result = eval "require $schema_class; 1";
                    if (!$require_result || $@) {
                        my $err = $@ || 'Unknown error';
                        warn "[PID $$] FAILED to load schema class: $err"
                            if ASYNC_TRACE;
                        die "Worker Load Fail: $err";
                    }

                    warn "[PID $$] Schema class loaded successfully"
                        if ASYNC_TRACE;

                    unless ($schema_class->can('connect')) {
                        warn "[PID $$] Schema class has no 'connect' method!"
                            if ASYNC_TRACE;
                        die "Schema class $schema_class does not provide 'connect' method";
                    }

                    warn "[PID $$] Attempting database connection..."
                        if ASYNC_TRACE;

                    # Connect to database
                    my $schema = eval { $schema_class->connect(@$connect_info); };
                    if ($@) {
                        warn "[PID $$] Database connection FAILED: $@"
                            if ASYNC_TRACE;
                        die "Failed to connect to database: $@";
                    }
                    unless (defined $schema) {
                        warn "[PID $$] Schema connection returned undef!"
                            if ASYNC_TRACE;
                        die "Schema connection returned undef";
                    }

                    if ($debug_flag && $schema->storage) {
                        $schema->storage->debug($debug_flag);
                        warn "[PID $$] Worker storage debug enabled at level $debug_flag"
                            if ASYNC_TRACE;
                    }

                    # https://github.com/manwar/DBIx-Class-Async/issues/9
                    #
                    # When the worker process exits, Perl tries to clean up
                    # the database handle. But the parent process also has a
                    # reference to what it thinks is the same handle (it's
                    # not, it's a fork). Without InactiveDestroy, both
                    # processes try to close the connection, causing:
                    #
                    # 1) Parent closes connection
                    # 2) Worker tries to close same connection -> SEGV
                    #    (trying to free already-freed memory)
                    #
                    # InactiveDestroy = 1 tells DBI: "This handle was
                    # inherited from a fork, don't close it when the child
                    # exits"

                    if ($schema->storage && $schema->storage->dbh) {
                        $schema->storage->dbh->{InactiveDestroy} = 1;
                        $schema->storage->dbh->{AutoInactiveDestroy} = 1;
                        warn "[PID $$] Set InactiveDestroy on worker database handle"
                            if ASYNC_TRACE;
                    }

                    warn "[PID $$] Database connected successfully"
                        if ASYNC_TRACE;

                    $schema_cache->{$pid} = $schema;

                    warn "[PID $$] Worker initialisation complete"
                        if ASYNC_TRACE;
                }

                warn "[PID $$] STAGE 5 (Worker): Executing operation: $operation"
                    if ASYNC_TRACE;

                my $result = try {
                    my $schema = $schema_cache->{$pid};

                    warn "[PID $$] Schema from cache: " . (defined $schema ? ref($schema) : "UNDEF")
                        if ASYNC_TRACE;

                    if ($operation =~ /^(count|sum|max|min|avg|average)$/) {
                        warn "[PID $$] STAGE 6 (Worker): Performing aggregate $operation"
                            if ASYNC_TRACE;

                        my $source_name = $payload->{source_name};
                        my $cond        = $payload->{cond}  // {};
                        my $attrs       = $payload->{attrs} // {};
                        my $column      = $payload->{column};

                        my $rs = $schema->resultset($source_name)->search($cond, $attrs);

                        # Use eval to catch DBIC errors (e.g., column doesn't exist)
                        my $val = eval {
                            if ($operation eq 'count') {
                                return $column ? $rs->get_column($column)->func('COUNT') : $rs->count;
                            }

                            if ($operation =~ /^(avg|average)$/) {
                                return $rs->get_column($column)->func('AVG');
                            }

                            return $rs->get_column($column)->$operation;
                        };

                        if ($@) {
                            warn "[PID $$] WORKER ERROR: $@" if ASYNC_TRACE;
                            return { error => $@ };
                        }
                        else {
                            # IMPORTANT: Force to scalar to avoid HASH(0x...) in Parent
                            # This stringifies potential Math::BigInt objects or references
                            warn "[PID $$] $operation complete: $val"
                                if ASYNC_TRACE;
                            return defined $val ? "$val" : undef;
                        }
                    }
                    elsif ($operation eq 'search' || $operation eq 'all') {
                        my $source_name = $payload->{source_name};
                        my $attrs       = $payload->{attrs} || {};

                        # Force collapse so DBIC merges the JOINed rows into nested objects
                        $attrs->{collapse} = 1 if $attrs->{prefetch};

                        my $rs = $schema->resultset($source_name)->search($payload->{cond}, $attrs);
                        my @rows = $rs->all;

                        # Use your proven old-design logic here
                        return [
                            map { _serialise_row_with_prefetch($_, $attrs->{prefetch}, {}) } @rows
                        ];
                    }
                    elsif ($operation eq 'update') {
                        my $source_name = $payload->{source_name};
                        my $cond        = $payload->{cond};
                        my $updates     = $payload->{updates};

                        if (!$updates || !keys %$updates) {
                            return 0;
                        }
                        else {
                            return $schema->resultset($source_name)
                                          ->search($cond)
                                          ->update($updates);
                        }
                    }
                    elsif ($operation eq 'create') {
                        my $source_name = $payload->{source_name};
                        my $data        = $payload->{data};

                        # Perform the actual DBIC insert
                        my $row = $schema->resultset($source_name)->create($data);

                        # Sync with DB to get the Auto-Increment ID
                        # Some DBD drivers need this to populate the primary key in the object
                        $row->discard_changes;

                        my %raw = $row->get_columns;
                        my %clean_data;
                        for my $key (keys %raw) {
                            # Force stringification/numification to strip any DBIC internal "magic"
                            $clean_data{$key} = defined $raw{$key} ? "$raw{$key}" : undef;
                        }
                        return \%clean_data;
                    }
                    elsif ($operation eq 'delete') {
                        my $source_name = $payload->{source_name};
                        my $cond        = $payload->{cond};

                        # Direct delete on the resultset matching the condition
                        return $schema->resultset($source_name)->search($cond)->delete + 0;
                    }
                    elsif ($operation =~ /^populate(?:_bulk)?$/) {
                        my $source_name = $payload->{source_name};
                        my $data        = $payload->{data};

                        my $val = eval {
                            my $rs = $schema->resultset($source_name);

                            if ($operation eq 'populate') {
                                # Standard populate can return objects.
                                # We inflate them to HashRefs to pass back.
                                my @rows = $rs->populate($data);
                                return [ map { _serialise_row_with_prefetch($_, undef, {}) } @rows ];
                            }
                            else {
                                # populate_bulk is for speed; typically returns a count or truthy
                                $rs->populate($data); # DBIC void context usually
                                return 1;
                            }
                        };

                        if ($@) {
                            warn "[PID $$] WORKER ERROR: $@" if ASYNC_TRACE;
                            return { error => "$@" };
                        }
                        else {
                            return $val;
                        }
                    }
                    elsif ($operation eq 'find') {
                        my $source_name = $payload->{source_name};
                        my $query       = $payload->{query};
                        my $attrs       = $payload->{attrs} || {};

                        my $row = $schema->resultset($source_name)->find($query, $attrs);

                        if ($row) {
                            return _serialise_row_with_prefetch($row, undef, $attrs);
                        }
                        else {
                            return;
                        }
                    }
                    elsif ($operation eq 'deploy') {
                        my ($sqlt_args, $dir) = (ref $payload eq 'ARRAY') ? @$payload : ($payload);
                        eval {
                            $schema->deploy($sqlt_args // {}, $dir);
                        };
                        if ($@) {
                            return { error => "Deploy operation failed: $@" };
                        }
                        else {
                            return { success => 1 };
                        }
                    }
                    elsif ($operation eq 'txn_batch') {
                        my $operations = $payload;

                        my $batch_result = eval {
                            $schema->txn_do(sub {
                                my $success_count = 0;
                                foreach my $op (@$operations) {
                                    my $type = $op->{type};
                                    my $rs_name = $op->{resultset};

                                    if ($type eq 'update') {
                                        my $row = $schema->resultset($rs_name)->find($op->{id});
                                        die "Record not found for update: $rs_name ID $op->{id}\n"
                                            unless $row;
                                        $row->update($op->{data});
                                        $success_count++;
                                    }
                                    elsif ($type eq 'create') {
                                        $schema->resultset($rs_name)->create($op->{data});
                                        $success_count++;
                                    }
                                    elsif ($type eq 'delete') {
                                        my $row = $schema->resultset($rs_name)->find($op->{id});
                                        die "Record not found for delete: $rs_name ID $op->{id}\n"
                                            unless $row;
                                        $row->delete;
                                        $success_count++;
                                    }
                                    elsif ($type eq 'raw') {
                                        $schema->storage->dbh->do($op->{sql}, undef, @{$op->{bind} || []});
                                        $success_count++;
                                    }
                                    else {
                                        die "Unknown operation type: $type\n";
                                    }
                                }
                                return { count => $success_count, success => 1 };
                            });
                        };

                        if ($@) {
                            return { error => "Batch Transaction Aborted: $@", success => 0 };
                        }
                        else {
                            return $batch_result;
                        }
                    }
                    elsif ($operation eq 'txn_do') {
                        my $steps = $payload;
                        my %register;

                        my $txn_result = eval {
                            $schema->txn_do(sub {
                                my @step_results;

                                foreach my $step (@$steps) {
                                    next unless $step && ref $step eq 'HASH'; # Skip empty/invalid steps
                                    next unless $step->{action};              # Skip steps with no action

                                    # 1. Resolve variables from previous steps
                                    # e.g., changing '$user_id' to the actual ID found in step 1
                                    _resolve_placeholders($step, \%register);

                                    # my $rs = $schema->resultset($step->{resultset});
                                    my $action = $step->{action};
                                    my $result_data;

                                    if ($action eq 'raw') {
                                        # Raw SQL bypasses the Resultset layer
                                        my $dbh = $schema->storage->dbh;
                                        $dbh->do($step->{sql}, undef, @{$step->{bind} || []});
                                        $result_data = { success => 1 };
                                    }
                                    else {
                                        # CRUD operations require a Resultset
                                        my $rs_name = $step->{resultset}
                                            or die "txn_do: action '$action' requires a 'resultset' parameter";
                                        my $rs = $schema->resultset($rs_name);

                                        if ($action eq 'create') {
                                            my $row = $rs->create($step->{data});
                                            $result_data = { id => $row->id, data => { $row->get_columns } };
                                        }
                                        elsif ($action eq 'find') {
                                            my $row = $rs->find($step->{id});
                                            die "txn_do: record not found" unless $row;
                                            $result_data = { id => $row->id, data => { $row->get_columns } };
                                        }
                                        elsif ($action eq 'update') {
                                            my $row = $rs->find($step->{id});
                                            die "txn_do: record not found for update" unless $row;
                                            $row->update($step->{data});
                                            $result_data = { success => 1, id => $row->id };
                                        }
                                    }

                                    if ($step->{name} && $result_data->{id}) {
                                        $register{ '$' . $step->{name} . '.id' } = $result_data->{id};
                                    }
                                    push @step_results, $result_data;
                                }
                                return { results => \@step_results, success => 1 };
                            });
                        };

                        return $@ ? { error => "Transaction failed: $@", success => 0 }
                                  : $txn_result;
                    }
                    elsif ($operation eq 'txn_begin') {
                        $schema->storage->txn_begin;
                        return { success => 1 };
                    }
                    elsif ($operation eq 'txn_commit') {
                        $schema->storage->txn_commit;
                        return { success => 1 };
                    }
                    elsif ($operation eq 'txn_rollback') {
                        $schema->storage->txn_rollback;
                        return { success => 1 };
                    }
                    elsif ($operation eq 'ping') {
                        my $alive = eval { $schema->storage->dbh->do("SELECT 1") };
                        return { success => ($alive ? 1 : 0), status => "pong" };
                    }
                    else {
                        die "Unknown operation: $operation";
                    }
                }
                catch {
                    warn "[PID $$] Worker execution error: $_"
                        if ASYNC_TRACE;
                    return { error => "$_", success => 0 };
                };

                my $safe_result = $deflator->($result);
                if (ASYNC_TRACE) {
                    warn "[PID $$] Worker returning result type: " . ref($safe_result);
                    warn "[PID $$] Worker returning: $safe_result";
                }
                return $safe_result;
            },
            max_workers => 1,
        );

        $db->{_loop}->add($worker);

        push @{$db->{_workers}}, {
            instance => $worker,
            healthy  => 1,
            pid      => undef,
        };
    }
}

sub _init_metrics {
    my $db = shift;

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
        $db->{_enable_metrics} = 0;
        undef $METRICS;
    }
}

sub _next_worker {
    my ($db) = @_;

    return unless $db->{_workers} && @{$db->{_workers}};

    $db->{_worker_idx} //= 0;

    die "No workers available" unless $db->{_workers} && @{$db->{_workers}};

    my $idx    = $db->{_worker_idx};
    my $worker = $db->{_workers}[$idx];

    $db->{_worker_idx} = ($idx + 1) % @{$db->{_workers}};

    return $worker->{instance};
}

sub _start_health_checks {
    my ($db, $interval) = @_;

    return if $interval <= 0;

    # Try to create the timer
    eval {
        require IO::Async::Timer::Periodic;

        my $timer = IO::Async::Timer::Periodic->new(
            interval => $interval,
            on_tick  => sub {
                # Don't use async here - just fire and forget
                _health_check($db)->retain;
            },
        );

        $db->{_loop}->add($timer);
        $timer->start;

        $db->{_health_check_timer} = $timer;
    };

    if ($@) {
        # If repeat fails, try a different approach or disable health checks
        warn "Failed to start health checks: $@" if ASYNC_TRACE;
    }
}

sub _health_check {
    my $db = shift;

    my @checks = map {
        my $worker_info = $_;
        my $worker = $worker_info->{instance};
        $worker->call(
            args => [
                $db->{_schema_class},
                $db->{_connect_info},
                $db->{_workers_config},
                'health_check',
            ],
            timeout => 5,
        )->then(
        sub {
            $worker_info->{healthy} = 1;
            return Future->done(1);
        },
        sub {
            $worker_info->{healthy} = 0;
            return Future->done(0);
        })
    } @{$db->{_workers}};

    return Future->wait_all(@checks)->then(sub {
        my @results = @_;
        my $healthy_count = grep { $_->get } @results;

        _record_metric($db, 'set', 'db_async_workers_active', $healthy_count);

        return Future->done($healthy_count);
    });
}

sub _record_metric {
    my ($db, $type, $name, @args) = @_;

    return unless $db->{_enable_metrics} && defined $METRICS;

    if ($type eq 'inc') {
        $METRICS->inc($name, @args);
    }
    elsif ($type eq 'observe') {
        $METRICS->observe($name, @args);
    }
    elsif ($type eq 'set') {
        $METRICS->set($name, @args);
    }
}

sub _resolve_placeholders {
    my ($item, $reg) = @_;
    return unless defined $item;

    if (ref $item eq 'HASH') {
        for my $key (keys %$item) {
            if (ref $item->{$key}) {
                # Dive deeper into nested structures
                _resolve_placeholders($item->{$key}, $reg);
            }
            elsif (defined $item->{$key} && exists $reg->{$item->{$key}}) {
                # Exact match: Swap '$user.id' for 42
                $item->{$key} = $reg->{$item->{$key}};
            }
            elsif (defined $item->{$key} && !ref $item->{$key}) {
                # String interpolation: Handle "ID is $user.id"
                $item->{$key} = _interpolate_string($item->{$key}, $reg);
            }
        }
    }
    elsif (ref $item eq 'ARRAY') {
        for my $i (0 .. $#$item) {
            if (ref $item->[$i]) {
                _resolve_placeholders($item->[$i], $reg);
            }
            elsif (defined $item->[$i] && exists $reg->{$item->[$i]}) {
                $item->[$i] = $reg->{$item->[$i]};
            }
        }
    }
}

sub _interpolate_string {
    my ($string, $reg) = @_;
    return $string unless $string =~ /\$/;

    # Use a regex to find all keys in the register and replace them
    # Example: "INSERT INTO logs VALUES ('Created user $user.id')"
    foreach my $key (keys %$reg) {
        my $val = $reg->{$key};
        # Escape the key for regex safety (since it contains $)
        my $quoted_key = quotemeta($key);
        $string =~ s/$quoted_key/$val/g;
    }
    return $string;
}

sub _build_default_cache {
    my ($ttl) = @_;

    # If ttl is 0 or undef, we might not want to initialise the cache driver
    # depending on how CHI handles undef (never expire) vs 0 (expire immediately)
    return undef if !defined $ttl || $ttl == 0;

    my %params = (
        driver => 'Memory',
        global => 1,
    );

    # Add expires_in only if ttl is defined (undef means never expire in CHI)
    $params{expires_in} = $ttl if defined $ttl;

    return CHI->new(%params);
}

sub _normalise_prefetch {
    my $pref = shift;

    return {} unless $pref;
    return { $pref => undef } unless ref $pref;

    if (ref $pref eq 'ARRAY') {
        return { map { %{ _normalise_prefetch($_) } } @$pref };
    }

    if (ref $pref eq 'HASH') {
        return $pref; # Already a spec
    }

    return {};
}

sub _serialise_row_with_prefetch {
    my ($row, $prefetch) = @_;
    return unless $row;

    # 1. If it's a plain HASH (from HashRefInflator),
    # just return it. DBIC already structured it for us.
    return $row if ref($row) eq 'HASH';

    # 2. If it's an object, we proceed with manual extraction
    my %data = $row->get_columns;

    if ($prefetch) {
        my $spec = _normalise_prefetch($prefetch);
        foreach my $rel (keys %$spec) {
            # Only call methods if we have a blessed object
            if (blessed($row) && $row->can($rel)) {
                my $related = eval { $row->$rel };
                next if $@ || !defined $related;

                if (blessed($related)
                    && $related->isa('DBIx::Class::ResultSet')) {
                    $data{$rel} = [
                        map {
                            _serialise_row_with_prefetch($_, $spec->{$rel})
                        } $related->all
                    ];
                }
                else {
                    $data{$rel} = _serialise_row_with_prefetch($related, $spec->{$rel});
                }
            }
        }
    }
    return \%data;
}

=head1 EVENT LOOP INTEGRATION

B<LOOP AGNOSTICISM>

C<DBIx::Class::Async> is built atop L<IO::Async>, but it is designed to be
loop-agnostic. It does not force you to use a specific event loop engine.
This is critical for applications already running within an established
ecosystem like L<Mojolicious>, L<AnyEvent>, etc.

The bridge follows a B<"Smart Default"> pattern:

=over 4

=item * Implicit

If no loop is provided, it automatically detects your OS and instantiates
the best available L<IO::Async::Loop> (e.g., B<Epoll>, B<KQueue>, or B<Poll>).

=item * Explicit

If you provide a loop object via the B<loop> attribute, the bridge B<"slaves">
itself to that engine.

=back

B<UNDER THE HOOD>

When an external loop is provided, L<DBIx::Class::Async> performs the following
steps:

=over 4

=item * Process Delegation

The library initialises a pool of persistent background workers. These are
separate processes that hold their own database handles to prevent blocking
the main event loop.

=item * Pipe Multiplexing

Communication between your application and the workers happens via asynchronous
pipes. Your event loop (Mojo, Poll, etc.) watches these pipes for "Read Ready"
signals.

=item * Heartbeat Sharing

All internal timers (Health Checks, TTL Caching) are registered as Notifiers
within the parent loop’s reactor, ensuring they only fire when the loop
is "ticking".

=item * Non-Blocking Flow

Because the database I/O happens in a separate memory space, a 10-second
query will not increase the "latency" or "lag" of your web server's main loop.

=back

B<EXAMPLE: MOJOLICIOUS INTEGRATION>

To use this library inside a B<Mojolicious> application, use the L<IO::Async::Loop::Mojo>
bridge. This allows your database workers to share the same reactor as your
web server, preventing I/O starvation.

    use Mojolicious::Lite;
    use DBIx::Class::Async::Schema;
    use IO::Async::Loop::Mojo;

    # 1. Create a bridge between IO::Async and Mojo
    my $loop = IO::Async::Loop::Mojo->new;

    # 2. Connect your schema using the Mojo-backed loop
    helper db => sub {
        state $schema = DBIx::Class::Async::Schema->connect(
            $dsn, $user, $pass, \%dbic_attrs,
            {
                schema_class => 'My::App::Schema',
                workers      => 4,
                loop         => $loop,  # The Magic Connection
            }
        );
    };

    # 3. Use non-blocking DBIC in your routes
    get '/stats' => sub {
        my $c = shift;

        $c->db->resultset('User')
              ->search({ active => 1 })
              ->all
              ->on_done(sub {
                my @users = @_;
                $c->render(json => { count => scalar @users });
              });
    };

    app->start;

=head1 PERFORMANCE TIPS

=over 4

=item * Worker Count & CPU Affinity

Adjust the C<workers> parameter based on your database connection limits and expected concurrency. Since each worker is a separate process, 2-4 workers per CPU core is the sweet spot. Too many workers can cause context-switching overhead on your OS.

=item * Caching Strategy

The new design uses C<CHI> for memory-efficient caching. For read-heavy workloads, ensure C<cache_ttl> is set. Setting it to C<0> will disable caching, which is useful for data that changes every second.

=item * Batch Operations (Concurrent Execution)

Instead of sequential C<await> calls, which force workers to sit idle, use C<Future->wait_all> or C<Future->needs_all> to fire multiple queries across your worker pool simultaneously.

=item * Connection Persistence

Each worker maintains a persistent connection to the database. This eliminates the "connection tax" (handshake time) for every query. Monitor your database's C<max_connections> setting to ensure it can handle C<Total Apps * Workers Per App>.

=item * Timeout Guardrails

The C<query_timeout> (default 30s) is your safety net. In the new design, a hung query only blocks B<one> worker; the others stay active. Without a timeout, a single "zombie" query could permanently reduce your pool size.

=back

=head1 SQL GENERATION CONSISTENCY

L<DBIx::Class::Async> ensures deterministic SQL generation across multiple
invocations of the same query. This is critical for query caching, performance
analysis, and debugging.

B<Deterministic Column Ordering>

When you call C<search()> multiple times on the same ResultSet, the generated
SQL will be identical, including column order:

    my $rs = $schema->resultset('User');

    # These produce identical SQL every time
    my $query1 = $rs->search({})->as_query;
    my $query2 = $rs->search({})->as_query;

    # SELECT me.id, me.name, me.email, ... FROM users me
    # (same order on every call)

This consistency is maintained even with complex attribute merging:

    my $rs = $schema->resultset('User')
                    ->search({}, { join => 'orders' })
                    ->search({}, { join => 'profile' });

    # Joins are deduplicated and ordered consistently

B<Attribute Deduplication>

When chaining C<search()> calls, accumulating attributes (C<join>, C<prefetch>,
C<columns>, C<select>, C<as>, C<order_by>, C<group_by>, C<having>) are
automatically deduplicated:

    my $rs = $schema->resultset('User')
                    ->search({}, { join => 'orders' })
                    ->search({}, { join => 'orders' })  # Deduplicated
                    ->search({}, { join => 'profile' });

    # Results in: JOIN orders, JOIN profile (not duplicate orders)

Deduplication uses a stable serialisation of nested structures, so these
are correctly recognised as duplicates:

    { orders => 'items' }  # Same as:
    { orders => 'items' }  # This duplicate

B<Benefits>

=over 4

=item * B<Query Caching> - Identical SQL enables effective query caching

=item * B<Performance Analysis> - Consistent SQL makes it easier to identify
slow queries in logs

=item * B<Testing> - Predictable SQL generation makes testing more reliable

=item * B<Debugging> - Easier to trace and compare queries

=back

B<Debugging SQL>

You can inspect generated SQL using the C<as_query> method or by enabling
debug mode:

    # Using as_query
    my $rs = $schema->resultset('User')->search({ active => 1 });
    my $query = $rs->as_query;
    # Extract SQL from the returned structure

    # Using debug mode
    $schema->storage->debug(1);
    $rs->all;  # SQL printed to STDERR in worker processes

See L<debugobj|DBIx::Class::Async::Storage::DBI/debugobj> and
L<debug|DBIx::Class::Async::Storage::DBI/debug> for more information on SQL
debugging.

=head1 ERROR HANDLING

The bridge uses C<< Future->fail >> to propagate errors from the workers back to your main process. You should handle these using C<await> within a C<try/catch> block or the C<< ->catch >> method.

=over 4

=item * Worker Connectivity

If a worker cannot connect to the DB, it will throw an exception during the first query or a health check.

=item * Automatic Retries

If C<enable_retry> is true, the bridge will automatically retry queries that fail due to transient issues (like database deadlocks) using an exponential backoff (starting at 1s, doubling each time).

=item * Serialisation Failures

Because data must travel between processes, any custom objects in your ResultSets must be serialiisable. The new design handles most DBIC inflation automatically, but be wary of passing "live" filehandles or sockets.

=back

=head1 METRICS

If C<< enable_metrics => 1 >> is passed to the constructor and L<Metrics::Any> is available, the following gauges and counters are tracked:

    +------------------------------------+-----------+-----------------------------------------------------+
    | Metric                             | Type      | Description                                         |
    +------------------------------------+-----------+-----------------------------------------------------+
    | C<db_async_queries_total>          | Counter   | Total number of operations sent to workers.         |
    | C<db_async_cache_hits_total>       | Counter   | Queries resolved via the internal C<CHI> cache.     |
    | C<db_async_query_duration_seconds> | Histogram | Latency distribution of database operations.        |
    | C<db_async_workers_active>         | Gauge     | Number of workers passing the periodic health check.|
    +------------------------------------+-----------+-----------------------------------------------------+

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
