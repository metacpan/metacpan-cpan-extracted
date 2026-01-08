package DBIx::Class::Async::ResultSet;

use strict;
use warnings;
use utf8;
use v5.14;

use Carp;
use Future;
use Scalar::Util 'blessed';
use DBIx::Class::Async::Row;
use DBIx::Class::Async::Cursor;

=head1 NAME

DBIx::Class::Async::ResultSet - Asynchronous ResultSet for DBIx::Class::Async

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

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

A helper method that inflates a raw hash of database columns into a blessed Row object.

It dynamically generates a specialised subclass under the C<DBIx::Class::Async::Row::*>
namespace based on the C<source_name> of the current ResultSet. This allows for
cleaner method resolution and avoids namespace pollution across different tables.

The returned object will be an instance of a class that inherits from
L<DBIx::Class::Async::Row>.

Returns C<undef> if the provided data is empty or undefined.

=cut

sub new_result {
    my ($self, $data) = @_;
    return undef unless $data;

    # Create a unique class for this specific table to avoid namespace pollution
    my $row_class = "DBIx::Class::Async::Row::" . $self->{source_name};

    {
        no strict 'refs';
        unless (@{"${row_class}::ISA"}) {
            @{"${row_class}::ISA"} = ('DBIx::Class::Async::Row');
        }
    }

    return $row_class->new(
        schema      => $self->{schema},
        async_db    => $self->{async_db},
        source_name => $self->{source_name},
        row_data    => $data,
    );
}

=head2 new_result_set

  my $new_rs = $rs->new_result_set({
      entries       => \@prefetched_data,
      is_prefetched => 1
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

Returns all rows matching the current search criteria as L<DBIx::Class::Async::Row>
objects.

=over 4

=item B<Returns>

A L<Future> that resolves to an array reference of L<DBIx::Class::Async::Row>
objects.

=item B<Notes>

Results are cached internally for use with C<next> and C<reset> methods.

=back

=cut

=head2 all

Returns all rows matching the current search criteria as L<DBIx::Class::Async::Row> objects,
with prefetched relationships properly inflated.

=cut

sub all {
    my $self = shift;

    # 1. If this is a prefetched ResultSet, return the data immediately as a Future
    if ($self->{is_prefetched} && $self->{entries}) {
        my @rows       = map { $self->new_result($_) } @{$self->{entries}};
        $self->{_rows} = \@rows;
        return Future->done(\@rows);
    }

    # 2. Standard Async Fetch with Prefetch Support
    my $source_name = $self->{source_name};

    return $self->{async_db}->search(
        $source_name,
        $self->{_cond},
        $self->{_attrs}
    )->then(sub {
        my ($rows_data) = @_;

        my @rows = map {
            my $row_data = $_;
            my $row = $self->new_result($row_data);

            # If the hash contains nested hashes or arrays, it's prefetched data
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
    return ($self->{_cond}, $self->{_attrs});
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

    # MERGE: Combine the ResultSet's current search condition (which contains the foreign key)
    # with the new data provided by the user.
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

        if (ref $result eq 'HASH' && $result->{__error}) {
            return Future->fail($result->{__error}, 'db_error');
        }

        return Future->done($self->new_result($result));
    });
}

=head2 cursor

  my $cursor = $rs->cursor;

Returns a L<DBIx::Class::Async::Cursor> object for the current resultset.
This is used to stream through large data sets asynchronously without
loading all records into memory at once.

=cut

sub cursor {
    my ($self) = @_;

    # We return a specialised Cursor object
    return DBIx::Class::Async::Cursor->new(
        rs => $self,
    );
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

    return $self->all->then(sub {
        my (@rows) = @_;

        my @values = map { $_->get_column($column) } @rows;
        return Future->done(\@values);
    });
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

    my $clone = bless {
        %$self,
        _cond         => { %{$self->{_cond}},  %{$cond  || {}} },
        _attrs        => { %{$self->{_attrs}}, %{$attrs || {}} },
        _rows         => undef,
        _pos          => 0,
        entries       => undef, # Clones lose prefetch data unless re-fetched
        is_prefetched => 0,
    }, ref $self;

    return $clone;
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

    # 1. If already prefetched
    if ($self->{is_prefetched} && $self->{entries}) {
        my $data = $self->{entries}[0];
        return Future->done($data ? $self->new_result($data) : undef);
    }

    # 2. Optimization: Check for simple PK lookup
    my @pk = $self->result_source->primary_columns;
    if (@pk == 1
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

    # 3. General Case - FIX IS HERE
    return $self->search(undef, { rows => 1 })->all->then(sub {
        my ($results) = @_; # $results is now an ARRAY reference

        # Guard: Check if it's an arrayref and get the first element
        my $row = (ref $results eq 'ARRAY') ? $results->[0] : $results;

        return Future->done($row);
    });
}

=head2 search_future

    $rs->search_future->then(sub {
        # Same as all_future, alias for API consistency
    });

Alias for C<all_future>.

=cut

sub search_future { shift->all_future(@_)  }

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

=head2 source

    my $source = $rs->source;

Alias for C<result_source>.

=over 4

=item B<Returns>

A L<DBIx::Class::ResultSource> object.

=back

sub source { shift->_get_source }

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

=head1 INTERNAL METHODS

These methods are for internal use and are documented for completeness.

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

=head2 _find_reverse_relationship (Internal)

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

# Chainable modifiers
foreach my $method (qw(rows page order_by columns group_by having distinct)) {
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
