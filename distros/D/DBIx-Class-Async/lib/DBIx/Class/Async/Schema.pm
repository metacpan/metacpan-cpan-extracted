package DBIx::Class::Async::Schema;

$DBIx::Class::Async::Schema::VERSION   = '0.64';
$DBIx::Class::Async::Schema::AUTHORITY = 'cpan:MANWAR';

=encoding utf8

=head1 NAME

DBIx::Class::Async::Schema - Non-blocking, worker-pool based Proxy for DBIx::Class::Schema

=head1 VERSION

Version 0.64

=head1 SYNOPSIS

    use IO::Async::Loop;
    use DBIx::Class::Async::Schema;

    my $loop = IO::Async::Loop->new;

    # Connect returns a proxy object immediately
    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=myapp.db", undef, undef, {},
        {
            schema_class   => 'MyApp::Schema',
            workers        => 4,
            enable_metrics => 1,
            loop           => $loop,
        }
    );

    # Use the 'await' helper for one-off scripts
    my $count = $schema->await( $schema->resultset('User')->count_future );

    # Or use standard Future chaining for web/event apps
    $schema->resultset('User')->find_future(1)->then(sub {
        my $user = shift;
        print "Found async user: " . $user->name;
    })->retain;

=head1 DESCRIPTION

C<DBIx::Class::Async::Schema> acts as a non-blocking bridge to your standard
L<DBIx::Class> schemas. Instead of executing queries in the main event loop
(which would block your UI or web server), this module offloads queries to a
managed pool of background worker processes.

=cut

use strict;
use warnings;
use utf8;

use Carp;
use Future;
use Try::Tiny;
use Scalar::Util 'blessed';
use DBIx::Class::Async;
use DBIx::Class::Async::Storage;
use DBIx::Class::Async::ResultSet;
use DBIx::Class::Async::Storage::DBI;
use Data::Dumper;

our $METRICS;
use constant ASYNC_TRACE => $ENV{ASYNC_TRACE} || 0;

=head1 METHODS

=head2 connect

    my $schema = DBIx::Class::Async::Schema->connect($dsn, $user, $pass, $dbi_attrs, \%async_attrs);

Initialises the worker pool and returns a proxy schema instance.

=over 4

=item * C<schema_class> (Required): The name of your existing DBIC Schema class.

=item * C<workers>: Number of background processes (Default: 2).

=item * C<loop>: An L<IO::Async::Loop> instance. If not provided, one will be created.

=item * C<enable_retry>: Automatically retry deadlocks/transient errors.

=back

=cut

sub connect {
    my ($class, @args) = @_;

    # Separate async options from connect_info
    my $async_options = {};
    if (ref $args[-1] eq 'HASH' && !exists $args[-1]->{RaiseError}) {
        $async_options = pop @args;
    }

    my $schema_class = $async_options->{schema_class}
       or croak "schema_class is required in async options";

    my $schema_loaded = 0;
    if (eval { $schema_class->can('connect') }) {
        $schema_loaded = 1;
    }
    elsif (eval "require $schema_class") {
        $schema_loaded = 1;
    }
    elsif (eval "package main; \$${schema_class}::VERSION ||= '0.01'; 1") {
        $schema_loaded = 1;
    }

    unless ($schema_loaded) {
        croak "Cannot load schema class $schema_class: $@";
    }

    $async_options->{cache_ttl} //= 0;  # Caching is OFF by default.

    my $async_db = eval {
        DBIx::Class::Async->create_async_db(
            schema_class => $schema_class,
            connect_info => \@args,
            %$async_options,
        );
    };

    if ($@) {
        croak "Failed to create async engine: $@";
    }

    my $native_schema = $schema_class->connect(@args);

    my $self = bless {
        _async_db      => $async_db,
        _native_schema => $native_schema,
        _sources_cache => {},
    }, $class;

    # Populate the inflator map
    $async_db->{_custom_inflators} = $self->_build_inflator_map($native_schema);

    # Store the datetime formatter once at connect time.
    # _inflate_row uses this to re-inflate datetime columns that
    # InflateColumn::DateTime handles in the worker but sends back
    # as raw strings to the parent.
    my $dsn = ref($args[0]) eq 'ARRAY' ? $args[0][0] : $args[0] // '';
    my $formatter;
    if ($dsn =~ /dbi:Pg/i) {
        eval { require DateTime::Format::Pg;
               $formatter = DateTime::Format::Pg->new };
    }
    elsif ($dsn =~ /dbi:mysql/i) {
        eval { require DateTime::Format::MySQL;
               $formatter = DateTime::Format::MySQL->new };
    }
    elsif ($dsn =~ /dbi:SQLite/i) {
        eval { require DateTime::Format::SQLite;
               $formatter = DateTime::Format::SQLite->new };
    }
    $async_db->{_datetime_formatter} = $formatter if $formatter;

    my $storage = DBIx::Class::Async::Storage::DBI->new(
        schema   => $self,
        async_db => $async_db,
    );

    $self->{_storage} = $storage;

    return $self;
}

sub await {
    my ($self, $future) = @_;

    my $loop = $self->{_async_db}->{_loop};
    my @results = $loop->await($future);

    # Unwrap nested Futures
    while (@results == 1
           && defined $results[0]
           && Scalar::Util::blessed($results[0])
           && $results[0]->isa('Future')) {

        if (!$results[0]->is_ready) {
            @results = $loop->await($results[0]);
        } elsif ($results[0]->is_failed) {
            my ($error) = $results[0]->failure;
            die $error;
        } else {
            @results = $results[0]->get;
        }
    }

    return wantarray ? @results : $results[0];
}

sub await_all {
    my ($self, @futures) = @_;

    my $combined = Future->needs_all(@futures);
    return $self->await($combined);
}

sub run_parallel {
    my ($self, @tasks) = @_;
    my @futures = map { $_->($self) } @tasks;
    return Future->needs_all(@futures);
}

# Cache specific
sub cache_hits    { shift->{_async_db}->{_stats}->{_cache_hits}   // 0 }
sub cache_misses  { shift->{_async_db}->{_stats}->{_cache_misses} // 0 }
sub cache_retries { shift->{_async_db}->{_stats}->{_retries}      // 0 }

# Execution specific
sub total_queries { shift->{_async_db}->{_stats}->{_queries}      // 0 }
sub error_count   { shift->{_async_db}->{_stats}->{_errors}       // 0 }
sub deadlock_count{ shift->{_async_db}->{_stats}->{_deadlocks}    // 0 }


sub class {
    my ($self, $source_name) = @_;

    croak("source_name required") unless defined $source_name;

    # Fetch metadata (this uses your existing _sources_cache)
    my $source = eval { $self->source($source_name) };

    if ($@ || !$source) {
        croak("No such source '$source_name'");
    }

    return $source->{result_class};
}

sub clone {
    my ($self, %args) = @_;

    # 1. Determine worker count
    my $orig_db = $self->{_async_db};
    my $worker_count = $args{workers}
        || ($orig_db
            && $orig_db->{_workers_config}
            && $orig_db->{_workers_config}{_count})
        || 2;

    # 2. Re-create the async engine
    my $new_async_db;
    if ($orig_db) {
        $new_async_db = DBIx::Class::Async->create_async_db(
            schema_class   => $orig_db->{_schema_class},
            connect_info   => $orig_db->{_connect_info},
            workers        => $worker_count,
            loop           => $orig_db->{_loop},
            enable_metrics => $orig_db->{_enable_metrics},
            enable_retry   => $orig_db->{_enable_retry},
        );
    }

    # 3. Build the new schema object (strictly internal keys)
    my $new_self = bless {
        %$self,
        _async_db      => $new_async_db,
        _sources_cache => {},
    }, ref $self;

    # 4. Re-attach storage
    if ($new_async_db) {
        $new_self->{_storage} = DBIx::Class::Async::Storage::DBI->new(
            schema   => $new_self,
            async_db => $new_async_db,
        );
    }

    return $new_self;
}

sub deploy {
    my ($self, $sqlt_args, $dir) = @_;

    my $async_db = $self->{_async_db};

    return DBIx::Class::Async::_call_worker(
        $async_db, 'deploy', [ $sqlt_args, $dir ],
    )->then(sub {
        my ($res) = @_;

        # Return the result (usually { success => 1 } or similar)
        # or return $self if you want to allow chaining.
        return $res;
    });
}

sub disconnect {
    my $self = shift;

    if (ref $self->{_async_db} eq 'HASH') {
        # 1. Properly stop every worker in the array
        if (my $workers = $self->{_async_db}->{_workers}) {
            for my $worker (@$workers) {
                if (blessed($worker) && $worker->can('stop')) {
                    eval { $worker->stop };
                }
            }
        }

        # 2. Clear the internal hash contents to break any circular refs
        %{$self->{_async_db}} = ();
    }

    # 3. Remove the manager entirely
    delete $self->{_async_db};

    # 4. Flush the metadata cache
    $self->{_sources_cache} = {};

    return $self;
}

sub health_check {
    my ($self) = @_;

    my $async_db = $self->{_async_db};

    my @futures;
    for (1 .. $async_db->{_workers_config}->{_count}) {
        push @futures, DBIx::Class::Async::_call_worker($async_db, 'ping', {});
    }

    return Future->wait_all(@futures)->then(sub {
        my @res_futures = @_;

        # Count how many actually returned a successful ping
        my $healthy_count = grep {
            $_->is_done && !$_->failure && ($_->get->{success} // 0)
        } @res_futures;

        # Record the metric
        $self->_record_metric('set', 'db_async_workers_active', $healthy_count);

        return Future->done($healthy_count);
    });
}

sub inflate_column {
    my ($self, $source_name, $column, $handlers) = @_;

    my $schema = $self->{_native_schema};

    my @known_sources = $schema->sources;
    warn "[PID $$] Parent Schema class: " . ref($schema) if ASYNC_TRACE;

    # Attempt lookup
    my $source = eval { $schema->source($source_name) };

    if (!$source) {
        warn "[PID $$] Source '$source_name' not found. Attempting force-load via resultset..."
            if ASYNC_TRACE;
        eval { $schema->resultset($source_name) };
        $source = eval { $schema->source($source_name) };
    }

    croak "Could not find result source for '$source_name' in Parent process."
        unless $source;

    # Apply the handlers to the Parent's schema instance
    my $col_info = $source->column_info($column);
    $source->add_column($column => {
        %$col_info,
        inflate => $handlers->{inflate},
        deflate => $handlers->{deflate},
    });

    # Registry for Parent-side inflation of results coming back from Worker
    $self->{_async_db}{_custom_inflators}{$source_name}{$column} = $handlers;
}

sub loop          { shift->{_async_db}->{_loop}  }
sub stats         { shift->{_async_db}->{_stats} }
sub native_schema { shift->{_native_schema}      }

sub populate {
    my ($self, $source_name, $data) = @_;

    # 1. Standard Guard Clauses
    croak("Schema is disconnected")   unless $self->{_async_db};
    croak("source_name required")     unless defined $source_name;
    croak("data required")            unless defined $data;
    croak("data must be an arrayref") unless ref $data eq 'ARRAY';
    croak("data cannot be empty")     unless scalar @$data;

    # 2. Delegate to ResultSet
    # This creates the RS and immediately triggers the bulk insert logic
    return $self->resultset($source_name)->populate($data);
}

sub register_class {
    my ($self, $source_name, $result_class) = @_;

    croak("source_name and result_class required")
        unless $source_name && $result_class;

    # 1. Load the class in the Parent process
    # We do this to extract metadata (columns, relationships)
    unless ($result_class->can('result_source_instance')) {
        eval "require $result_class";
        if ($@) {
            croak("Failed to load Result class '$result_class': $@");
        }
    }

    # 2. Get the ResultSource instance from the class
    # This contains the column definitions and table name
    my $source = eval { $result_class->result_source_instance };
    if ($@ || !$source) {
        croak("Class '$result_class' does not appear to be a valid DBIx::Class Result class");
    }

    # 3. Register the source
    # This will populate your { _sources_cache } or internal metadata map
    return $self->register_source($source_name, $source);
}

sub register_source {
    my ($self, $source_name, $source) = @_;

    # 1. Update Parent Instance
    $self->{_sources_cache}->{$source_name} = $source;

    # 2. Track this for Workers
    # Store the 'source' metadata so we can send it to workers if needed
    $self->{_dynamic_sources}->{$source_name} = $source;

    # 3. Class-level registration (for future local instances)
    my $schema_class = $self->{_schema_class};
    $schema_class->register_source($source_name, $source) if $schema_class;

    return $source;
}

=head2 resultset

    my $rs = $schema->resultset('Source');

Returns a L<DBIx::Class::Async::ResultSet> object. This RS behaves like
standard DBIC but provides C<*_future> variants (e.g., C<all_future>,
C<count_future>).

=cut

sub resultset {
    my ($self, $source_name) = @_;

    unless (defined $source_name && length $source_name) {
        croak("resultset() requires a source name");
    }

    # 1. Check our cache for the source metadata
    # (In DBIC, a 'source' contains column info, class names, etc.)
    my $source = $self->{_sources_cache}{$source_name};

    unless ($source) {
        # Fetch metadata from the real DBIx::Class::Schema class
        $source = $self->_resolve_source($source_name);
        $self->{_sources_cache}{$source_name} = $source;
    }

    my $result_class = $self->class($source_name);
    # 2. Create the new Async ResultSet
    return DBIx::Class::Async::ResultSet->new(
        source_name     => $source_name,
        schema_instance => $self,              # Access to _record_metric
        async_db        => $self->{_async_db}, # Access to _call_worker
        result_class    => $result_class,
    );
}

sub search_with_prefetch {
    my ($self, $source_name, $cond, $prefetch, $attrs) = @_;

    $attrs ||= {};
    my %merged_attrs = ( %$attrs, prefetch => $prefetch, collapse => 1 );

    return $self->resultset($source_name)
                ->search($cond, \%merged_attrs)
                ->all_future
                ->then(sub { my ($rows) = @_; return $rows; });
}

sub set_default_context {
    my $self = shift;

    # No-op for compatibility with external libraries
    # that expect a standard DBIC Schema interface.
    # In an Async world, we avoid global context to prevent
    # cross-talk between event loop cycles.

    return $self;
}

sub schema_version {
    my $self  = shift;
    my $class = $self->{_async_db}->{_schema_class};

    unless ($class) {
        croak("schema_class is not defined in " . ref($self));
    }

    return $class->schema_version if $class->can('schema_version');

    return undef;
}

sub sync_metadata {
    my ($self) = @_;

    my $async_db = $self->{_async_db};
    my @futures;

    # Ping every worker in the pool
    for (1 .. $async_db->{_workers_config}->{_count}) {
        push @futures, DBIx::Class::Async::_call_worker($async_db, 'ping', {});
    }

    return Future->wait_all(@futures);
}

sub schema_class { shift->{_async_db}->{_schema_class}; }

sub source_ {
    my ($self, $source_name) = @_;

    unless (exists $self->{_sources_cache}{$source_name}) {
        my $source = eval { $self->{_native_schema}->source($source_name) };

        croak("No such source '$source_name'") if $@ || !$source;

        $self->{_sources_cache}{$source_name} = $source;
    }

    return $self->{_sources_cache}{$source_name};
}

sub sources_ { shift->{_native_schema}->sources; }

sub storage  { shift->{_storage}; }

sub source {
    my ($self, $source_name) = @_;

    # 1. Retrieve the cached entry
    my $cached = $self->{_sources_cache}{$source_name};

    # 2. Check if we need to (re)fetch:
    #    Either we have no entry, or it's a raw HASH (autovivification artifact)
    if (!$cached || !blessed($cached)) {

        # Clean up any "ghost" hash before re-fetching
        delete $self->{_sources_cache}{$source_name};

        # 3. Use the persistent provider to keep ResultSource objects alive
        $self->{_metadata_provider} ||= do {
            my $class = $self->{_async_db}->{_schema_class};
            eval "require $class" or die "Could not load schema class $class: $@";
            $class->connect(@{$self->{_async_db}->{_connect_info}});
        };

        # 4. Fetch the source and validate its blessing
        my $source_obj = eval { $self->{_metadata_provider}->source($source_name) };

        if (blessed($source_obj)) {
            $self->{_sources_cache}{$source_name} = $source_obj;
        } else {
            return undef;
        }
    }

    return $self->{_sources_cache}{$source_name};
}

sub sources {
    my $self = shift;

    my $schema_class = $self->{_async_db}->{_schema_class};
    my $connect_info = $self->{_async_db}->{_connect_info};
    my $temp_schema = $schema_class->connect(@{$connect_info});
    my @sources = $temp_schema->sources;

    $temp_schema->storage->disconnect;

    return @sources;
}

sub txn_begin {
    my $self = shift;

    # We return the future so the caller can wait for the 'BEGIN' to finish
    return DBIx::Class::Async::_call_worker(
        $self->{_async_db},
        'txn_begin',
        {}
    );
}

sub txn_commit {
    my $self = shift;

    return DBIx::Class::Async::_call_worker(
        $self->{_async_db},
        'txn_commit',
        {}
    );
}

sub txn_rollback {
    my $self = shift;

    return DBIx::Class::Async::_call_worker(
        $self->{_async_db},
        'txn_rollback',
        {}
    );
}

sub txn_do {
    my ($self, $steps) = @_;

    croak "txn_do requires an ARRAYREF of steps"
        unless ref $steps eq 'ARRAY';

    return DBIx::Class::Async::_call_worker(
        $self->{_async_db},
        'txn_do',
        $steps
    )->then(sub {
        my ($result) = @_;
        return Future->fail($result->{error}) if ref $result eq 'HASH' && $result->{error};
        return Future->done($result);
    });
}

sub txn_batch {
    my ($self, @args) = @_;

    croak "Async database handle not initialised in schema."
        unless $self->{_async_db};

    # Allow both txn_batch([$h1, $h2]) and txn_batch($h1, $h2)
    my @operations = (ref $args[0] eq 'ARRAY') ? @{$args[0]} : @args;

    # 1. Parent-side Validation
    for my $op (@operations) {
        croak "Each operation must be a hashref with 'type' key"
            unless (ref $op eq 'HASH' && $op->{type});

        if ($op->{type} =~ /^(update|delete|create)$/) {
            croak "Operation type '$op->{type}' requires 'resultset' parameter"
                unless $op->{resultset};
        }
    }

    # 2. Direct call to the worker
    return DBIx::Class::Async::_call_worker(
        $self->{_async_db},
        'txn_batch',
        \@operations
    )->then(sub {
        my ($result) = @_;

        # Ensure we handle the result correctly
        if (ref $result eq 'HASH' && $result->{error}) {
            return Future->fail($result->{error});
        }

        return Future->done($result);
    });
}

sub unregister_source {
    my ($self, $source_name) = @_;

    croak("source_name is required") unless defined $source_name;

    # 1. Reach into the manager hashref (the "Async DB" manager)
    my $class = $self->{_async_db}->{_schema_class};
    unless ($class) {
        croak("schema_class is not defined in manager for " . ref($self));
    }

    # 2. Local Cache Cleanup
    # Even if the file stays on disk, we prevent the Parent from
    # attempting to generate new ResultSets for this source.
    delete $self->{_sources_cache}->{$source_name};

    # 3. Class-Level Cleanup
    # This prevents any future workers (or re-initialisations)
    # from seeing this source definition.
    if ($class->can('unregister_source')) {
        $class->unregister_source($source_name);
    }

    return $self;
}

sub AUTOLOAD {
    my $self = shift;

    return unless ref $self;

    our $AUTOLOAD;
    my ($method) = $AUTOLOAD =~ /([^:]+)$/;

    return if $method eq 'DESTROY';

    if ($self->{_async_db} && exists $self->{_async_db}->{schema}) {
        my $real_schema = $self->{_async_db}->{schema};
        if ($real_schema->can($method)) {
            return $real_schema->$method(@_);
        }
    }

    croak "Method $method not found in " . ref($self);
}

#
#
# PRIVATE METHODS

sub _record_metric {
    my ($self, $type, $name, @args) = @_;

    # 1. Check if metrics are enabled via the async_db state
    # 2. Ensure the global $METRICS object exists
    return unless $self->{_async_db}
               && $self->{_async_db}{_enable_metrics}
               && defined $METRICS;

    # 3. Handle different metric types (parity with old design)
    if ($type eq 'inc') {
        # Usage: $schema->_record_metric('inc', 'query_count', 1)
        $METRICS->inc($name, @args);
    }
    elsif ($type eq 'observe') {
        # Usage: $schema->_record_metric('observe', 'query_duration', 0.05)
        $METRICS->observe($name, @args);
    }
    elsif ($type eq 'set') {
        # Usage: $schema->_record_metric('set', 'worker_pool_size', 5)
        $METRICS->set($name, @args);
    }

    return;
}

sub _resolve_source {
    my ($self, $source_name) = @_;

    croak "Missing source name." unless defined $source_name;

    my $schema_class = $self->{_async_db}{_schema_class};

    croak "Schema class not found." unless defined $schema_class;

    # 1. Ask the main DBIC Schema class for the source metadata
    # We call this on the class name, not an instance, to stay "light"
    my $source = eval { $schema_class->source($source_name) };

    if ($@ || !$source) {
        croak "Could not resolve source '$source_name' in $schema_class: $@";
    }

    # 2. Extract only what we need for the Async side
    return {
        result_class  => $source->result_class,
        columns       => [ $source->columns ],
        relationships => {
            # We map relationships to know how to handle joins/prefetch later
            map { $_ => $source->relationship_info($_) } $source->relationships
        },
    };
}

sub _build_inflator_map {
    my ($self, $schema) = @_;

    my $map = {};
    foreach my $source_name ($schema->sources) {
        my $source = $schema->source($source_name);
        foreach my $col ($source->columns) {
            my $info = $source->column_info($col);

            # Extract both inflate and deflate coderefs
            if ($info->{deflate} || $info->{inflate}) {
                $map->{$source_name}{$col} = {
                    deflate => $info->{deflate},
                    inflate => $info->{inflate},
                };
            }
            # Explicit check for JSON Serializer
            elsif ($info->{serializer_class}
                   && $info->{serializer_class} eq 'JSON') {
                require JSON;
                my $json = JSON->new->utf8->allow_nonref;
                $map->{$source_name}{$col} = {
                    inflate => sub {
                        my $val = shift;
                        return $val if !defined $val || ref($val);

                        my $decoded;
                        eval  {
                            $decoded = $json->decode($val); 1;
                        }
                        or do {
                            warn "Failed to inflate JSON in $col: $@ (Value: $val)";
                            return $val;
                        };
                        return $decoded;
                    },
                    deflate => sub {
                        my $val = shift;
                        return $val if !defined $val || !ref($val);

                        return $json->encode($val);
                    },
                };
            }
        }
    }

    return $map;
}

=head1 METADATA & REFLECTION

=over 4

=item B<source( $source_name )>

Returns the L<DBIx::Class::ResultSource> for the given name.

Unlike standard DBIC, this uses a B<persistent metadata provider> (a cached
internal schema) to ensure that ResultSource objects remain stable across
async calls without re-connecting to the database unnecessarily.

=item B<sources()>

Returns a list of all source names available in the schema. This creates a
temporary, light-weight connection to extract the current schema structure
and then immediately disconnects to save resources.

=item B<class( $source_name )>

Returns the Result Class string (e.g., C<MyApp::Schema::Result::User>) for
the given source. Useful for dynamic inspections.

=item B<schema_class()>

Returns the name of the base L<DBIx::Class> schema class being proxied.

=item B<schema_version()>

Returns the version number defined in your DBIC Schema class, if available.

=back

=head1 TRANSACTION MANAGEMENT

=over 4

=item B<txn_begin / txn_commit / txn_rollback>

These methods return L<Future> objects. Because workers are persistent,
calling C<txn_begin> pins your current logic to a specific worker until
C<commit> or C<rollback> is called.

B<Note:> Use these carefully in an async loop to avoid "Worker Starvation"
where all workers are waiting on long-running manual transactions.

=item B<txn_batch( @operations | \@operations )>

The high-performance alternative to manual transactions. It sends a "bundle"
of operations to a worker to be executed in a single atomic block.

    $schema->txn_batch(
        { type      => 'create',
          resultset => 'User',
          data      => { name => 'Alice' }
        },
        { type      => 'update',
          resultset => 'Stats',
          data      => { count => 1 },
          where     => { id    => 5 }
        }
    );

=back

=head1 LIFECYCLE & STATE

=over 4

=item B<clone( workers =E<gt> $count )>

Creates a fresh instance of the Async Schema. This is useful if you need a
separate pool of workers for "heavy" reporting queries vs. "light" web queries.

=item B<disconnect()>

Gracefully shuts down all background worker processes and flushes the metadata
caches. Use this during app shutdown to prevent zombie processes.

=item B<storage()>

Returns the C<DBIx::Class::Async::Storage::DBI> wrapper. This is provided for
compatibility with components that expect to inspect the DBIC storage layer.

=back

=head1 UTILITIES

=over 4

=item B<populate( $source_name, \@data )>

Performs a high-speed bulk insert. This delegates to the ResultSet's C<populate>
logic and is significantly faster than calling C<create> in a loop.

=item B<search_with_prefetch( $source_name, \%cond, \@prefetch, \%attrs )>

A specialised shortcut for complex joins. It forces C<collapse =E<gt> 1> to ensure
that the data structure returned from the worker process is properly "folded"
into objects, preventing Cartesian product issues over IPC.

=back

=head1 FUTURE HANDLING & UNWRAPPING

This package provides methods to handle L<Future> objects, including recursive
unwrapping for complex async operations and methods for parallel execution.

=head2 await

    my $data = $schema->await($future);
    my @data_list = $schema->await($future);

Suspends the current process, running the underlying L<IO::Async::Loop>
until the provided C<Future> is ready.

This method implements recursive unwrapping of nested Futures. If the
top-level Future resolves to another Future (e.g., a C<txn_do> call), this
method will continue to resolve them until the final data payload is reached.

Throws an exception immediately if the Future chain fails.

Returns the final B<"leaf"> value(s) to the caller. The return value respects
the context of the caller (list or scalar).

=head2 run_parallel

    my $combined_future = $schema->run_parallel(
        sub { $_[0]->resultset('User')->find_future(1) },
        sub { $_[0]->resultset('Log')->count_future() },
    );

Takes a list of coderefs, executes them concurrently passing the schema
object as the first argument, and returns a single L<Future>. This returned
Future resolves to a list of all results when all tasks have completed.

B<Note>: The coderefs passed to this method must return a L<Future> object.
Typically, you would use async methods like C<find_future> or C<search_future>
within these coderefs.

=head2 await_all

    my ($user, $log_count) = $schema->await_all($combined_future);
    # OR
    my ($user, $log_count) = $schema->await_all($f1, $f2);

Takes a single combined L<Future> (like one returned by L</run_parallel>)
or a list of individual L<Future> objects.

It uses L</await> to synchronously wait for all provided Futures to resolve,
and returns the final data results in the same order as the inputs.

Throws an exception if any of the Futures fail.

=head1 CUSTOM INFLATION & SERIALISATION

Because this module uses a Worker-Pool architecture, data must travel across
process boundaries. Standard Perl objects (like L<DateTime> or L<JSON> blobs)
cannot simply be "shared" as live memory.

C<DBIx::Class::Async::Schema> automatically detects your DBIC C<inflate_column>
definitions and mirrors them in the Worker processes.

=head2 How it works

=over 4

=item 1. Deflation (Main to Worker)

When you pass an object to C<create> or C<update>, the bridge deflates it into
a storable format before sending it to the worker.

=item 2. Inflation (Worker to Main)

When results come back, the bridge automatically re-applies your C<inflate> coderefs
to turn raw strings back into rich objects.

=back

=head2 JSON Support

The new design includes built-in support for C<serializer_class =E<gt> 'JSON'>.
If detected in your ResultSource metadata, it will automatically handle the
C<decode>/C<encode> cycle using L<JSON> in a non-blocking manner.

=head2 Manual Registration

If you have complex objects that aren't handled by standard DBIC inflation,
you can register them manually:

    $schema->inflate_column('User', 'preferences', {
        inflate => sub { my $val = shift; decode_json($val) },
        deflate => sub { my $obj = shift; encode_json($obj) },
    });

=head1 PERFORMANCE TIPS

=head2 Worker Count

Adjust the C<workers> parameter based on your database connection limits.
Typically B<2-4 workers per CPU core> works well. Each worker maintains its
own persistent DB connection.

=head2 Prefetching

Use C<search_with_prefetch> to fetch related data in one trip across the
process boundary. This significantly reduces the overhead of IPC (Inter-Process
Communication).

=head1 ERROR HANDLING

All methods return L<Future> objects. Errors from workers (SQL errors,
timeouts, connection drops) are propagated as Future failures. Use
C<< ->catch >> or C<try/catch> with C<await>.

=head1 STATISTICS & METRICS

If C<enable_metrics> is enabled, you can query the internal state:

=over 4

=item * C<total_queries()>: Total operations processed.

=item * C<cache_hits()>: Operations resolved via the internal cache.

=item * C<error_count()>: Total failed operations.

=back

=head1 EXTENSIBILITY & AUTOLOAD

If you call a method on this object that is not defined in the Async package,
it will attempt to proxy the call to the B<Native DBIC Schema>.

This allows you to use custom methods defined in your C<MyApp::Schema> class
seamlessly. However, be aware that calls made via C<AUTOLOAD> are executed in
the B<Parent Process context> and may be blocking unless they specifically
return a L<Future>.

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

    perldoc DBIx::Class::Async::Schema

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

1; # End of DBIx::Class::Async::Schema
