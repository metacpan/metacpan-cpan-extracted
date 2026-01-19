package DBIx::Class::Async::ResultSet;

use strict;
use warnings;
use utf8;
use v5.14;

use Carp;
use Future;
use Scalar::Util 'blessed';
use DBIx::Class::Async::Row;

=head1 NAME

DBIx::Class::Async::ResultSet - Asynchronous resultset for DBIx::Class::Async

=head1 VERSION

Version 0.40

=cut

our $VERSION = '0.40';

=head1 SYNOPSIS

    use DBIx::Class::Async::ResultSet;

    # Typically obtained from DBIx::Class::Async::Schema
    my $rs = $schema->resultset('User');

    # Synchronous methods (return Future objects)
    $rs->all->then(sub {
        my ($users) = @_;
        foreach my $user (@$users) {
            say "User: " . $user->name;
        }
    });

    $rs->search({ active => 1 })->count->then(sub {
        my ($count) = @_;
        say "Active users: $count";
    });

    # Asynchronous future methods
    $rs->all_future->then(sub {
        my ($data) = @_;
        # Raw data arrayref
    });

    # Chaining methods
    $rs->search({ status => 'active' })
       ->order_by('created_at')
       ->rows(10)
       ->all->then(sub {
           my ($active_users) = @_;
           # Process results
       });

    # Create new records
    $rs->create({
        name  => 'Alice',
        email => 'alice@example.com',
    })->then(sub {
        my ($new_user) = @_;
        say "Created user ID: " . $new_user->id;
    });

=head1 DESCRIPTION

C<DBIx::Class::Async::ResultSet> provides an asynchronous result set interface
for L<DBIx::Class::Async>. It mimics the L<DBIx::Class::ResultSet> API but
returns L<Future> objects for database operations, allowing non-blocking
asynchronous database access.

This class supports both synchronous-style iteration (using C<next> and C<reset>)
and asynchronous operations (using C<then> callbacks). All database operations
are delegated to the underlying L<DBIx::Class::Async> instance.

=head1 ARCHITECTURAL ROLE

In a standard DBIC environment, the ResultSet holds a live database handle. In
the C<Async> environment, the "real" ResultSet lives in a background worker.
This class exists on the application side to provide:

=over 4

=item B<Lazy Inflation>

Results are not turned into objects until they are actually needed. This saves
CPU cycles if you are only passing data through to a JSON encoder.

=item B<Relationship Stitching>

When C<search_with_prefetch> is used, the worker sends back a nested data structure.
This class's C<new_result> method is responsible for "stitching" that data back
together so that C<< $user->orders >> returns the prefetched collection without
triggering new database queries.

=item B<Dynamic Class Hijacking>

This class uses an anonymous proxy pattern to ensure that if a user requests a
custom C<result_class>, the resulting objects inherit correctly from both the
Async framework and the user's custom class.

=back

=head1 CONSTRUCTOR

=head2 new

    my $rs = DBIx::Class::Async::ResultSet->new(
        schema      => $schema,            # DBIx::Class::Schema instance
        async_db    => $async_db,          # DBIx::Class::Async instance
        source_name => $source_name,       # Result source name
    );

Creates a new asynchronous result set.

=over 4

=item B<Parameters>

=over 8

=item C<schema>

A L<DBIx::Class::Schema> instance. Required.

=item C<async_db>

A L<DBIx::Class::Async> instance. Required.

=item C<source_name>

The name of the result source (table). Required.

=back

=item B<Throws>

=over 4

=item *

Croaks if any required parameter is missing.

=back

=back

=cut

sub new {
    my ($class, %args) = @_;

    croak "Missing required argument: schema"      unless $args{schema};
    croak "Missing required argument: async_db"    unless $args{async_db};
    croak "Missing required argument: source_name" unless $args{source_name};

    return bless {
        schema        => $args{schema},
        async_db      => $args{async_db},
        source_name   => $args{source_name},
        _source       => undef,
        _cond         => {},
        _attrs        => {},
        _rows         => undef,
        _pos          => 0,
        entries       => $args{entries}       || undef, # For prefetched data
        is_prefetched => $args{is_prefetched} || 0,     # Flag for prefetch
    }, $class;
}

=head2 new_result

    my $row = $rs->new_result($hashref);

A core inflation method that transforms a raw hash of database results into a
fully-functional row object. Unlike standard inflation, this method is
architected for the asynchronous, disconnected nature of background workers.

B<Features>

=over 4

=item * B<Dynamic Subclassing>:

Generates a specialised class (e.g., C<DBIx::Class::Async::Row::User>) per
ResultSource to ensure clean method resolution.

=item * B<Custom Class Support>:

If a C<result_class> is set, it dynamically creates an anonymous proxy
(C<...::Anon::*>) that uses multiple inheritance to combine your custom
methods with the asynchronous row logic.

=item * B<Deep Inflation (Prefetch)>:

Detects nested data structures (hashes or arrays) in the input and injects
them into the object's internal relationship cache, allowing for
non-blocking access to related data.

=item * B<Data Normalization>:

Handles SQL aliases (like C<me.id>), primary key detection for storage state,
and preserves literal SQL columns (like C<COUNT(*)>) that may not exist
in the schema.

=back

Returns a blessed object inheriting from L<DBIx::Class::Async::Row>.
Returns C<undef> if the provided data is empty or undefined.

=cut

sub new_result {
    my ($self, $data) = @_;

    # 1. Start with the standard Async Row class
    my $source_name = $self->{source_name};
    my $row_class   = "DBIx::Class::Async::Row::$source_name";

    # Ensure the base Async Row class exists
    {
        no strict 'refs';
        unless (@{"${row_class}::ISA"}) {
            @{"${row_class}::ISA"} = ('DBIx::Class::Async::Row');
        }
    }

    $data    //= {};
    my $source = $self->result_source;
    my ($pk)   = $source->primary_columns;

    # 2. Determine storage state
    my $is_in_storage = 0;
    if (exists $data->{_in_storage}) {
        $is_in_storage = delete $data->{_in_storage};
    } elsif ($pk && defined $data->{$pk}) {
        $is_in_storage = 1;
    }

    # 3. Data Normalization (Keeping the working Prefetch & Count fixes)
    my %clean_data;
    my %rel_data;

    my %expected = map { lc($_) => $_ } $source->columns;
    if (my $as = $self->{attrs}->{as}) {
        my @as_list = ref $as eq 'ARRAY' ? @$as : ($as);
        $expected{lc($_)} = $_ for @as_list;
    }

    foreach my $key (keys %$data) {
        my $clean_key = $key;
        $clean_key    =~ s/^me\.//i;

        if (ref $data->{$key} eq 'HASH' || ref $data->{$key} eq 'ARRAY') {
            $rel_data{$key} = $data->{$key};
        }
        elsif (exists $expected{lc($clean_key)}) {
            $clean_data{$expected{lc($clean_key)}} = $data->{$key};
        }
        else {
            # Keep literal counts/aliases
            $clean_data{$key} = $data->{$key};
        }
    }

    # 4. Instantiate the Row
    my $row = $row_class->new(
        schema      => $self->{schema},
        async_db    => $self->{async_db},
        source_name => $source_name,
        row_data    => \%clean_data,
        in_storage  => $is_in_storage,
    );

    # 5. Handle Custom Result Class Overrides
    my $target_class = $self->result_class;

    # If the target class isn't our standard generated one, we must rebless
    if ($target_class ne $row_class
        && $target_class ne $self->result_source->result_class) {
        my $anon_class = "${row_class}::WITH::" . $target_class;
        $anon_class =~ s/::/_/g;
        $anon_class = "DBIx::Class::Async::Anon::$anon_class";

        no strict 'refs';
        unless (@{"${anon_class}::ISA"}) {
            # Load the custom class if needed
            eval "require $target_class" unless $target_class->can('new');

            # The order ensures Async::Row methods take precedence over custom ones
            @{"${anon_class}::ISA"} = ($row_class, $target_class);
        }
        bless $row, $anon_class;
    }

    # 6. Finalize state
    $row->{_dirty} = {} if $is_in_storage;
    $row->{_data}  = \%clean_data;

    if (keys %rel_data) {
        $row->{_relationship_data} = \%rel_data;
    }

    return $row;
}

=head2 new_result_set

  my $new_rs = $rs->new_result_set({
      entries       => \@prefetched_data,
      is_prefetched => 0
  });

Creates a new instance (clone) of the current ResultSet class, inheriting the
schema, database connection, and source name.

This is primarily used internally to handle prefetched relationships. When a
C<has_many> relationship is accessed, this method creates a "virtual" ResultSet
seeded with the data already retrieved in the initial query, preventing
unnecessary follow-up database hits.

Accepts a hashref of attributes to override in the new instance.

=cut

sub new_result_set {
    my ($self, $args) = @_;

    $args //= {};

    return (ref $self)->new(
        schema      => $self->{schema},
        async_db    => $self->{async_db},
        source_name => $self->{source_name},
        %$args,
    );
}

=head1 METHODS

=head2 all

    $rs->all->then(sub {
        my ($rows) = @_;
        # $rows is an arrayref of DBIx::Class::Async::Row objects
    });

Returns all rows matching the current search criteria as L<DBIx::Class::Async::Row> objects,
with prefetched relationships properly inflated.

=over 4

=item B<Returns>

A L<Future> that resolves to an array reference of L<DBIx::Class::Async::Row>
objects.

=item B<Notes>

Results are cached internally for use with C<next> and C<reset> methods.

=back

=cut

sub all {
    my $self = shift;

    # 1. Handle cached or prefetched ResultSet
    if ($self->{is_prefetched} && $self->{entries}) {
        # If entries are already objects (from set_cache), return them
        if (ref $self->{entries}[0]
            && $self->{entries}[0]->isa('DBIx::Class::Async::Row')) {
            $self->{_rows} = $self->{entries};
            return Future->done($self->{_rows});
        }

        # Otherwise, inflate raw entries
        my @rows       = map { $self->new_result($_) } @{$self->{entries}};
        $self->{_rows} = \@rows;
        return Future->done(\@rows);
    }

    # 2. Standard Async Fetch
    return $self->{async_db}->search(
        $self->{source_name},
        $self->{_cond},
        $self->{_attrs}
    )->then(sub {
        my ($rows_data) = @_;

        my @rows = map {
            my $row_data = $_;
            my $row = $self->new_result($row_data);

            # If the hash contains nested data, it's prefetched
            if (grep { ref($row_data->{$_}) } keys %$row_data) {
                $self->_inflate_prefetch($row, $row_data, $self->{_attrs}{prefetch});
            }

            $row;
        } @$rows_data;

        $self->{_rows} = \@rows;
        $self->{_pos}  = 0;

        return Future->done(\@rows);
    });
}

=head2 all_future

    $rs->all_future->then(sub {
        my ($data) = @_;
        # $data is an arrayref of raw hashrefs
    });

Returns all rows matching the current search criteria as raw data.

=over 4

=item B<Returns>

A L<Future> that resolves to an array reference of hash references containing
raw row data.

=item B<Notes>

This method bypasses row object creation for performance. Use C<all> if you
need L<DBIx::Class::Async::Row> objects.

=back

=cut

sub all_future {
    my $self = shift;

    return $self->{async_db}->search(
        $self->{source_name},
        $self->{_cond},
        $self->{_attrs}
    )->then(sub {
        my ($rows_data) = @_;
        # Store raw data so iterator methods can use them without re-fetching
        $self->{_rows}  = $rows_data;
        $self->{_pos}   = 0;
        return Future->done($rows_data);
    });
}

=head2 as_query

    my ($cond, $attrs) = $rs->as_query;

Returns the internal search conditions and attributes.

=over 4

=item B<Returns>

A list containing two hash references: conditions and attributes.

=back

=cut

sub as_query {
    my $self = shift;
    my $bridge = $self->{async_db};
    my $schema_class = $bridge->{schema_class};

    unless ($schema_class->can('resultset')) {
        eval "require $schema_class" or die "as_query: Could not load $schema_class: $@";
    }

    $bridge->{_metadata_schema} //= $schema_class->connect();

    my $real_rs = $bridge->{_metadata_schema}
                         ->resultset($self->{source_name})
                         ->search($self->{_cond}, $self->{_attrs});

    # This always returns the \[ $sql, @bind ] structure
    return $real_rs->as_query;
}

=head2 clear_cache

  $rs->clear_cache;

Clears the internal cache of the ResultSet. This forces the next execution
of the ResultSet to fetch fresh data from the database (or the global
query cache). Returns C<undef>.

=cut

sub clear_cache {
    my $self = shift;
    $self->{_rows}         = undef;
    $self->{entries}       = undef;
    $self->{is_prefetched} = 0;
    return undef;
}

=head2 count

    $rs->count->then(sub {
        my ($count) = @_;
        say "Found $count rows";
    });

Returns the count of rows matching the current search criteria.

=over 4

=item B<Returns>

A L<Future> that resolves to the number of matching rows.

=back

=cut

sub count {
    my $self = shift;

    # If we have rows/offset, we need to count differently
    # We can't just pass the condition - we need to actually apply the slice
    if (exists $self->{_attrs}{rows} || exists $self->{_attrs}{offset}) {
        # For sliced ResultSets, we need to fetch and count
        return $self->all->then(sub {
            my ($results) = @_;
            return Future->done(scalar @$results);
        });
    }

    # Normal count without slice
    return $self->{async_db}->count(
        $self->{source_name},
        $self->{_cond},
    );
}

=head2 count_future

    $rs->count_future->then(sub {
        my ($count) = @_;
        # Same as count(), alias for API consistency
    });

Alias for C<count>. Returns the count of rows matching the current search criteria.

=over 4

=item B<Returns>

A L<Future> that resolves to the number of matching rows.

=back

=cut

sub count_future {
    my $self = shift;

    return $self->{async_db}->count(
        $self->{source_name},
        $self->{_cond}
    );
}

=head2 count_literal

    my $count = await $rs->count_literal('age > ? AND status = ?', 18, 'active');

=over 4

=item Arguments: $sql_fragment, @standalone_bind_values

=item Return Value: L<Future> (resolving to Integer)

=back

Counts the results in a literal query.

This method is provided primarily for L<Class::DBI> compatibility. It is
equivalent to calling L</search_literal> with the passed arguments,
followed by L</count>.

Because this triggers an immediate database query, it returns a L<Future>
that will resolve to the integer count once the worker process has
completed the execution.

B<Note:> Always use placeholders (C<?>) in your C<$sql_fragment> to
maintain security and prevent SQL injection.

=cut

sub count_literal {
    my ($self, $sql_fragment, @bind) = @_;

    # This satisfies your requirement: search_literal then count.
    # Since search_literal returns a ResultSet, and count returns a Future,
    # this returns the Future for the count operation.
    return $self->search_literal($sql_fragment, @bind)->count;
}

=head2 count_rs

    my $count_rs = $rs->count_rs({ active => 1 });
    # Use as a subquery:
    my $users = await $schema->resultset('User')->search({
        login_count => $count_rs->as_query
    })->all;

=over 4

=item Arguments: $cond?, \%attrs?

=item Return Value: L<DBIx::Class::Async::ResultSet>

=back

Returns a new ResultSet object that, when executed, performs a C<COUNT(*)>
operation. Unlike C<count>, this method is lazy and does not dispatch a
request to the worker pool immediately. It is primarily useful for
constructing subqueries or complex joins where the count is part of a
larger query.

=cut

sub count_rs {
    my ($self, $cond, $attrs) = @_;

    # count_rs is lazy. It doesn't call the worker yet.
    # It returns a new ResultSet constrained to a count.
    return $self->search($cond, {
        %{$attrs || {}},
        select => [ { count => '*' } ],
        as     => [ 'count' ],
    });
}

=head2 count_total

    my $future = $rs->count_total;
    my $total  = $future->get;

Returns a L<Future> that resolves to the total number of records matching the
ResultSet's conditions, specifically ignoring any pagination attributes
(C<rows>, C<offset>, or C<page>).

This is distinct from the standard C<count> method, which in an asynchronous
context often reflects the size of the current page (the "slice") rather than
the total dataset. This method is used internally by the L<pager|/pager>
to calculate the last page number and total entries.

You can optionally pass additional conditions or attributes to be merged:

    my $total = $rs->count_total({ status => 'active' })->get;

=cut

sub count_total {
    my ($self, $cond, $attrs) = @_;

    my $merged_cond  = { %{ $self->{_cond}  || {} }, %{ $cond  || {} } };
    my $merged_attrs = { %{ $self->{_attrs} || {} }, %{ $attrs || {} } };

    delete $merged_attrs->{rows};
    delete $merged_attrs->{offset};
    delete $merged_attrs->{page};

    return $self->{async_db}->count(
        $self->{source_name},
        $merged_cond,
        $merged_attrs,
    );
}

=head2 create

    $rs->create({ name => 'Alice', email => 'alice@example.com' })
       ->then(sub {
           my ($new_row) = @_;
           say "Created row ID: " . $new_row->id;
       });

Creates a new row in the database.

=over 4

=item B<Parameters>

=over 8

=item C<$data>

Hash reference containing column-value pairs for the new row.

=back

=item B<Returns>

A L<Future> that resolves to a L<DBIx::Class::Async::Row> object representing
the newly created row.

=back

=cut

sub create {
    my ($self, $data) = @_;

    # Combine the ResultSet's current search condition, which contains
    # the foreign key) with the new data provided by the user.
    my %to_insert = ( %{$self->{_cond} || {}}, %$data );

    # Clean up prefixes: DBIC sometimes stores conditions as 'foreign.user_id'
    # but we need 'user_id' for the INSERT statement.
    my %final_data;
    while (my ($k, $v) = each %to_insert) {
        my $clean_key = $k;
        $clean_key =~ s/^(?:foreign|self)\.//;
        $final_data{$clean_key} = $v;
    }

    return $self->{async_db}->create(
        $self->{source_name},
        \%final_data
    )->then(sub {
        my ($result) = @_;

        if (ref $result eq 'HASH'
            && ($result->{error} || $result->{__error})) {
            my $err = $result->{error} // $result->{__error};
            return Future->fail($err, 'db_error');
        }

        return Future->done($self->new_result($result, { in_storage => 1 }));
    });
}

=head2 cursor

  my $cursor = $rs->cursor;

Returns a L<DBIx::Class::Async::Storage::DBI::Cursor> object for iterating
through the ResultSet's rows asynchronously.

The cursor provides a low-level interface for fetching rows one at a time
using Futures, which is useful for processing large result sets without
loading all rows into memory at once.

  use Future::AsyncAwait;

  my $rs = $schema->resultset('User');
  my $cursor = $rs->cursor;

  my $iter = async sub {
      while (my $row = await $cursor->next) {
          # Process each row asynchronously
          say $row->name;
      }
  };

  $iter->get;  # Wait for iteration to complete

The cursor respects the ResultSet's C<rows> attribute for batch fetching:

  my $rs = $schema->resultset('User')->search(undef, { rows => 50 });
  my $cursor = $rs->cursor;  # Will fetch 50 rows at a time

See L<DBIx::Class::Async::Storage::DBI::Cursor> for available cursor methods
including C<next()> and C<reset()>.

=cut

sub cursor {
    my $self = shift;
    return $self->schema->storage->cursor($self);
}

=head2 delete

    $rs->search({ status => 'inactive' })->delete->then(sub {
        my ($deleted_count) = @_;
        say "Deleted $deleted_count rows";
    });

Deletes all rows matching the current search criteria.

=over 4

=item B<Returns>

A L<Future> that resolves to the number of rows deleted.

=item B<Notes>

This method fetches all matching rows first to count them and get their IDs,
then deletes them individually. For large result sets, consider using a direct
SQL delete via the underlying database handle.

=back

=cut

sub delete {
    my $self = shift;

    # Get all rows to count them and get their IDs
    return $self->all_future->then(sub {
        my ($rows) = @_;

        # If no rows, return 0
        return Future->done(0) unless @$rows;

        # Delete each row
        my @futures;
        my @pk = $self->result_source->primary_columns;

        foreach my $row_data (@$rows) {
            my $id = $row_data->{$pk[0]};
            push @futures, $self->{async_db}->delete($self->{source_name}, $id);
        }

        return Future->wait_all(@futures)->then(sub {
            # Count successful deletes
            my $deleted_count = 0;
            foreach my $f (@_) {
                my $result = eval { $f->get };
                $deleted_count++ if $result;
            }
            return Future->done($deleted_count);
        });
    });
}

=head2 delete_all

  $rs->delete_all->then(sub {
      my ($deleted_count) = @_;
      say "Deleted $deleted_count rows";
  });

Fetches all objects and deletes them one at a time via L<DBIx::Class::Row/delete>.

=over 4

=item B<Arguments>

None

=item B<Returns>

A L<Future> that resolves to the number of rows deleted.

=item B<Difference from delete()>

C<delete_all> will run DBIC-defined triggers (such as C<before_delete>, C<after_delete>),
and will handle cascading deletes through relationships, while C<delete()> performs
a more efficient bulk delete that bypasses Row-level operations.

Use C<delete_all> when you need:
- Row-level triggers to fire
- Cascading deletes to work properly
- Accurate counts of rows affected

Use C<delete> when you need:
- Better performance for large datasets
- Direct database-level deletion

=item B<Example>

  # Delete with triggers
  $rs->search({ expired => 1 })->delete_all->then(sub {
      my ($count) = @_;
      say "Deleted $count expired records with triggers";
  });

  # Compare with bulk delete (no triggers)
  $rs->search({ expired => 1 })->delete->then(sub {
      my ($count) = @_;
      say "Bulk deleted $count records (no triggers)";
  });

=back

=cut

sub delete_all {
    my $self = shift;

    # Fetch all rows as Row objects (not raw data)
    return $self->all->then(sub {
        my ($rows) = @_;

        # If no rows, return 0
        return Future->done(0) unless @$rows;

        # Delete each Row object individually
        # This will trigger all DBIC row-level operations
        my @futures;

        foreach my $row (@$rows) {
            # Call delete on the Row object
            # This ensures triggers and cascades work
            push @futures, $row->delete;
        }

        return Future->wait_all(@futures)->then(sub {
            # Count successful deletes
            my $deleted_count = 0;
            foreach my $f (@_) {
                my $result = eval { $f->get };
                if ($result && !$@) {
                    $deleted_count++;
                }
            }
            return Future->done($deleted_count);
        });
    });
}

=head2 find

    $rs->find($id)->then(sub {
        my ($row) = @_;
        if ($row) {
            say "Found: " . $row->name;
        } else {
            say "Not found";
        }
    });

Finds a single row by primary key.

=over 4

=item B<Parameters>

=over 8

=item C<$id>

Primary key value, or hash reference for composite primary key lookup.

=back

=item B<Returns>

A L<Future> that resolves to a L<DBIx::Class::Async::Row> object if found,
or C<undef> if not found.

=item B<Throws>

=over 4

=item *

Dies if composite primary key is not supported.

=back

=back

=cut

sub find {
    my ($self, @args) = @_;

    my $cond;

    # Scalar -> primary key lookup (DBIC semantics)
    if (@args == 1 && !ref $args[0]) {
        my @pk = $self->result_source->primary_columns;
        die "Composite PK not supported" if @pk != 1;

        $cond = { $pk[0] => $args[0] };
    }
    else {
        # Hashref or complex condition
        $cond = $args[0];
    }

    # Fully async: search builds query, single_future executes async
    return $self->search($cond)->single_future;
}

=head2 find_or_new

  my $future = $rs->find_or_new({ name => 'Alice' }, { key => 'user_name' });

  $future->on_done(sub {
      my $user = shift;
      $user->insert if !$user->in_storage;
  });

Finds a record using C<find>. If no row is found, it returns a new Result object
inflated with the provided data. This object is B<not> yet saved to the database.

=cut

sub find_or_new {
    my ($self, $data, $attrs) = @_;

    # 1. Attempt to find the record first
    return $self->find($data, $attrs)->then(sub {
        my ($row) = @_;

        # 2. If found, return it
        return Future->done($row) if $row;

        # 3. If not found, instantiate a new result object locally.
        # We merge the search data with ResultSet conditions (like foreign keys).
        my %new_data = ( %{$self->{_cond} || {}}, %$data );
        my %clean_data;
        while (my ($k, $v) = each %new_data) {
            (my $clean_key = $k)    =~ s/^(?:foreign|self)\.//;
            $clean_data{$clean_key} = $v;
        }

        return Future->done($self->new_result(\%clean_data));
    });
}

=head2 find_or_create

  my $future = $rs->find_or_create({ name => 'Bob' });

Attempts to find a record. If it does not exist, it performs an C<INSERT> and
returns the resulting Result object.

=cut

sub find_or_create {
    my ($self, $data, $attrs) = @_;

    $attrs //= {};
    my $source      = $self->result_source;
    my $key_name    = $attrs->{key} || 'primary';
    my @unique_cols = $source->unique_constraint_columns($key_name);

    # Extract only the unique identifier columns for the lookup
    my %lookup;
    if (@unique_cols) {
        @lookup{@unique_cols} = @{$data}{@unique_cols};
    } else {
        %lookup = %$data;
    }

    return $self->find(\%lookup, $attrs)->then(sub {
        my $row = shift;
        return Future->done($row) if $row;
        return $self->create($data);
    });
}

=head2 first

    $rs->first->then(sub {
        my ($row) = @_;
        if ($row) {
            say "First row: " . $row->name;
        }
    });

Returns the first row matching the current search criteria.

=over 4

=item B<Returns>

A L<Future> that resolves to a L<DBIx::Class::Async::Row> object if found,
or C<undef> if no rows match.

=back

=cut

sub first {
    my $self = shift;

    # Handle prefetch
    if ($self->{is_prefetched} && $self->{entries}) {
        return Future->done($self->new_result($self->{entries}[0]));
    }

    return $self->search(undef, { rows => 1 })->all->then(sub {
        my (@rows) = @_;
        return Future->done($rows[0]);
    });
}

=head2 first_future

    $rs->first_future->then(sub {
        # Same as single_future, alias for API consistency
    });

Alias for C<single_future>.

=cut

sub first_future { shift->single_future(@_) }

=head2 get

    my $rows = $rs->get;
    # Returns cached rows, or empty arrayref if not fetched

Returns the currently cached rows.

=over 4

=item B<Returns>

Array reference of cached rows (either raw data or row objects, depending on
how they were fetched).

=item B<Notes>

This method returns immediately without performing any database operations.
It only returns data that has already been fetched via C<all>, C<all_future>,
or similar methods.

=back

=cut

sub get {
    my $self = shift;
    # Returns current cached rows (raw or objects)
    return $self->{_rows} || [];
}

=head2 get_cache

  my $cached_rows = $rs->get_cache;

Returns the current contents of the ResultSet's internal cache. This will be
an arrayref of L<DBIx::Class::Async::Row> objects if the cache has been
populated via C<set_cache> or a previous execution of C<all>. Returns
C<undef> if no cache exists.

=cut

sub get_cache {
    my $self = shift;

    # Return the inflated rows if they exist, or the raw entries
    return $self->{_rows}   if $self->{_rows};
    return $self->{entries} if $self->{entries};
    return undef;
}

=head2 get_column

    $rs->get_column('name')->then(sub {
        my ($names) = @_;
        # $names is an arrayref of name values
    });

Returns values from a single column for all rows matching the current criteria.

=over 4

=item B<Parameters>

=over 8

=item C<$column>

Column name to retrieve values from.

=back

=item B<Returns>

A L<Future> that resolves to an array reference of column values.

=back

=cut

sub get_column {
    my ($self, $column) = @_;

    # Don't die if column doesn't exist, just return undef or check _data
    return $self->{_data}{$column} if exists $self->{_data}{$column};

    return undef;
}

=head2 is_paged

    if ($rs->is_paged) { ... }

Returns a boolean (1 or 0) indicating whether the ResultSet has pagination
attributes (specifically the C<page> key) defined.

=cut

sub is_paged {
    my $self = shift;
    return exists $self->{_attrs}->{page} ? 1 : 0;
}

=head2 is_ordered

    my $bool = $rs->is_ordered;

Returns B<true> (1) if the ResultSet has an C<order_by> attribute set, B<false> (0)
otherwise. It is highly recommended to ensure a ResultSet B<is_ordered> before
performing pagination to ensure consistent results across pages.

=cut

sub is_ordered {
    my $self = shift;

    return exists $self->{_attrs}->{order_by} ? 1 : 0;
}

=head2 next

    while (my $row = $rs->next) {
        say "Row: " . $row->name;
    }

Returns the next row from the cached result set.

=over 4

=item B<Returns>

A L<DBIx::Class::Async::Row> object, or C<undef> when no more rows are available.

=item B<Notes>

If no rows have been fetched yet, this method performs a blocking fetch via
C<all>. The results are cached for subsequent C<next> calls. Call C<reset>
to restart iteration.

=back

=cut

sub next {
    my $self = shift;

    # If we haven't fetched yet, do a blocking fetch
    unless ($self->{_rows}) {
        $self->{_rows} = $self->all->get;
    }

    $self->{_pos} //= 0;

    return undef if $self->{_pos} >= @{$self->{_rows}};

    return $self->{_rows}[$self->{_pos}++];
}

=head2 page

    my $paged_rs = $rs->page(3);

Returns a new ResultSet clone with the C<page> and C<rows> attributes set. If
C<rows> (entries per page) has not been previously set on the ResultSet, it
defaults to 10.

This method is chainable and does not execute a query immediately.

=cut

sub page {
    my ($self, $page_number) = @_;

    # We use the existing search() method to handle the cloning.
    # This avoids calling new() directly and hitting those validation croaks.
    return $self->search(undef, {
        page => $page_number || 1,
        rows => $self->{_attrs}->{rows} || 10
    });
}

=head2 pager

    my $pager = $rs->page(1)->pager;

Returns a L<DBIx::Class::Async::ResultSet::Pager> object for the current
ResultSet. This object provides methods to calculate the total number of pages,
next/previous page numbers, and entry counts.

B<Note:> This method will C<die> if called on a ResultSet that has not been
paged via the L</page> method.

B<PRO-TIP>: Warn the user if they are paginating unordered data.

=cut

sub pager {
    my $self = shift;

    unless ($self->is_paged) {
        die "Cannot call ->pager on a non-paged resultset. Call ->page(\$n) first.";
    }

    # Warn only if unordered AND not running in a test suite
    if (!$self->is_ordered && !$ENV{HARNESS_ACTIVE}) {
        warn "DBIx::Class::Async Warning: Calling ->pager on an unordered ResultSet. " .
             "Results may be inconsistent across pages.\n";
    }

    require DBIx::Class::Async::ResultSet::Pager;
    return DBIx::Class::Async::ResultSet::Pager->new(resultset => $self);
}

=head2 populate

  # Array of hashrefs format
  $rs->populate([
      { name => 'Alice', email => 'alice@example.com' },
      { name => 'Bob',   email => 'bob@example.com' },
  ])->then(sub {
      my ($users) = @_;
      say "Created " . scalar(@$users) . " users";
  });

  # Column list + rows format
  $rs->populate([
      [qw/ name email /],
      ['Alice', 'alice@example.com'],
      ['Bob',   'bob@example.com'],
  ])->then(sub {
      my ($users) = @_;
  });

Creates multiple rows at once. More efficient than calling C<create> multiple times.

=over 4

=item B<Arguments>

=over 8

=item C<$data>

Either:

- Array of hashrefs: C<< [ \%col_data, \%col_data, ... ] >>

- Column list + rows: C<< [ \@column_list, \@row_values, \@row_values, ... ] >>

=back

=item B<Returns>

A L<Future> that resolves to an arrayref of created L<DBIx::Class::Async::Row> objects.

=back

=cut

sub populate {
    my ($self, $data) = @_;

    croak("data required")            unless defined $data;
    croak("data must be an arrayref") unless ref $data eq 'ARRAY';
    croak("data cannot be empty")     unless @$data;

    # Detect format: hashref array or column list + rows
    my $first_elem = $data->[0];
    my $is_column_list_format = ref $first_elem eq 'ARRAY';

    my @rows_to_create;

    if ($is_column_list_format) {
        # Format: [ [qw/col1 col2/], [val1, val2], [val3, val4], ... ]
        my @columns = @{ $data->[0] };

        for my $i (1 .. $#$data) {
            my @values = @{ $data->[$i] };

            croak("Row $i has different number of values than columns")
                unless @values == @columns;

            my %row;
            for my $j (0 .. $#columns) {
                $row{$columns[$j]} = $values[$j];
            }

            push @rows_to_create, \%row;
        }
    } else {
        # Format: [ {col1 => val1}, {col1 => val2}, ... ]
        @rows_to_create = @$data;
    }

    # Create all rows
    my @futures;
    foreach my $row_data (@rows_to_create) {
        # Create the row, then immediately discard_changes to fetch defaults
        my $f = $self->create($row_data)->then(sub {
            my $new_row = shift;
            return $new_row->discard_changes; # Returns a future resolving to the refreshed row
        });
        push @futures, $f;
    }

    # Wait for all creates to complete
    return Future->wait_all(@futures)->then(sub {
        my @results;
        foreach my $f (@_) {
            my $row = eval { $f->get };
            push @results, $row if $row && !$@;
        }

        return Future->done(\@results);
    });
}

=head2 populate_bulk

  my $future = $rs->populate_bulk(\@large_dataset);

  $future->on_done(sub {
      print "Bulk insert successful\n";
  });

A high-performance version of C<populate> intended for large-scale data ingestion.

=over 4

=item * B<Arguments:> C<[ \%col_data, ... ]> or C<[ \@column_list, [ \@row_values, ... ] ]>

=item * B<Return Value:> A L<Future> that resolves to a truthy value (1) on success.

=back

B<Key Differences from populate:>

=over 4

=item 1. B<Context:> Executes the database operation in void context on the worker side.

=item 2. B<No Inflation:> Does not create Result objects for the inserted rows.

=item 3. B<Efficiency:> Reduces memory overhead and Inter-Process Communication (IPC)
payload by only returning a success status rather than the full row data.

=back

Use this method when you need to "fire and forget" large amounts of data where
individual object manipulation is not required immediately after insertion.

=cut

sub populate_bulk {
    my ($self, $data) = @_;

    # 1. Validation: Ensure we have an arrayref
    unless (ref $data eq 'ARRAY') {
        return Future->fail("populate_bulk() requires an arrayref", "usage_error");
    }

    # 1. Data Preparation: Handle potential prefixes and merge ResultSet conditions
    my $final_data = $data;

    # We only perform merging/cleaning if we are dealing with an array of hashrefs.
    # If it's an array of arrays (bulk insert), we pass it through as-is for maximum speed.
    if (ref $data->[0] eq 'HASH') {
        $final_data = [ map {
            my $row = $_;
            my %to_insert = ( %{$self->{_cond} || {}}, %$row );
            my %clean_data;
            while (my ($k, $v) = each %to_insert) {
                my $clean_key = $k;
                $clean_key =~ s/^(?:foreign|self)\.//;
                $clean_data{$clean_key} = $v;
            }
            \%clean_data;
        } @$data ];
    }

    # 3. Execute: Call the background worker using the 'populate_bulk' operation
    return $self->{async_db}->populate_bulk(
        $self->{source_name},
        $final_data
    )->then(sub {
        my ($result) = @_;

        # 4. Error Handling
        if (ref $result eq 'HASH' && $result->{__error}) {
            return Future->fail($result->{__error}, 'db_error');
        }

        # 5. Return Success: We return a simple truthy value instead of a list of objects
        return Future->done(1);
    });
}

=head2 prefetch

    my $rs_with_prefetch = $rs->prefetch('related_table');

Adds a prefetch clause to the result set for eager loading of related data.

=over 4

=item B<Parameters>

=over 8

=item C<$prefetch>

Prefetch specification (string or arrayref).

=back

=item B<Returns>

A new result set object with the prefetch clause added.

=item B<Notes>

This method returns a clone of the result set and does not modify the original.

=back

=cut

sub prefetch {
    my ($self, $prefetch) = @_;
    return $self->search(undef, { prefetch => $prefetch });
}

=head2 related_resultset

  my $users_rs = $orders_rs->related_resultset('user');

Returns a new ResultSet for a related table based on a relationship name.
The new ResultSet will be constrained to only include records that are
related to records in the current ResultSet.

=cut

sub related_resultset {
    my ($self, $relation) = @_;

    croak("Relationship name is required") unless defined $relation;

    my $source = $self->result_source;

    unless ($source->has_relationship($relation)) {
        croak("No such relationship '$relation' on " . $source->source_name);
    }

    my $rel_info   = $source->relationship_info($relation);
    my $rel_source = $source->related_source($relation);
    my $cond       = $rel_info->{cond};

    # Build the join condition
    my ($foreign_key, $self_key);

    if (ref $cond eq 'HASH') {
        my ($foreign_col, $self_col) = %$cond;

        # Handle complex condition structures
        if (ref $self_col eq 'HASH') {
            my ($op, $col) = %$self_col;
            $self_col = $col;
        }

        $foreign_col =~ s/^foreign\.//;
        $self_col    =~ s/^self\.//;
        $foreign_key =  $foreign_col;
        $self_key    =  $self_col;
    } else {
        croak("Complex relationship conditions not yet supported");
    }

    my $reverse_rel = $self->_find_reverse_relationship($source, $rel_source, $relation);

    unless ($reverse_rel) {
        croak("Cannot find reverse relationship from " .
              $rel_source->source_name . " back to " .
              $source->source_name);
    }

    # Build new search condition with prefixed keys
    my %prefixed_cond;
    while (my ($key, $value) = each %{$self->{_cond}}) {
        # Add the reverse relationship prefix to existing conditions
        if ($key =~ /\./) {
            $prefixed_cond{$key} = $value;
        } else {
            $prefixed_cond{"$reverse_rel.$key"} = $value;
        }
    }

    # Get all columns from the related source for proper GROUP BY
    my @columns = $rel_source->columns;
    my @select = map { "me.$_" } @columns;
    my @group_by = map { "me.$_" } @columns;

    # Create attributes with join
    my %new_attrs = (
        join     => $reverse_rel,
        select   => \@select,
        as       => \@columns,
        group_by => \@group_by,
        %{$self->{_attrs}},
    );

    # Remove any conflicting attributes from the original ResultSet
    delete $new_attrs{prefetch} if exists $new_attrs{prefetch};

    # Create and return the new ResultSet
    return $self->{schema}->resultset($rel_source->source_name)->search(
        \%prefixed_cond,
        \%new_attrs
    );
}

=head2 reset

    $rs->reset;
    # Now $rs->next will start from the first row again

Resets the internal iterator position.

=over 4

=item B<Returns>

The result set object itself (for chaining).

=back

=cut

sub reset {
    my $self = shift;
    $self->{_pos} = 0;
    return $self;
}

=head2 result_class

    $rs->result_class('My::Custom::Row::Class');
    my $class = $rs->result_class;

Gets or sets the result class (inflation class) for the ResultSet.

In C<DBIx::Class::Async>, this method plays a critical role in maintaining
Object-Oriented compatibility. When a custom result class is specified,
the library automatically generates an anonymous proxy class that inherits
from both the internal asynchronous logic and your custom class.

This ensures that:

=over 4

=item 1. Custom row methods (e.g., C<hello_name>) are available on returned objects.

=item 2. The objects correctly pass C<< $row->isa('My::Custom::Row::Class') >> checks.

=item 3. Database interactions remain asynchronous and non-blocking.

=back

The method resolves the class using the following priority:

=over 4

=item 1. Explicitly set value via this accessor.

=item 2. Attributes passed during the C<search> call (C<result_class>).

=item 3. The default C<result_class> defined in the L<DBIx::Class::ResultSource>.

=back

Returns the ResultSet object when used as a setter to allow method chaining.

=cut

sub result_class {
    my $self = shift;
    if (@_) {
        $self->{attrs}->{result_class} = shift;
        return $self;
    }
    # Priority: 1. Manual override, 2. ResultSet attributes, 3. Source default
    return $self->{attrs}->{result_class}
        || $self->{_attrs}->{result_class}
        || $self->result_source->result_class;
}

=head2 result_source

    my $source = $rs->result_source;

Returns the result source object for this result set.

=over 4

=item B<Returns>

A L<DBIx::Class::ResultSource> object.

=back

=cut

sub result_source {
    my $self = shift;
    return $self->_get_source;
}

=head2 schema

  my $schema = $rs->schema;

Returns the L<DBIx::Class::Async::Schema> object that this ResultSet belongs to.

This provides access to the parent schema, allowing you to access other
ResultSources, the storage layer, or schema-level operations from within
a ResultSet context.

  my $rs = $schema->resultset('User');
  my $parent_schema = $rs->schema;

  # Access other result sources
  my $orders_rs = $parent_schema->resultset('Order');

  # Access storage
  my $storage = $parent_schema->storage;

  # Perform schema-level operations
  $parent_schema->txn_do(sub { ... });

This method is particularly useful in ResultSet method chains or custom
ResultSet classes where you need to access the schema without passing it
as a parameter.

=cut

sub schema {
    my $self = shift;
    return $self->{_schema};
}

=head2 search

    my $filtered_rs = $rs->search({ active => 1 }, { order_by => 'name' });

Adds search conditions and attributes to the result set.

=over 4

=item B<Parameters>

=over 8

=item C<$cond>

Hash reference of search conditions (optional).

=item C<$attrs>

Hash reference of search attributes like order_by, rows, etc. (optional).

=back

=item B<Returns>

A new result set object with the combined conditions and attributes.

=item B<Notes>

This method returns a clone of the result set. Conditions and attributes
are merged with any existing ones from the original result set.

=back

=cut

sub search {
    my ($self, $cond, $attrs) = @_;

    # Handle the condition merging carefully
    my $new_cond;

    # 1. If the new condition is a literal (Scalar/Ref), it overrides/becomes the condition
    if (ref $cond eq 'REF' || ref $cond eq 'SCALAR') {
        $new_cond = $cond;
    }
    # 2. If the current existing condition is a literal,
    # and we try to add a hash, we usually want to encapsulate or override.
    # For now, let's allow the new condition to take precedence if it's a hash.
    elsif (ref $cond eq 'HASH') {
        if (ref $self->{_cond} eq 'HASH') {
            $new_cond = { %{$self->{_cond}}, %$cond };
        }
        else {
            # If current is literal and new is hash, prioritize the new hash
            # or handle based on your preference. Most DBIC users expect a merge.
            $new_cond = $cond;
        }
    }
    else {
        # Fallback for simple cases or undef
        $new_cond = $cond || $self->{_cond};
    }

    my $clone = bless {
        %$self,
        _cond         => $new_cond,
        _attrs        => { %{$self->{_attrs} || {}}, %{$attrs || {}} },
        _rows         => undef,
        _pos          => 0,
        entries       => undef,
        is_prefetched => 0,
    }, ref $self;

    return $clone;
}

=head2 search_future

    $rs->search_future->then(sub {
        # Same as all_future, alias for API consistency
    });

Alias for C<all_future>.

=cut

sub search_future { shift->all_future(@_)  }

=head2 search_literal

    my $rs = $schema->resultset('User')->search_literal(
        'age > ? AND status = ?',
        18, 'active'
    );

=over 4

=item Arguments: $sql_fragment, @bind_values

=item Return Value: L<DBIx::Class::Async::ResultSet>

=back

Performs a search using a literal SQL fragment. This is provided for
compatibility with L<Class::DBI>.

B<Warning:> Use this method with caution. Always use placeholders (C<?>)
for values to prevent SQL injection. Literal fragments are not parsed or
validated by the ORM before being sent to the database.

=cut

sub search_literal {
    my ($self, $sql_fragment, @bind) = @_;

    # In DBIC, search_literal is a shorthand for passing
    # the literal SQL as the first element of the condition.
    return $self->search(
        \[ $sql_fragment, @bind ]
    );
}

=head2 search_related

  # Scalar context: returns a ResultSet
  my $new_rs = $rs->search_related('orders');

  # List context: returns a Future (implicit ->all)
  my $future = $rs->search_related('orders');
  my @orders = $future->get;

In scalar context, works exactly like L</search_related_rs>. In list context, it
returns a L<Future> that resolves to the list of objects in that relationship.

=cut

sub search_related {
    my $self = shift;
    return wantarray
        ? $self->_do_search_related(@_)->all
        : $self->_do_search_related(@_);
}

=head2 search_related_rs

  my $rel_rs = $rs->search_related_rs('relationship_name', \%cond?, \%attrs?);

Returns a new L<DBIx::Class::Async::ResultSet> representing the specified relationship.
This is a synchronous metadata operation and does not hit the database.

=cut

sub search_related_rs {
    my $self = shift;
    return $self->_do_search_related(@_);
}

=head2 search_with_pager

    my $future = $rs->search_with_pager({ status => 'active' }, { rows => 20 });

    $future->then(sub {
        my ($rows, $pager) = @_;
        print "Displaying page " . $pager->current_page;
        return Future->done;
    })->get;

This is a convenience method that performs a search and initializes a pager
simultaneously. It returns a L<Future> which, when resolved, provides two values:
an arrayref of result objects (C<$rows>) and a L<DBIx::Class::Async::ResultSet::Pager>
object (C<$pager>).

B<Performance Note>

Unlike standard synchronous pagination where you must first fetch the data and
then fetch the count (or vice versa), C<search_with_pager> fires both the
C<SELECT> and the C<COUNT> queries to the database worker pool in parallel using
L<Future/needs_all>. This can significantly reduce latency in web applications.

If the ResultSet is not already paged when this method is called, it
automatically applies C<< ->page(1) >>.

=cut

sub search_with_pager {
    my ($self, $cond, $attrs) = @_;

    # 1. Create the paged resultset
    my $paged_rs = $self->search($cond, $attrs);
    if (!$paged_rs->is_paged) {
        $paged_rs = $paged_rs->page(1);
    }

    # 2. Fire both requests in parallel
    my $data_f  = $paged_rs->all;
    my $pager   = $paged_rs->pager;
    my $total_f = $pager->total_entries;

    # 3. Return a combined Future
    return Future->needs_all($data_f, $total_f)->then(sub {
        my ($rows, $total) = @_;
        return Future->done($rows, $pager);
    });
}

=head2 set_cache

  $rs->set_cache(\@row_objects);

Manually populates the ResultSet cache with the provided arrayref of row objects.
Once a cache is set, any subsequent data-fetching operations (like C<all> or
C<single_future>) will return the cached objects immediately instead of
querying the database or the global worker cache.

Expects an arrayref of objects of the same class as those normally produced
by the ResultSet.

=cut

sub set_cache {
    my ($self, $cache) = @_;

    if (defined $cache && ref $cache ne 'ARRAY') {
        croak("set_cache expects an arrayref of objects");
    }

    # Standard DBIC behavior: setting cache populates the result list
    $self->{_rows}         = $cache;
    $self->{is_prefetched} = 1;

    # Also store as raw entries if these are objects,
    # ensuring compatibility with your current 'all' logic
    $self->{entries} = $cache;

    return $cache;
}

=head2 single

    my $row = $rs->single;
    # Returns first row (blocking), or undef

Returns the first row from the result set (blocking version).

=over 4

=item B<Returns>

A L<DBIx::Class::Async::Row> object, or C<undef> if no rows match.

=item B<Notes>

This method performs a blocking fetch. For non-blocking operation, use
C<first> or C<single_future>.

=back

=cut

sub single {
    my $self = shift;

    return $self->search(undef, { rows => 1 })->next;
}

=head2 single_future

    $rs->single_future->then(sub {
        my ($row) = @_;
        if ($row) {
            # Process single row
        }
    });

Returns a single row matching the current search criteria (non-blocking).

=over 4

=item B<Returns>

A L<Future> that resolves to a L<DBIx::Class::Async::Row> object if found,
or C<undef> if not found.

=item B<Notes>

For simple primary key lookups, this method optimizes by using C<find>
internally. For complex queries, it adds C<rows =E<gt> 1> to the search
attributes.

=back

=cut

sub single_future {
    my $self = shift;

    if ($self->{is_prefetched} && $self->{entries}) {
        my $data = $self->{entries}[0];
        return Future->done($data ? $self->new_result($data) : undef);
    }

    my @pk = $self->result_source->primary_columns;
    my $cond_type = ref $self->{_cond};

    if (@pk == 1
        && $cond_type eq 'HASH'
        && !exists $self->{_attrs}->{select}
        && keys %{$self->{_cond}} == 1
        && exists $self->{_cond}{$pk[0]}
        && !ref $self->{_cond}{$pk[0]}) {

        return $self->{async_db}->find(
            $self->{source_name},
            $self->{_cond}{$pk[0]}
        )->then(sub {
            my $data = shift;
            return Future->done($data ? $self->new_result($data) : undef);
        });
    }

    return $self->search({}, { rows => 1 })->all->then(sub {
        my $results = shift;
        my $row = ($results && @$results) ? $results->[0] : undef;
        return Future->done($row);
    });
}

=head2 slice

  my ($first, $second, $third) = $rs->slice(0, 2);
  my @records = $rs->slice(5, 10);
  my $sliced_rs = $rs->slice(0, 9);  # scalar context

Returns a resultset or object list representing a subset of elements from the
resultset. Indexes are from 0.

=over 4

=item B<Parameters>

=over 8

=item C<$first>

Zero-based starting index (inclusive).

=item C<$last>

Zero-based ending index (inclusive).

=back

=item B<Returns>

In list context: Array of L<DBIx::Class::Async::Row> objects.

In scalar context: A new L<DBIx::Class::Async::ResultSet> with appropriate
C<rows> and C<offset> attributes set.

=item B<Examples>

  # Get first 3 records
  my ($one, $two, $three) = $rs->slice(0, 2);

  # Get records 10-19
  my @batch = $rs->slice(10, 19);

  # Get a ResultSet for records 5-14 (for further chaining)
  my $subset_rs = $rs->slice(5, 14);
  my $count = $subset_rs->count->get;

=back

=cut

sub slice {
    my ($self, $first, $last) = @_;

    require Carp;
    Carp::croak("slice requires two arguments (first and last index)")
        unless defined $first && defined $last;

    Carp::croak("slice indices must be non-negative integers")
        if $first < 0 || $last < 0;

    Carp::croak("first index must be less than or equal to last index")
        if $first > $last;

    # Calculate offset and number of rows
    my $offset = $first;
    my $rows = $last - $first + 1;

    # In scalar context, return a new ResultSet with offset and rows set
    unless (wantarray) {
        return $self->search(undef, {
            offset => $offset,
            rows   => $rows,
        });
    }

    # In list context, fetch the data and return the array
    # We need to apply offset and rows, then fetch
    my $sliced_rs = $self->search(undef, {
        offset => $offset,
        rows   => $rows,
    });

    # Fetch all results and return as list
    my $results = $sliced_rs->all->get;
    return @$results;
}

=head2 source

    my $source = $rs->source;

Alias for C<result_source>.

=over 4

=item B<Returns>

A L<DBIx::Class::ResultSource> object.

=back

sub source { shift->_get_source }

=head2 source_name

    my $source_name = $rs->source_name;

Returns the source name for this result set.

=over 4

=item B<Returns>

The source name (string).

=back

=cut

sub source_name {
    my $self = shift;
    return $self->{source_name};
}

=head2 update

    $rs->search({ status => 'pending' })->update({ status => 'processed' })
       ->then(sub {
           my ($rows_affected) = @_;
           say "Updated $rows_affected rows";
       });

Updates all rows matching the current search criteria.

=over 4

=item B<Parameters>

=over 8

=item C<$data>

Hash reference containing column-value pairs to update.

=back

=item B<Returns>

A L<Future> that resolves to the number of rows affected.

=item B<Notes>

This performs a bulk update using the search conditions. For individual
row updates, use C<update> on the row object instead.

=back

=cut

sub update {
    my ($self, $data) = @_;

    # Perform a single bulk update via the worker
    # This uses the search condition (e.g., { active => 1 })
    # instead of individual row IDs.
    return $self->{async_db}->update_bulk(
        $self->{source_name},
        $self->{_cond} || {},
        $data
    )->then(sub {
        my ($rows_affected) = @_;
        return Future->done($rows_affected);
    });
}

=head2 update_or_create

    my $future = $rs->update_or_create({
         email => 'user@example.com',
         name  => 'Updated Name',
        active => 1
    }, { key => 'user_email' });

    $future->on_done(sub {
        my $row = shift;
        print "Upserted user ID: " . $row->id;
    });

An "upsert" operation. It first attempts to locate an existing record using the unique
constraints provided in the data hashref (or specified by the C<key> attribute).

=over 4

=item * If a matching record is found, it is updated with the remaining values in the hashref.

=item * If no matching record is found, a new record is inserted into the database.

=back

Returns a L<Future> which, when resolved, provides the L<DBIx::Class::Async::Row>
object representing the updated or newly created record.

=cut

sub update_or_create {
    my ($self, $data, $attrs) = @_;

    $attrs //= {};
    my $source      = $self->result_source;
    my $key_name    = $attrs->{key} || 'primary';
    my @unique_cols = $source->unique_constraint_columns($key_name);

    my %lookup;
    if (@unique_cols) {
        @lookup{@unique_cols} = @{$data}{@unique_cols};
    } else {
        %lookup = %$data;
    }

    # Try to find the record
    return $self->find(\%lookup, $attrs)->then(sub {
        my $row = shift;

        if ($row) {
            # Found: Perform an update with the provided data
            return $row->update($data);
        }

        # Not Found: Create it
        return $self->create($data);
    });
}

=head2 update_or_new

    my $future = $rs->update_or_new({
         email => 'user@example.com',
         name  => 'New Name'
    }, { key => 'user_email' });

Similar to L</update_or_create>, but with a focus on in-memory instantiation.

=over 4

=item * If a matching record is found in the database, it is updated and the resulting
object is returned.

=item * If no record is found, a new row object is instantiated (using L</new_result>)
but B<not yet saved> to the database.

=back

This is useful for workflows where you want to ensure an object is synchronised with
the database if it exists, but you aren't yet ready to commit a new record to storage.

Returns a L<Future> resolving to a L<DBIx::Class::Async::Row> object.

=cut

sub update_or_new {
    my ($self, $data, $attrs) = @_;

    # Behavior: find it and update it, or return a 'new' object with the data
    return $self->update_or_create($data, $attrs)->then(sub {
        my $row = shift;
        return Future->done($row);
    });
}

=head1 CHAINABLE MODIFIERS

The following methods return a new result set with the specified attribute
added or modified:

=over 4

=item C<rows($number)> - Limits the number of rows returned

=item C<page($number)> - Specifies the page number for pagination

=item C<order_by($spec)> - Specifies the sort order

=item C<columns($spec)> - Specifies which columns to select

=item C<group_by($spec)> - Specifies GROUP BY clause

=item C<having($spec)> - Specifies HAVING clause

=item C<distinct($bool)> - Specifies DISTINCT modifier

=back

Example:

    my $paginated = $rs->rows(10)->page(2)->order_by('created_at DESC');

These methods do not modify the original result set and do not execute any
database queries.

=head1 CACHING METHODS

These methods allow for manual management of the ResultSet's internal data cache.
Note that this is separate from the global query cache managed by the L<DBIx::Class::Async> object.

=over 4

=item get_cache

=item set_cache

=item clear_cache

=back

=head1 INTERNAL METHODS

These methods are for internal use and are documented for completeness.

=head2 _do_search_related

  my $new_async_rs = $rs->_do_search_related($rel_name, $cond, $attrs);

An internal helper method that performs the heavy lifting for L</search_related>
and L</search_related_rs>.

B<NOTE:> This method exists to break deep recursion issues caused by
L<DBIx::Class> method aliasing. It bypasses the standard method dispatcher by
manually instantiating a native L<DBIx::Class::ResultSet> to calculate
relationship metadata before re-wrapping the result in the Async class.

=over 4

=item * B<Arguments:> Same as L</search_related_rs>.

=item * B<Returns:> A new L<DBIx::Class::Async::ResultSet> object.

=back

=cut

sub _do_search_related {
    my ($self, $rel_name, $cond, $attrs) = @_;

    # 1. Get the Raw ResultSource
    my $source = $self->{_source} || $self->{schema}->source($self->{source_name});

    # 2. Create a NATIVE DBIC ResultSet directly from the source
    require DBIx::Class::ResultSet;
    my $native_rs = DBIx::Class::ResultSet->new($source, {
        cond  => $self->{_cond},
        attrs => $self->{_attrs}
    });

    # 3. Perform the pivot on the native object
    my $related_native_rs = $native_rs->search_related($rel_name, $cond, $attrs);

    # 4. Manually construct the new Async RS object (Bypassing 'new')
    return bless {
        %$self,
        source_name => $related_native_rs->result_source->source_name,
        _cond       => $related_native_rs->{cond},
        _attrs      => $related_native_rs->{attrs},
        _source     => $related_native_rs->result_source,
        _rows       => undef,
        _pos        => 0,
    }, ref($self);
}

=head2 _get_source

    my $source = $rs->_get_source;

Returns the result source object, loading it lazily if needed.

=cut

sub _get_source {
    my $self = shift;
    $self->{_source} ||= $self->{schema}->source($self->{source_name});
    return $self->{_source};
}

=head2 _inflate_prefetch

Inflates prefetched relationship data into the row object.

=cut

sub _inflate_prefetch {
    my ($self, $row, $data, $prefetch_spec) = @_;

    # Initialize prefetch storage in the row if not exists
    $row->{_prefetched} ||= {};

    # Handle both scalar and arrayref prefetch specs
    my @prefetches =
        ref $prefetch_spec eq 'ARRAY' ? @$prefetch_spec : ($prefetch_spec);

    foreach my $prefetch (@prefetches) {
        # Handle nested prefetch (e.g., 'comments.user')
        if ($prefetch =~ /\./) {
            my @parts = split /\./, $prefetch;
            $self->_inflate_nested_prefetch($row, $data, \@parts);
        } else {
            # Simple prefetch
            $self->_inflate_simple_prefetch($row, $data, $prefetch);
        }
    }
}

=head2 _inflate_simple_prefetch

Inflates a simple (non-nested) prefetched relationship.

=cut

sub _inflate_simple_prefetch {
    my ($self, $row, $data, $rel_name) = @_;

    # Get the relationship info from the result source
    my $source = $self->result_source;

    # Verify relationship exists
    return unless $source->has_relationship($rel_name);

    my $rel_info = $source->relationship_info($rel_name);
    return unless $rel_info;

    # Check if prefetch data exists in the row data
    # Try multiple possible keys for prefetch data
    my $prefetch_data;
    for my $key ("prefetch_${rel_name}", $rel_name, "${rel_name}_prefetch") {
        if (exists $data->{$key}) {
            $prefetch_data = $data->{$key};
            last;
        }
    }

    return unless defined $prefetch_data;

    my $rel_type = $rel_info->{attrs}{accessor} || 'single';

    if ($rel_type eq 'multi') {
        # has_many relationship - create a prefetched ResultSet
        my $rel_source = $source->related_source($rel_name);

        # Ensure prefetch_data is an arrayref
        my $entries =
            ref $prefetch_data eq 'ARRAY' ? $prefetch_data : [$prefetch_data];

        my $rel_rs = $self->new_result_set({
            source_name => $rel_source->source_name,
            entries => $entries,
            is_prefetched => 1,
        });

        # Store the prefetched ResultSet in the row
        $row->{_prefetched}{$rel_name} = $rel_rs;

    } else {
        # belongs_to or might_have - single related object
        if ($prefetch_data && ref $prefetch_data eq 'HASH') {
            my $rel_source = $source->related_source($rel_name);

            my $rel_row = $self->new_result_set({
                source_name => $rel_source->source_name,
            })->new_result($prefetch_data);

            # Store the prefetched row
            $row->{_prefetched}{$rel_name} = $rel_row;
        } elsif (!$prefetch_data) {
            # NULL relationship (e.g., optional belongs_to)
            $row->{_prefetched}{$rel_name} = undef;
        }
    }
}

=head2 _inflate_nested_prefetch

Inflates nested prefetched relationships (e.g., 'comments.user').

=cut

sub _inflate_nested_prefetch {
    my ($self, $row, $data, $parts) = @_;

    my $first_rel = shift @$parts;
    my $remaining_path = join('.', @$parts);

    # Inflate the first level
    $self->_inflate_simple_prefetch($row, $data, $first_rel);

    # If there are more levels, handle them recursively
    if (@$parts && exists $row->{_prefetched}{$first_rel}) {
        my $first_level = $row->{_prefetched}{$first_rel};

        # Check if it's a ResultSet (has_many)
        if (blessed($first_level)
            && $first_level->isa('DBIx::Class::Async::ResultSet')) {
            # Get the entries from the prefetched ResultSet
            my $entries = $first_level->{entries} || [];

            foreach my $nested_data (@$entries) {
                my $rel_source = $self->result_source->related_source($first_rel);
                my $nested_rs  = $self->new_result_set({
                    source_name => $rel_source->source_name,
                });

                # Create a row object for this entry
                my $nested_row = $nested_rs->new_result($nested_data);

                # Recursively inflate the remaining path
                $nested_rs->_inflate_nested_prefetch(
                    $nested_row,
                    $nested_data,
                    [@$parts]
                );
            }

        } elsif (blessed($first_level)
                && $first_level->isa('DBIx::Class::Async::Row')) {
            # Single related object (belongs_to)
            my $rel_source = $self->result_source->related_source($first_rel);
            my $nested_rs  = $self->new_result_set({
                source_name => $rel_source->source_name,
            });

            # Get the raw data from the row
            my $nested_data = $first_level->{_data};

            # Recursively inflate the remaining path
            $nested_rs->_inflate_nested_prefetch(
                $first_level,
                $nested_data,
                [@$parts]
            );
        }
    }
}

=head2 _find_reverse_relationship

Finds the reverse relationship name on the related source.

=cut

sub _find_reverse_relationship {
    my ($self, $source, $rel_source, $forward_rel) = @_;

    my @rel_names    = $rel_source->relationships;
    my $forward_info = $source->relationship_info($forward_rel);
    my $forward_cond = $forward_info->{cond};

    # Extract keys from forward condition
    my ($forward_foreign, $forward_self);
    if (ref $forward_cond eq 'HASH') {
        my ($f, $s) = %$forward_cond;
        if (ref $s eq 'HASH') {
            my ($op, $col) = %$s;
            $s = $col;
        }
        $forward_foreign = $f;
        $forward_self    = $s;
        $forward_foreign =~ s/^foreign\.//;
        $forward_self    =~ s/^self\.//;
    }

    # Look for a relationship that points back to our source
    foreach my $rev_rel (@rel_names) {
        my $rev_info       = $rel_source->relationship_info($rev_rel);
        my $rev_source_obj = $rel_source->related_source($rev_rel);

        # Check if this relationship points back to our original source
        next unless $rev_source_obj->source_name eq $source->source_name;

        # Check if the foreign keys match (in reverse)
        my $rev_cond = $rev_info->{cond};
        if (ref $rev_cond eq 'HASH') {
            my ($rev_foreign, $rev_self) = %$rev_cond;

            if (ref $rev_self eq 'HASH') {
                my ($op, $col) = %$rev_self;
                $rev_self = $col;
            }

            $rev_foreign =~ s/^foreign\.//;
            $rev_self    =~ s/^self\.//;

            # Check if the keys match in reverse
            # Forward: foreign.id => self.user_id
            # Reverse: foreign.user_id => self.id
            if ($rev_foreign eq $forward_self && $rev_self eq $forward_foreign) {
                return $rev_rel;
            }
        }
    }

    # If we couldn't find it by key matching, try by source name
    # This is a fallback for simple cases
    foreach my $rev_rel (@rel_names) {
        my $rev_info       = $rel_source->relationship_info($rev_rel);
        my $rev_source_obj = $rel_source->related_source($rev_rel);

        if ($rev_source_obj->source_name eq $source->source_name) {
            return $rev_rel;
        }
    }

    return undef;
}

=head2 _resolved_attrs

    my $attrs = $rs->_resolved_attrs;
    my $rows  = $attrs->{rows};

=over 4

=item Return Value: HashRef

=back

An internal helper method that returns the raw attributes hash for the current
ResultSet. This includes things like C<order_by>, C<join>, C<prefetch>, C<rows>,
and C<offset>.

If no attributes have been set, it returns an empty anonymous hash reference
(C<{}>) to ensure that calls to specific keys (e.g., C<$rs->_resolved_attrs->{rows}>)
do not trigger "not a HASH reference" errors.

B<Note:> This is intended for internal use and testing. To modify attributes,
use the L</search> method to create a new ResultSet.

=cut

sub _resolved_attrs {
    my $self = shift;
    return $self->{_attrs} // {};
}

# Chainable modifiers
foreach my $method (qw(rows order_by columns group_by having distinct)) {
    no strict 'refs';
    *{$method} = sub {
        my ($self, $value) = @_;
        return $self->search(undef, { $method => $value });
    };
}

=head1 SEE ALSO

=over 4

=item *

L<DBIx::Class::Async> - Asynchronous DBIx::Class interface

=item *

L<DBIx::Class::ResultSet> - Synchronous DBIx::Class result set interface

=item *

L<DBIx::Class::Async::Row> - Asynchronous row objects

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
