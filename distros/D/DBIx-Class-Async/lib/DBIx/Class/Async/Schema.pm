package DBIx::Class::Async::Schema;

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

our $VERSION = '0.40';

=head1 NAME

DBIx::Class::Async::Schema - Asynchronous schema for DBIx::Class::Async

=head1 VERSION

Version 0.40

=cut

=head1 SYNOPSIS

    use DBIx::Class::Async::Schema;

    # Connect with async options
    my $schema = DBIx::Class::Async::Schema->connect(
        'dbi:mysql:database=test',  # DBI connect string
        'username',                 # Database username
        'password',                 # Database password
        { RaiseError => 1 },        # DBI options
        {                           # Async options
            schema_class => 'MyApp::Schema',
            workers      => 4,
        }
    );

    # Get a resultset
    my $users_rs = $schema->resultset('User');

    # Asynchronous operations
    $users_rs->search({ active => 1 })->all->then(sub {
        my ($active_users) = @_;
        foreach my $user (@$active_users) {
            say "Active user: " . $user->name;
        }
    });

    # Disconnect when done
    $schema->disconnect;

=head1 DESCRIPTION

C<DBIx::Class::Async::Schema> provides an asynchronous schema class that mimics
the L<DBIx::Class::Schema> API but performs all database operations
asynchronously using L<Future> objects.

This class acts as a bridge between the synchronous DBIx::Class API and the
asynchronous backend provided by L<DBIx::Class::Async>. It manages connection
pooling, result sets, and transaction handling in an asynchronous context.

=head1 CONSTRUCTOR

=head2 connect

    my $schema = DBIx::Class::Async::Schema->connect(
        $dsn,           # Database DSN
        $user,          # Database username
        $password,      # Database password
        $db_options,    # Hashref of DBI options
        $async_options, # Hashref of async options
    );

Connects to a database and creates an asynchronous schema instance.

=over 4

=item B<Parameters>

The first four parameters are standard DBI connection parameters. The fifth
parameter is a hash reference containing asynchronous configuration:

=over 8

=item C<schema_class> (required)

The name of the DBIx::Class schema class to use (e.g., 'MyApp::Schema').

=item C<workers>

Number of worker processes (default: 4).

=item C<connect_timeout>

Connection timeout in seconds (default: 10).

=item C<max_retries>

Maximum number of retry attempts for failed operations (default: 3).

=back

=item B<Returns>

A new C<DBIx::Class::Async::Schema> instance.

=item B<Throws>

=over 4

=item *

Croaks if C<schema_class> is not provided.

=item *

Croaks if the schema class cannot be loaded.

=item *

Croaks if the async instance cannot be created.

=back

=back

=cut

sub connect {
    my ($class, @args) = @_;

    # Separate async options from connect_info
    my $async_options = {};
    if (ref $args[-1] eq 'HASH' && !exists $args[-1]->{RaiseError}) {
        # Last arg is async options hash
        $async_options = pop @args;
    }

    my $schema_class = $async_options->{schema_class}
        or croak "schema_class is required in async options";

    my $schema_loaded = 0;

    # Method 1: Check if class already exists
    if (eval { $schema_class->can('connect') }) {
        $schema_loaded = 1;
    }
    # Method 2: Try to require it (for .pm files)
    elsif (eval "require $schema_class") {
        $schema_loaded = 1;
    }
    # Method 3: Check if it's defined in memory (inline class)
    elsif (eval "package main; \$${schema_class}::VERSION ||= '0.01'; 1") {
        # The class exists in memory (defined inline)
        $schema_loaded = 1;
    }

    unless ($schema_loaded) {
        croak "Cannot load schema class $schema_class: $@";
    }

    my $async_db = eval {
        DBIx::Class::Async->new(
            schema_class => $schema_class,
            connect_info => \@args,
            %$async_options,
        );
    };

    if ($@) {
        croak "Failed to create async instance: $@";
    }

    my $self = bless {
        async_db      => $async_db,
        schema_class  => $schema_class,
        connect_info  => \@args,
        sources_cache => {},  # Cache for source lookups
    }, $class;

    my $storage = DBIx::Class::Async::Storage::DBI->new(
        schema   => $self,
        async_db => $async_db,
    );

    $self->{_storage} = $storage;

    return $self;
}

=head1 METHODS

=head2 class

  my $class = $schema->class('User');
  # Returns: 'MyApp::Schema::Result::User'

Returns the class name for the given source name or moniker.

=over 4

=item B<Arguments>

=over 8

=item C<$source_name>

The name of the source/moniker (e.g., 'User', 'Order').

=back

=item B<Returns>

The full class name of the Result class (e.g., 'MyApp::Schema::Result::User').

=item B<Throws>

Dies if the source doesn't exist.

=item B<Examples>

  # Get the Result class for User
  my $user_class = $schema->class('User');
  # $user_class is now 'MyApp::Schema::Result::User'

  # Can be used to call class methods
  my $user_class = $schema->class('User');
  my @columns = $user_class->columns;

  # Or to create new objects directly
  my $user = $schema->class('User')->new({
      name => 'Alice',
      email => 'alice@example.com',
  });

=back

=cut

sub class {
    my ($self, $source_name) = @_;

    require Carp;
    Carp::croak("source_name required") unless defined $source_name;

    # Get the source object
    my $source = eval { $self->source($source_name) };

    if ($@) {
        Carp::croak("No such source '$source_name'");
    }

    # Return the result class
    return $source->result_class;
}

=head2 clone

    my $cloned_schema = $schema->clone;

Creates a clone of the schema with a fresh worker pool.

=over 4

=item B<Returns>

A new C<DBIx::Class::Async::Schema> instance with fresh connections.

=item B<Notes>

The cloned schema shares no state with the original and has its own
worker processes and source cache.

=back

=cut

sub clone {
    my $self = shift;
    my %args = @_;

    my $worker_count = $args{workers}
        || $self->{async_db}->{workers_config}{count}
        || $self->{async_db}->workers  # If there's a method
        || 2;                          # Sensible default

    return bless {
        %$self,
        # Clone with fresh worker pool
        async_db => DBIx::Class::Async->new(
            schema_class => $self->{schema_class},
            connect_info => [@{$self->{connect_info}}],
            workers      => $worker_count,
            (defined $self->{loop} ? (loop => $self->{loop}) : ()),
        ),
        sources_cache => {},  # Fresh cache
    }, ref $self;
}

=head2 deploy

    my $future = $schema->deploy(\%sqlt_args?, $dir?);

    $future->on_done(sub {
        my $self = shift;
        say "Schema deployed successfully.";
    });

=over 4

=item Arguments: \%sqlt_args?, $dir?

=item Return Value: L<Future> resolving to $self

=back

Asynchronously deploys the database schema.

This is a non-blocking proxy for L<DBIx::Class::Schema/deploy>. The actual SQL
translation (via L<SQL::Translator>) and DDL execution are performed in a
background worker process to prevent the main event loop from stalling.

The optional C<\%sqlt_args> are passed directly to the worker-side
C<deploy> method. Common options include:

=over 4

=item * C<add_drop_table> - Prepends a C<DROP TABLE> statement for each table.

=item * C<quote_identifiers> - Ensures database identifiers are correctly quoted.

=back

On success, the returned L<Future> resolves to the schema object (C<$self>),
allowing for easy method chaining. On failure, the Future fails with the
error message generated by the worker.

=cut

sub deploy {
    my ($self, $sqlt_args, $dir) = @_;

    croak "Async database handle not initialised" unless $self->{async_db};

    return $self->{async_db}->deploy($sqlt_args, $dir)->then(sub {
        my ($res) = @_;

        if (ref $res eq 'HASH' && $res->{__error}) {
            return Future->fail($res->{__error});
        }

        return Future->done($self);
    });
}

=head2 disconnect

    $schema->disconnect;

Disconnects all worker processes and cleans up resources.

=over 4

=item B<Notes>

This method is called automatically when the schema object is destroyed,
but it's good practice to call it explicitly when done with the schema.

=back

=cut

sub disconnect {
    my $self = shift;
    $self->{async_db}->disconnect if $self->{async_db};
}

=head2 populate

  # Array of hashrefs format
  my $users = $schema->populate('User', [
      { name => 'Alice', email => 'alice@example.com' },
      { name => 'Bob',   email => 'bob@example.com' },
  ])->get;

  # Column list + rows format
  my $users = $schema->populate('User', [
      [qw/ name email /],
      ['Alice', 'alice@example.com'],
      ['Bob',   'bob@example.com'],
  ])->get;

A convenience shortcut to L<DBIx::Class::Async::ResultSet/populate>.
Creates multiple rows efficiently.

=over 4

=item B<Arguments>

=over 8

=item C<$source_name>

The name of the source/moniker (e.g., 'User', 'Order').

=item C<$data>

Either:

- Array of hashrefs: C<< [ \%col_data, \%col_data, ... ] >>

- Column list + rows: C<< [ \@column_list, \@row_values, \@row_values, ... ] >>

=back

=item B<Returns>

A L<Future> that resolves to an arrayref of L<DBIx::Class::Async::Row> objects
in scalar context, or a list in list context.

=item B<Examples>

  # Array of hashrefs
  $schema->populate('User', [
      { name => 'Alice', email => 'alice@example.com', active => 1 },
      { name => 'Bob',   email => 'bob@example.com',   active => 1 },
      { name => 'Carol', email => 'carol@example.com', active => 0 },
  ])->then(sub {
      my ($users) = @_;
      say "Created " . scalar(@$users) . " users";
  });

  # Column list + rows (more efficient for many rows)
  $schema->populate('User', [
      [qw/ name email active /],
      ['Alice', 'alice@example.com', 1],
      ['Bob',   'bob@example.com',   1],
      ['Carol', 'carol@example.com', 0],
  ])->then(sub {
      my ($users) = @_;
      foreach my $user (@$users) {
          say "Created: " . $user->name;
      }
  });

=back

=cut

sub populate {
    my ($self, $source_name, $data) = @_;

    croak("source_name required")     unless defined $source_name;
    croak("data required")            unless defined $data;
    croak("data must be an arrayref") unless ref $data eq 'ARRAY';

    # Delegate to resultset->populate
    return $self->resultset($source_name)->populate($data);
}

=head2 register_class

  $schema->register_class($source_name => $result_class);

Registers a new Result class with the schema. This is a convenience method
that loads the Result class, gets its result source, and registers it.

B<Arguments>

=over 4

=item * C<$source_name> - String name for the source (e.g., 'User', 'Product')

=item * C<$result_class> - Fully qualified Result class name

=back

  # Register a Result class
  $schema->register_class('Product' => 'MyApp::Schema::Result::Product');

  # Now you can use it
  my $rs = $schema->resultset('Product');

This method will load the Result class if it hasn't been loaded yet.

=cut

sub register_class {
    my ($self, $source_name, $result_class) = @_;

    # Load the class if not already loaded
    eval "require $result_class";
    if ($@) {
        croak "Failed to load Result class '$result_class': $@";
    }

    # Get the result source instance
    my $source = $result_class->result_source_instance;

    # Register it
    return $self->register_source($source_name, $source);
}

=head2 register_source

  $schema->register_source($source_name => $source);

Registers a new result source with the schema. This is used to add new tables
or views to the schema at runtime.

B<Arguments>

=over 4

=item * C<$source_name> - String name for the source (e.g., 'User', 'Product')

=item * C<$source> - A L<DBIx::Class::ResultSource> instance

=back

  # Define a new Result class
  package MyApp::Schema::Result::Product;
  use base 'DBIx::Class::Core';

  __PACKAGE__->table('products');
  __PACKAGE__->add_columns(
      id => { data_type => 'integer', is_auto_increment => 1 },
      name => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');

  # Register it with the schema
  $schema->register_source('Product',
      MyApp::Schema::Result::Product->result_source_instance
  );

=cut

sub register_source {
    my ($self, $source_name, $source) = @_;

    # Delegate to the underlying sync schema class
    my $schema_class = $self->{_schema_class};

    # Register with the class, not the instance
    return $schema_class->register_source($source_name, $source);
}

=head2 resultset

    my $rs = $schema->resultset('User');

Returns a result set for the specified source/table.

=over 4

=item B<Parameters>

=over 8

=item C<$source_name>

Name of the result source (table) to get a result set for.

=back

=item B<Returns>

A L<DBIx::Class::Async::ResultSet> object.

=item B<Throws>

Croaks if C<$source_name> is not provided.

=back

=cut

sub resultset {
    my ($self, $source_name) = @_;

    croak "resultset() requires a source name" unless $source_name;

    return DBIx::Class::Async::ResultSet->new(
        schema      => $self,
        async_db    => $self->{async_db},
        source_name => $source_name,
    );
}

=head2 schema_version

    my $version = $schema->schema_version;

Returns the normalised version string of the underlying L<DBIx::Class::Schema>
class.

=cut

sub schema_version {
    my $self  = shift;
    my $class = $self->{schema_class};

    croak("schema_class is not defined in " . ref($self)) unless $class;

    # Delegates to the class method on the Result class
    return $class->schema_version;
}

=head2 set_default_context

    $schema->set_default_context;

Sets the default context for the schema.

=over 4

=item B<Returns>

The schema object itself (for chaining).

=item B<Notes>

This is a no-op method provided for compatibility with DBIx::Class.

=back

=cut

sub set_default_context {
    my $self = shift;
    # No-op for compatibility
    return $self;
}

=head2 source

    my $source = $schema->source('User');

Returns the result source object for the specified source/table.

=over 4

=item B<Parameters>

=over 8

=item C<$source_name>

Name of the result source (table).

=back

=item B<Returns>

A L<DBIx::Class::ResultSource> object.

=item B<Notes>

Sources are cached internally after first lookup to avoid repeated
database connections.

=back

=cut

sub source {
    my ($self, $source_name) = @_;

    unless (exists $self->{sources_cache}{$source_name}) {
        my $temp_schema = $self->{schema_class}->connect(@{$self->{connect_info}});
        $self->{sources_cache}{$source_name} = $temp_schema->source($source_name);
        $temp_schema->storage->disconnect;
    }

    return $self->{sources_cache}{$source_name};
}

=head2 sources

    my @source_names = $schema->sources;

Returns a list of all available source/table names.

=over 4

=item B<Returns>

Array of source names (strings).

=item B<Notes>

This method creates a temporary synchronous connection to the database
to fetch the source list.

=back

=cut

sub sources {
    my $self = shift;

    my $temp_schema = $self->{schema_class}->connect(@{$self->{connect_info}});
    my @sources = $temp_schema->sources;
    $temp_schema->storage->disconnect;

    return @sources;
}

=head2 storage

    my $storage = $schema->storage;

Returns a storage object for compatibility with DBIx::Class.

=over 4

=item B<Returns>

A L<DBIx::Class::Async::Storage> object.

=item B<Notes>

This storage object does not provide direct database handle access
since operations are performed asynchronously by worker processes.

=back

=cut

sub storage {
    my $self = shift;
    return $self->{_storage};
}

=head2 txn_batch

    my $result = await $schema->txn_batch(@operations);

A proxy method for L<DBIx::Class::Async/txn_batch>. Executes a series of
database operations (create, update, delete, or raw SQL) atomically
within a single background transaction.

=cut

sub txn_batch {
    my ($self, @args) = @_;

    croak "Async database handle not initialised in schema."
        unless $self->{async_db};

    return $self->{async_db}->txn_batch(@args);
}

=head2 txn_do

    $schema->txn_do(sub {
        my $txn_schema = shift;
        # Perform async operations within transaction
        return $txn_schema->resultset('User')->create({
            name  => 'Alice',
            email => 'alice@example.com',
        });
    })->then(sub {
        my ($result) = @_;
        # Transaction committed successfully
    })->catch(sub {
        my ($error) = @_;
        # Transaction rolled back
    });

Executes a code reference within a database transaction.

=over 4

=item B<Parameters>

=over 8

=item C<$code>

Code reference to execute within the transaction. The code receives
the schema instance as its first argument.

=item C<@args>

Additional arguments to pass to the code reference.

=back

=item B<Returns>

A L<Future> that resolves to the return value of the code reference
if the transaction commits, or rejects with an error if the transaction
rolls back.

=item B<Throws>

=over 4

=item *

Croaks if the first argument is not a code reference.

=back

=back

=cut

sub txn_do {
    my ($self, $code, @args) = @_;

    croak "txn_do requires a coderef" unless ref $code eq 'CODE';

    return $self->{async_db}->txn_do($code);
}

=head2 unregister_source

    $schema->unregister_source($source_name);

Arguments: $source_name

Removes the specified L<DBIx::Class::ResultSource> from the schema class.
This is useful in test suites to ensure a clean state between tests.

=cut

sub unregister_source {
    my ($self, $source_name) = @_;
    my $class = $self->{schema_class};

    croak("schema_class is not defined in " . ref($self)) unless $class;

    return $class->unregister_source($source_name);
}

=head1 AUTOLOAD

The schema uses AUTOLOAD to delegate unknown methods to the underlying
L<DBIx::Class::Async> instance. This allows direct access to async
methods like C<search>, C<find>, C<create>, etc., without going through
a resultset.

Example:

    # These are equivalent:
    $schema->find('User', 123);
    $schema->resultset('User')->find(123);

Methods that are not found in the schema or the async instance will
throw an error.

=cut

sub AUTOLOAD {
    my $self = shift;

    our $AUTOLOAD;
    my ($method) = $AUTOLOAD =~ /([^:]+)$/;

    return if $method eq 'DESTROY';

    if ($self->{async_db} && $self->{async_db}->can($method)) {
        return $self->{async_db}->$method(@_);
    }

    croak "Method $method not found in " . ref($self);
}

=head1 DESTROY

The schema's destructor automatically calls C<disconnect> to clean up
worker processes and other resources.

=cut

sub DESTROY {
    my $self = shift;
    $self->disconnect;
}

=head1 DESIGN ARCHITECTURE

This module acts as an asynchronous proxy for L<DBIx::Class::Schema>. While
data-retrieval methods (like C<search>, C<create>, and C<find>) return
L<Future> objects and execute in worker pools, metadata management methods
(like C<unregister_source> and C<schema_version>) are delegated directly
to the underlying synchronous schema class to ensure metadata consistency
across processes.

=head1 ARCHITECTURAL NOTE

B<Removal of txn_scope_guard>

In C<DBIx::Class::Async>, the traditional C<txn_scope_guard> pattern has been
intentionally removed. While this pattern is a staple of synchronous
L<DBIx::Class> development, it is fundamentally incompatible with an
asynchronous, worker-pool architecture.

The following analysis explains the technical limitations that led to this
decision.

=head2 1. The Scope vs. Execution Race Condition

In a synchronous environment, a scope guard works because the program pauses
until every line inside the block completes. The C<DESTROY> method (which
triggers an automatic rollback) only fires after all work is done.

In an asynchronous environment, the block often finishes execution and
destroys the guard while the database requests are still in flight.

  {
      my $guard = $schema->txn_scope_guard;
      $schema->resultset('User')->create({ name => 'Bob' });
      # Request is sent to the worker; a Future is returned immediately.
  }
  # 1. The block ends here.
  # 2. $guard is destroyed, triggering an immediate ROLLBACK command.
  # 3. The ROLLBACK may arrive at the worker before the 'create' is processed.

This results in a "Silent Failure" where the application receives a success
notification from the L<Future>, but the data is never committed to the disk.

=head2 2. Worker Affinity and Statelessness

C<DBIx::Class::Async> utilises a pool of background worker processes to
achieve concurrency. Transactions are inherently "stateful" - a database
handle must remain assigned to a specific transaction until it is finished.

=over 4

=item * B<The Affinity Problem:> Without pinning a user session to a
specific worker, Operation A might go to Worker 1, while Operation B goes
to Worker 2. Worker 2 has no context regarding the transaction started
on Worker 1.

=item * B<Worker Starvation:> To support a Scope Guard, a worker would have
to "lock" itself to a single caller and refuse all other work until a
C<commit> or C<rollback> is received. In a high-concurrency environment, a
few unclosed guards could easily exhaust the worker pool, causing the
entire application to hang.

=back

=head2 3. The Recommended Alternative: txn_batch

To provide the same atomicity and safety as a transaction guard without the
architectural risks, use the L</txn_batch> method.

C<txn_batch> packages all operations into a single atomic message sent to
a single worker. The worker opens the transaction, executes all queries,
and commits the results before returning the handle to the pool.

=head2 4. Comparison at a Glance

    Feature            | txn_scope_guard   | txn_batch
    -------------------|-------------------|------------------
    Execution          | Non-deterministic | Atomic / Single-hop
    Worker Logic       | Stateful (Risky)  | Stateless (Safe)
    Cleanup            | Perl DESTROY      | Internal Worker Logic
    Race Conditions    | High Risk         | None

=head1 PERFORMANCE OPTIMISATION

=head2 Resolving the N+1 Query Problem

One of the most common performance bottlenecks in ORMs is the "N+1" query pattern. This occurs when you fetch a set of rows and then loop through them to fetch a related row for each member of the set.

In an asynchronous environment, this is particularly costly due to the overhead of message passing between the main process and the database worker pool.

L<DBIx::Class::Async::Schema> resolves this by supporting the standard L<DBIx::Class> B<prefetch> attribute.

=head3 The Slow Way (N+1 Pattern)

In this example, if there are 50 orders, this code will perform 51 database round-trips.

    my $orders = await $async_schema->resultset('Order')->all;

    foreach my $order (@$orders) {
        # Each call here triggers a NEW asynchronous find() query to a worker
        my $user = await $order->user;
        say "Order for: " . $user->name;
    }

=head3 The Optimised Way (Eager Loading)

By using C<prefetch>, you instruct the worker to perform a C<JOIN> in the background. The related data is serialised and sent back in the primary payload. The library then automatically hydrates the nested data into blessed Row objects.

    # Only ONE database round-trip for any number of orders
    my $orders = await $async_schema->resultset('Order')->search(
        {},
        { prefetch => 'user' }
    );

    foreach my $order (@$orders) {
        # This returns a resolved Future immediately from the internal cache.
        # No extra SQL or worker communication is required.
        my $user = await $order->user;
        say "Order for: " . $user->name;
    }

=head2 Complex Prefetching

The hydration logic is recursive. You can prefetch multiple levels of relationships or multiple independent relationships simultaneously.

    my $rs = $async_schema->resultset('Order')->search({}, {
        prefetch => [
            { user => 'profile' }, # Nested: Order -> User -> Profile
            'status_logs'          # Direct: Order -> Logs
        ]
    });

    my $orders = await $rs->all;

    # All the following are available instantly:
    my $user    = await $orders->[0]->user;
    my $profile = await $user->profile;

=head2 Implementation Details

=over 4

=item * B<Automation>: Prefetched data is automatically cached in an internal C<_prefetched> slot within the L<DBIx::Class::Async::Row> object during inflation.

=item * B<Transparency>: The relationship accessors generated by L<DBIx::Class::Async::Row> transparently check this cache before attempting a lazy-load via the worker pool.

=item * B<Efficiency>: By collapsing multiple queries into one, you significantly reduce the latency introduced by inter-process communication (IPC) and database contention.

=back

=head1 SEE ALSO

=over 4

=item *

L<DBIx::Class::Async> - Core asynchronous L<DBIx::Class> implementation

=item *

L<DBIx::Class::Async::ResultSet> - Asynchronous result sets

=item *

L<DBIx::Class::Async::Row> - Asynchronous row objects

=item *

L<DBIx::Class::Async::Storage> - Storage compatibility layer

=item *

L<DBIx::Class::Schema> - Standard DBIx::Class schema

=item *

L<Future> - Asynchronous programming abstraction

=back

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
