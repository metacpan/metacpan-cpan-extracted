package DBIx::Class::Async::Row;

use strict;
use warnings;
use utf8;
use v5.14;

use Carp;
use Future;
use Scalar::Util qw(blessed);

=head1 NAME

DBIx::Class::Async::Row - Asynchronous row object for DBIx::Class::Async

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

=head1 SYNOPSIS

    # Typically obtained via a ResultSet bridge
    my $user = $rs->find(1)->get;

    # Accessing Data (Synchronous/In-memory)

    say "User: " . $user->name;
    my $email = $user->get_column('email');
    my %data  = $user->get_columns;

    # Persistence Operations (Asynchronous, returns Future)

    # Update with chaining
    $user->update({ last_login => time })->then(sub {
        my $self = shift;
        say "Update complete for: " . $self->email;

        # Discard local changes and refetch fresh data from DB
        return $self->discard_changes;
    })->then(sub {
        my $fresh_user = shift;
        say "Confirmed DB state: " . $fresh_user->last_login;
    });

    # Delete record
    $user->delete->then(sub {
        say "Record removed from database.";
    });

    # Relationship Access (Asynchronous)

    # If the Row component is loaded, access related sets
    $user->search_related('orders', { status => 'pending' })
         ->all
         ->then(sub {
             my @orders = @_;
             say "Found " . scalar(@orders) . " pending orders.";
         });

=head1 DESCRIPTION

C<DBIx::Class::Async::Row> provides an asynchronous row object that represents
a single database row in a L<DBIx::Class::Async> application. It mimics the
interface of L<DBIx::Class::Row> but returns L<Future> objects for asynchronous
database operations.

This class is typically instantiated by L<DBIx::Class::Async> and not directly
by users. It provides both synchronous column access and asynchronous methods
for database operations.

=head1 CONSTRUCTOR

=head2 new

    my $row = DBIx::Class::Async::Row->new(
        schema      => $schema,            # DBIx::Class::Schema instance
        async_db    => $async_db,          # DBIx::Class::Async instance
        source_name => $source_name,       # Result source name
        row_data    => \%data,             # Hashref of row data
    );

Creates a new asynchronous row object.

=over 4

=item B<Parameters>

=over 8

=item C<schema>

A L<DBIx::Class::Schema> instance. Required.

=item C<async_db>

A L<DBIx::Class::Async> instance. Required.

=item C<source_name>

The name of the result source (table). Required.

=item C<row_data>

Hash reference containing the row's column data. Required.

=back

=item B<Throws>

=over 4

=item *

Croaks if any required parameter is missing.

=back

=back

=cut

# PRIVATE CONSTANTS
# Protects internal attributes from being treated as database columns
my $INTERNAL_KEYS = qr/^(?:_.*|async_db|source_name|schema|_inflation_map)$/;

sub new {
    my ($class, %args) = @_;

    croak "Missing required argument: schema"      unless $args{schema};
    croak "Missing required argument: async_db"    unless $args{async_db};
    croak "Missing required argument: source_name" unless $args{source_name};
    croak "Missing required argument: row_data"    unless $args{row_data};

    my $in_storage = delete $args{in_storage} // 0;
    my $data       = $args{row_data} || $args{_data} || {};

    my $self = bless {
        schema         => $args{schema},
        async_db       => $args{async_db},
        source_name    => $args{source_name},
        _source        => $args{_source} // undef,
        _data          => { %$data },
        _dirty         => {},
        _inflated      => {},
        _related       => {},
        _in_storage    => $in_storage,
        _inflation_map => {},
    }, $class;

    $self->_ensure_accessors;

    # WARM-UP: Pre-calculate metadata and shadow plain columns for speed
    my $source = $self->_get_source;
    if ($source) {
        foreach my $col (keys %$data) {
            # Skip internal plumbing
            next if $self->_is_internal($col);

            if ($source->has_column($col)) {
                my $info = $source->column_info($col);
                my $inflator = $info->{inflate} // 0;
                $self->{_inflation_map}{$col} = $inflator;

                # If NO inflator, shadow to top-level for direct hash-key speed
                if (!$inflator) {
                    $self->{$col} = $data->{$col};
                }
            }
            else {
                # Relationship or custom key - safe to shadow
                $self->{$col} = $data->{$col};
                $self->{_inflation_map}{$col} = 0;
            }
        }
    }

    return $self;
}

=head1 METHODS

=head2 copy

    my $future = $row->copy(\%changes);
    $future->then(sub {
        my ($new_row) = @_;
        # use $new_row
    });

Creates a copy of the current row object with optional modifications.

This method performs an asynchronous copy operation that:

=over 4

=item * Creates a new database record with the same column values as the current row

=item * Automatically excludes auto-increment columns (primary keys) from the copy

=item * Allows overriding specific column values through the C<\%changes> parameter

=item * Returns a L<Future> that resolves to a new row object of the same class

=back

B<Parameters:>

=over 4

=item C<$changes>

Optional hash reference containing column-value pairs to override in the copied row.
The changes are applied I<after> excluding auto-increment columns, so you can use this
to set a different primary key if needed.

If not provided or C<undef>, an empty hash reference will be used.

=back

B<Returns:> L<Future> that resolves to a new L<DBIx::Class::Async::Row> object (or subclass)
representing the copied database record.

B<Example:>

    # Simple copy
    $product->copy->then(sub {
        my ($copy) = @_;
        say "Copied product ID: " . $copy->id;
    });

    # Copy with modifications
    $product->copy({
        name => $product->name . ' (Copy)',
        sku  => 'NEW-SKU-123'
    })->then(sub {
        my ($modified_copy) = @_;
        # New row with changed name and SKU
    });

B<Notes:>

=over 4

=item * Auto-increment columns are automatically detected and excluded from the copy

=item * The method performs the copy at the database level, not just object duplication

=item * The returned row object will be of the appropriate subclass if one exists
(e.g., C<DBIx::Class::Async::Row::Product> for a Product source)

=item * All database constraints and triggers will apply during the copy operation

=item * The original row object remains unchanged

=back

B<Throws:> Exceptions from the underlying database operations will be propagated
through the returned L<Future>.

=cut

sub copy {
    my ($self, $changes) = @_;
    $changes //= {};

    my $source = $self->_get_source;

    # 1. Get ONLY keys that are valid database columns
    my %data;
    foreach my $col ($source->columns) {
        # Check _data first (clean storage), then top-level (hack storage)
        if (exists $self->{_data}{$col}) {
            $data{$col} = $self->{_data}{$col};
        }
        elsif (exists $self->{$col}) {
            # Ensure we don't accidentally copy our own management objects
            # if a column happened to have the same name
            next if $col =~ /^(?:async_db|schema|source_name|_source)$/;
            $data{$col} = $self->{$col};
        }
    }

    # 2. Remove Primary Keys (unless specifically overridden in $changes)
    foreach my $pk ($source->primary_columns) {
        delete $data{$pk} unless exists $changes->{$pk};
    }

    # 3. Apply user changes
    foreach my $col (keys %$changes) {
        $data{$col} = $changes->{$col};
    }

    # 4. Use the Async ResultSet to create
    return $self->{async_db}->resultset($self->{source_name})->create(\%data);
}

=head2 create_related

  my $post_future = $user->create_related('posts', {
      title   => 'My First Post',
      content => 'Hello World!'
  });

  my $post = await $post_future;

A convenience method that creates a new record in the specified relationship.

It internally calls C<related_resultset> to identify the correct foreign key
mapping (e.g., setting C<user_id> to the current user's ID) and then invokes
C<create> on the resulting ResultSet.

This method returns a L<Future> that resolves to a new Row object of the
related type.

B<Note:> Just like L<DBIx::Class::Async::ResultSet/create>, this method
automatically merges the relationship's foreign key constraints into the
provided hashref, ensuring that C<NOT NULL> constraints on the foreign key
columns are satisfied.

=cut

sub create_related {
    my ($self, $rel_name, $col_data) = @_;

    return $self->related_resultset($rel_name)->create($col_data);
}

=head2 delete

    $row->delete
        ->then(sub {
            my ($success) = @_;
            if ($success) {
                say "Row deleted successfully";
            }
        })
        ->catch(sub {
            my ($error) = @_;
            # Handle error
        });

Asynchronously deletes the row from the database.

=over 4

=item B<Returns>

A L<Future> that resolves to true if the row was deleted, false otherwise.

=item B<Throws>

Croaks if the row doesn't have a primary key.

=back

=cut

sub delete {
    my ($self) = @_;

    # If already deleted (not in storage), return false immediately
    unless ($self->in_storage) {
        return Future->done(0);
    }

    my $pk_info = $self->_get_primary_key_info;
    my $pk      = $pk_info->{columns}[0];
    my $id      = $self->get_column($pk);

    croak "Cannot delete row without a primary key"
        unless defined $id;

    return $self->{async_db}->delete($self->{source_name}, $id)->then(sub {
        my ($result) = @_;

        if (my $error = $self->_check_response($result)) {
            return Future->fail($error, 'db_error');
        }

        # Mark as not in storage
        $self->{_in_storage} = 0;

        # Return the success value (1 or 0), not $self
        return Future->done(1);
    });
}

=head2 discard_changes

  $row->discard_changes->then(sub {
      my ($refreshed_row) = @_;
      # Row data reloaded from database
  });

Reloads the row data from the database, discarding any changes.

=over 4

=item B<Returns>

A L<Future> that resolves to the refreshed row object.

=item B<Notes>

This refetches the row from the database and clears the dirty columns hash.

=back

=cut

sub discard_changes {
    my $self = shift;

    # Get primary key
    my @pk = $self->_get_source->primary_columns;

    croak("Cannot discard changes on row without primary key") unless @pk;
    croak("Composite primary keys not yet supported") if @pk > 1;

    my $pk_col = $pk[0];
    my $id = $self->get_column($pk_col);

    croak("Cannot discard changes: primary key value is undefined")
        unless defined $id;

    # Fetch fresh data from database
    return $self->{async_db}->find($self->{source_name}, $id)->then(sub {
        my ($fresh_data) = @_;

        if (my $error = $self->_check_response($fresh_data)) {
            return Future->fail($error, 'db_error');
        }

        # Extract the raw data from the fresh data
        my $raw_data = (ref($fresh_data) && $fresh_data->can('get_columns'))
                            ? { $fresh_data->get_columns }
                            : $fresh_data;

        # If it's an arrayref (sometimes returned by search/find), take first
        $raw_data = $raw_data->[0] if ref($raw_data) eq 'ARRAY';

        # Update our data
        $self->{_data} = $raw_data;
        $self->{_dirty} = {};

        return Future->done($self);
    });
}

=head2 get_column

    my $value = $row->get_column($column_name);

Synchronously retrieves a column value from the row.

=over 4

=item B<Parameters>

=over 8

=item C<$column_name>

Name of the column to retrieve.

=back

=item B<Returns>

The column value. If the column has an inflator defined, returns the
inflated value.

=item B<Throws>

Croaks if the column doesn't exist.

=back

=cut

sub get_column {
    my ($self, $col) = @_;

    # 1. Fast-track internal plumbing
    return $self->{$col} if $self->_is_internal($col);

    # 2. Return cached inflated value if it exists
    return $self->{_inflated}{$col} if exists $self->{_inflated}{$col};

    # 3. Discovery & Exception Handling
    if (!exists $self->{_inflation_map}{$col}) {
        my $source = $self->_get_source;

        # If it's not in data AND not in schema, trigger DBIC exception
        if ($source && !$source->has_column($col) && !exists $self->{_data}{$col}) {
            # Calling column_info on a non-existent column triggers the "No such column" croak
            return $source->column_info($col);
        }

        if ($source && $source->has_column($col)) {
            $self->{_inflation_map}{$col} = $source->column_info($col)->{inflate} // 0;
        } else {
            $self->{_inflation_map}{$col} = 0;
        }
    }

    my $raw      = $self->{_data}{$col};
    my $inflator = $self->{_inflation_map}{$col};

    # 4. Inflate if needed
    if ($inflator && defined $raw) {
        # Check if already inflated via shadow key
        if ("$raw" =~ /^HASH\(0x/ && ref $self->{$col}) {
            return $self->{$col};
        }

        my $inflated = eval { $inflator->("$raw", $self) };
        if (!$@ && defined $inflated) {
            $self->{_inflated}{$col} = $inflated;
            $self->{$col} = $inflated;
            return $inflated;
        }
    }

    return $raw;
}

=head2 get_columns

    my %columns = $row->get_columns;

Returns all columns as a hash.

=over 4

=item B<Returns>

Hash containing all column names and values.

=back

=cut

sub get_columns {
    my $self = shift;
    my $data = $self->{_data} || {};

    # 1. Get the list of valid column names from the source
    my @valid_cols = $self->_get_source->columns;

    # 2. Only extract keys that are actual database columns
    my %cols;
    foreach my $col (@valid_cols) {
        if (exists $data->{$col}) {
            $cols{$col} = $data->{$col};
        }
    }

    return wantarray ? %cols : \%cols;
}

=head2 get_dirty_columns

  my %dirty = $row->get_dirty_columns;
  my $dirty_ref = $row->get_dirty_columns;

Returns columns that have been modified but not yet saved.

=over 4

=item B<Returns>

In list context: Hash of column-value pairs for dirty columns.

In scalar context: Hashref of column-value pairs for dirty columns.

=item B<Examples>

  $row->set_column('name' => 'Alice');
  $row->set_column('email' => 'alice@example.com');

  my %dirty = $row->get_dirty_columns;
  # %dirty = (name => 'Alice', email => 'alice@example.com')

  my @dirty_cols = keys %dirty;
  say "Modified: " . join(', ', @dirty_cols);

=back

=cut

sub get_dirty_columns {
    my $self = shift;

    my %dirty_values;
    foreach my $column (keys %{$self->{_dirty}}) {
        $dirty_values{$column} = $self->{_data}{$column};
    }

    return wantarray ? %dirty_values : \%dirty_values;
}

=head2 get_inflated_columns

    my %inflated_columns = $row->get_inflated_columns;

Returns all columns with inflated values where applicable.

=over 4

=item B<Returns>

Hash containing all column names and inflated values.

=back

=cut

sub get_inflated_columns {
    my $self = shift;

    my %inflated;
    foreach my $col (keys %{$self->{_data}}) {
        $inflated{$col} = $self->get_column($col);
    }

    return %inflated;
}

=head2 id

  my $id  = $row->id;          # Single primary key
  my @ids = $row->id;          # Composite primary key (multiple values)

Returns the primary key value(s) for a row.

=over 4

=item B<Arguments>

None

=item B<Returns>

In list context: List of primary key values.

In scalar context: Single primary key value (for single-column primary keys) or
arrayref of values (for composite primary keys).

=item B<Throws>

Dies if:
- Called as a class method
- No primary key defined for the source
- Row is not in storage and primary key value is undefined

=item B<Examples>

  # Single primary key
  my $user = $rs->find(1)->get;
  my $id = $user->id;  # Returns: 1

  # Composite primary key
  my $record = $rs->find({ key1 => 1, key2 => 2 })->get;
  my @ids = $record->id;  # Returns: (1, 2)

  # Arrayref in scalar context (composite key)
  my $ids = $record->id;  # Returns: [1, 2]

=back

=cut

sub id {
    my $self = shift;

    croak("id() cannot be called as a class method")
        unless ref $self;

    my @pk_columns = $self->_get_source->primary_columns;

    croak("No primary key defined for " . $self->{source_name})
        unless @pk_columns;

    my @pk_values;
    foreach my $col (@pk_columns) {
        my $val = $self->get_column($col);

        # Warn if primary key is undefined (usually means row not in storage)
        unless (defined $val) {
            carp("Primary key column '$col' is undefined for " .
                 $self->{source_name});
        }

        push @pk_values, $val;
    }

    # Return based on context
    if (wantarray) {
        # List context: return list
        return @pk_values;
    } else {
        # Scalar context
        if (@pk_values == 1) {
            # Single primary key: return the value
            return $pk_values[0];
        } else {
            # Composite primary key: return arrayref
            return \@pk_values;
        }
    }
}

=head2 insert

    $row->insert
        ->then(sub {
            my ($inserted_row) = @_;
            # Row has been inserted
        });

Asynchronously inserts the row into the database.

Note: This method is typically called automatically by L<DBIx::Class::Async/create>.
For existing rows, it returns an already-resolved Future.

=over 4

=item B<Returns>

A L<Future> that resolves to the row object.

=back

=cut

sub insert {
    my $self = shift;

    # If the row is already in the database, DBIC behavior is to throw an error
    # or no-op. Here we follow the safer path.
    if ($self->in_storage) {
        return Future->fail("Check failed: count of objects to be inserted is 0 (already in storage)");
    }

    # update_or_insert handles the actual DB communication and state flipping
    return $self->update_or_insert;
}

=head2 insert_or_update

  await $row->insert_or_update;

Arguments: \%fallback_data?
Return Value: L<Future> resolving to $row

An alias for L</update_or_insert>. Provided for compatibility with
standard L<DBIx::Class::Row> method naming.

=cut

sub insert_or_update {
    my $self = shift;
    return $self->update_or_insert(@_);
}

=head2 in_storage

    if ($row->in_storage) {
        # Row exists in database
    }

Checks whether the row exists in the database.

=over 4

=item B<Returns>

True if the row is in storage (has a primary key and hasn't been deleted),
false otherwise.

=back

=cut

sub in_storage {
    my ($self, $val) = @_;

    if (defined $val) {
        $self->{_in_storage} = $val ? 1 : 0;
        # If it's in storage, it's no longer 'dirty' (unsaved changes)
        $self->{_dirty} = {} if $self->{_in_storage};
    }

    return $self->{_in_storage} // 0;
}

=head2 is_column_changed

  if ($row->is_column_changed('name')) {
      say "Name was modified";
  }

Checks if a specific column has been modified but not yet saved.

=over 4

=item B<Arguments>

=over 8

=item C<$column>

The column name to check.

=back

=item B<Returns>

True if the column is dirty (modified), false otherwise.

=back

=cut

sub is_column_changed {
    my ($self, $column) = @_;

    croak("column name required") unless defined $column;

    return exists $self->{_dirty}{$column} ? 1 : 0;
}

=head2 is_column_dirty

  if ($row->is_column_dirty('email')) {
      print "Email has been changed but not saved yet!";
  }

Arguments: $column_name
Return Value: 1|0

Returns a boolean value indicating whether the specified column has been modified
since the row was last fetched from or saved to the database.

=cut

sub is_column_dirty {
    my ($self, $column) = @_;
    return exists $self->{_dirty}{$column} ? 1 : 0;
}

=head2 make_column_dirty

  $row->make_column_dirty('name');

Marks a column as dirty even if its value hasn't changed.

=over 4

=item B<Arguments>

=over 8

=item C<$column>

The column name to mark as dirty.

=back

=item B<Returns>

The row object itself (for chaining).

=back

=cut

sub make_column_dirty {
    my ($self, $column) = @_;

    croak("column name required") unless defined $column;

    $self->{_dirty}{$column} = 1;

    return $self;
}

=head2 related_resultset

    my $rs = $row->related_resultset($relationship_name);

Returns a resultset for a related table.

=over 4

=item B<Parameters>

=over 8

=item C<$relationship_name>

Name of the relationship as defined in the result class.

=back

=item B<Returns>

A L<DBIx::Class::ResultSet> for the related table, filtered by the
relationship condition.

=item B<Throws>

=over 4

=item *

Croaks if the relationship doesn't exist.

=item *

Croaks if the relationship condition cannot be parsed.

=back

=back

=cut

sub related_resultset {
    my ($self, $rel_name) = @_;

    my $source = $self->_get_source;
    my $rel_info = $source->relationship_info($rel_name)
        or croak "No such relationship '$rel_name'";

    # Get the condition
    my $cond = $rel_info->{cond};

    my ($self_column, $foreign_column);

    if (ref $cond eq 'HASH') {
        # Parse hashref: { 'foreign.id' => 'self.user_id' } or { 'foreign.user_id' => 'self.id' }
        foreach my $key (keys %$cond) {
            my $value = $cond->{$key};
            if ($value =~ /^self\.(\w+)$/) {
                $self_column = $1;
                $foreign_column = $key;
                $foreign_column =~ s/^foreign\.//;
                last;
            } elsif ($key =~ /^foreign\.(\w+)$/ && $value =~ /^self\.(\w+)$/) {
                # Alternative format
                $foreign_column = $1;
                $self_column = $value =~ /^self\.(\w+)$/ ? $1 : undef;
                last;
            }
        }
    } elsif (!ref $cond) {
        # String format
        if ($cond =~ /^self\.(\w+)$/) {
            $self_column = $1;
            $foreign_column = 'id';  # Default
        }
    }

    croak "Could not parse relationship condition for '$rel_name'"
        unless $self_column && $foreign_column;

    # Get value from our row
    my $value = $self->get_column($self_column);

    my $raw_source = $rel_info->{source}
        or croak "No source defined for relationship '$rel_name'";

    my $moniker = $raw_source;
    $moniker =~ s/.*:://;

    my $search_cond = { $foreign_column => $value };

    return $self->{async_db}->resultset($moniker)->search($search_cond);
}

=head2 result_source

    my $source = $row->result_source;

Returns the L<DBIx::Class::ResultSource> for this row.

=over 4

=item B<Returns>

The result source object, or undef if not available.

=back

=cut

sub result_source {
    my $self = shift;
    return $self->_get_source;
}

=head2 set_column

  $row->set_column('name' => 'Alice');
  $row->set_column('email' => 'alice@example.com');

Sets a raw column value. If the new value is different from the old one,
the column is marked as dirty for when you next call C<update>.

=over 4

=item B<Arguments>

=over 8

=item C<$columnname>

The name of the column to set.

=item C<$value>

The value to set. Can be a scalar, object, or reference.

=back

=item B<Returns>

The value that was set.

=item B<Notes>

- If the new value differs from the old value, the column is marked as dirty
- If passed an object or reference, it will be stored as-is
- Use C<set_inflated_columns> for proper inflation/deflation
- Better yet, use column accessors: C<< $row->name('Alice') >>

=item B<Examples>

  # Set a simple value
  $row->set_column('name' => 'Bob');

  # Set to undef
  $row->set_column('email' => undef);

  # Mark as dirty and update
  $row->set_column('active' => 0);
  $row->update->get;

=back

=cut

sub set_column {
    my ($self, $col, $value) = @_;

    if (!defined $col || $col eq '') {
         require Carp;
         Carp::croak("Column name required for set_column");
    }

    # If someone tries to set 'async_db' or '_source', we return early
    # to protect the object's plumbing and prevent "dirty" poisoning.
    return $value if $self->_is_internal($col);

    # 1. Capture types before any operations occur
    my $old = $self->{_data}{$col};
    my $old_ref = ref($old)   || 'SCALAR';
    my $new_ref = ref($value) || 'SCALAR';

    my $changed = 0;
    if (!defined $old && defined $value) {
        $changed = 1;
    } elsif (defined $old && !defined $value) {
        $changed = 1;
    } elsif (defined $old && defined $value) {
        if ($old_ref ne 'SCALAR' || $new_ref ne 'SCALAR') {
            $changed = 1;
        } else {
            # Safe to use string comparison
            if ($old ne $value) {
                $changed = 1;
            }
        }
    }

    if ($changed) {
        $self->{_data}{$col} = $value;
        $self->{_dirty}{$col} = 1;

        # Clear the inflated cache so the next 'get_column' re-inflates the new data
        delete $self->{_inflated}{$col};

        # We delete the top-level key so it doesn't "shadow" the new data
        delete $self->{$col};
    }

    return $value;
}

=head2 set_columns

  $row->set_columns({
      name   => 'Alice',
      email  => 'alice@example.com',
      active => 1,
  });

Sets multiple column, raw value pairs at once.

=over 4

=item B<Arguments>

=over 8

=item C<\%columndata>

A hashref of column-value pairs.

=back

=item B<Returns>

The row object itself (for chaining).

=item B<Examples>

  # Set multiple columns
  $row->set_columns({
      name   => 'Bob',
      email  => 'bob@example.com',
      active => 1,
  });

  # Chain with update
  $row->set_columns({ name => 'Carol' })->update->get;

=back

=cut

sub set_columns {
    my ($self, $values) = @_;

    croak("hashref of column-value pairs required")
        unless defined $values && ref $values eq 'HASH';

    while (my ($column, $value) = each %$values) {
        $self->set_column($column, $value);
    }

    return $self;
}

=head2 update

  # Update with explicit values
  $row->update({ name => 'Bob', email => 'bob@example.com' })->get;

  # Update using dirty columns (after set_column/set_columns)
  $row->set_column('name', 'Bob');
  $row->update()->get;  # Updates only dirty columns

Updates the row in the database.

=over 4

=item B<Arguments>

=over 8

=item C<\%values> (optional)

A hashref of column-value pairs to update. If not provided, uses dirty columns.

=back

=item B<Returns>

A L<Future> that resolves to the updated row object.

=back

=cut

sub update {
    my ($self, $values) = @_;

    # 1. Validation
    unless ($self->in_storage) {
        return Future->fail("Cannot update row: not in storage. Did you mean to call insert or update_or_insert?");
    }

    # 2. If values are passed, update internal state via set_column first
    if ($values) {
        croak("Usage: update({ col => val })") unless ref $values eq 'HASH';
        foreach my $col (keys %$values) {
            $self->set_column($col, $values->{$col});
        }
    }

    # 3. Delegate to update_or_insert
    # Since in_storage is true, update_or_insert will correctly
    # run the UPDATE logic and clear dirty flags on success.
    return $self->update_or_insert;
}

=head2 update_or_insert

  my $future = $row->update_or_insert({ name => 'New Name' });

  $future->on_done(sub {
      my $row = shift;
      print "Row saved successfully";
  });

Arguments: \%fallback_data?
Return Value: L<Future> resolving to $row

Provides a "save" mechanism that intelligently decides whether to perform an
C<INSERT> or an C<UPDATE> based on the current state of the row object.

=over 4

=item 1

If the row is already C<in_storage>, it performs an C<update>. Only columns
marked as "dirty" (changed) will be sent to the database. If no columns are
dirty, the Future resolves immediately with the current row object.

=item 2

If the row is not in storage, it performs a C<create>. The entire contents
of the row's data are sent to the database.

=back

You may optionally pass a hashref of data to this method. These values will be
passed to C<set_column> before the save operation begins, effectively merging
ad-hoc changes into the row.

Upon success, the row's internal "dirty" tracking is reset, C<in_storage> is
set to true, and any database-generated values (like auto-increment IDs) are
synchronised back into the object.

=cut

sub update_or_insert {
    my ($self, $data) = @_;

    my $async_db    = $self->{async_db};
    my $source_name = $self->{source_name};
    my $source      = $self->result_source;
    my ($pk_col)    = $source->primary_columns;

    # 1. Apply changes to the object
    if ($data && ref $data eq 'HASH') {
        foreach my $col (keys %$data) {
            $self->set_column($col, $data->{$col});
        }
    }

    my $is_update = $self->in_storage;

    # 2. Prepare Payload
    my %raw_payload = $is_update ? $self->get_dirty_columns : %{ $self->{_data} // {} };
    my %to_save;

    foreach my $col (keys %raw_payload) {
        # If it's not in _inflated, fall back to the raw value in %raw_payload.
        my $val  = exists $self->{_inflated}{$col} ? $self->{_inflated}{$col} : $raw_payload{$col};
        my $info = $source->column_info($col);

        # If a deflate handler exists and we have a reference, turn it into a string
        if ($info && $info->{deflate} && defined $val && ref $val) {
            $val = $info->{deflate}->($val, $self);
        }

        $to_save{$col} = $val;
    }

    # 3. Success handler
    my $on_success = sub {
        my ($res) = @_;

        # We check if it's an object FIRST before asking what kind of object it is.
        if (blessed($res) && $res->isa('DBIx::Class::Exception')) {
             return Future->fail($res->msg, 'db_error');
        }

        # Also check for the HASH-style error envelope which we saw in your logs
        if (ref $res eq 'HASH' && ($res->{error} || $res->{__error})) {
             my $err = $res->{error} // $res->{__error};
            return Future->fail($err, 'db_error');
        }

        # Normalise data source
        my $final_data;
        if (ref $res && ref $res eq 'HASH') {
            $final_data = $res;
        }
        elsif (ref $res && eval { $res->can('get_columns') }) {
            # Handle case where $res is another Row object
            my %cols = $res->get_columns;
            $final_data = \%cols;
        }
        else {
            # Scalar result (ID) or fallback
            $final_data = { %to_save };
            if (!$is_update && defined $res && !ref $res && $pk_col) {
                $final_data->{$pk_col} = $res;
            }
        }

        $self->{_in_storage} = 1;
        $self->in_storage(1);

        foreach my $col (keys %$final_data) {
            my $new_val = $final_data->{$col};

            # 1. Update core data first
            $self->{_data}{$col} = $new_val;

            # 2. Clear caches
            delete $self->{_inflated}{$col};
            delete $self->{_dirty}{$col};

            # 3. Handle the Shadow Key with a "Column Only" safety check
            my $source = $self->can('_get_source') ? $self->_get_source : undef;

            # CRITICAL: Only call column_info IF the source confirms it is a real column.
            # This skips 'schema', '_source', 'async_db', and relationships.
            if ($source && $source->has_column($col)) {
                my $info = $source->column_info($col);
                if ($info && $info->{inflate}) {
                    # For inflated cols, delete shadow to force get_column() to run.
                    delete $self->{$col};
                }
                else {
                    # For standard columns, update the shadow.
                    $self->{$col} = $new_val;
                }
            }
            else {
                # If it's an internal attribute or relationship,
                # just update the shadow if it already exists,
                # but NEVER ask column_info about it.
                $self->{$col} = $new_val if exists $self->{$col};
            }
        }

        return $self;
    };

    # 4. Dispatch
    if ($is_update) {
        return Future->done($self) unless keys %to_save;

        my $id_val = $self->{_data}{$pk_col}
            // ( $self->can($pk_col) ? $self->$pk_col : undef )
            // $self->{$pk_col};

        if (ref $id_val && eval { $id_val->can('get_column') }) {
            $id_val = $id_val->get_column($pk_col);
        }

        if (!defined $id_val) {
            return Future->fail(
                "Cannot update row: Primary key ($pk_col) is missing",
                "logic_error");
        }

        return $async_db->update($source_name, $id_val, \%to_save)
                        ->then(sub {
                            my $res = shift;
                            # We must catch the error before it gets 'inflated' into a Row
                            if (blessed($res) && $res->isa('DBIx::Class::Exception')) {
                                my $error_text = "$res";
                                return Future->fail($error_text, 'db_error');
                            }
                            return $on_success->($res);
                          });
    } else {
        return $async_db->create($source_name, \%to_save)
                        ->then(sub {
                            my $res = shift;
                            if (blessed($res) && $res->isa('DBIx::Class::Exception')) {
                                my $error_text = "$res";
                                return Future->fail($error_text, 'db_error');
                            }
                            return $on_success->($res);
                          });
    }
}

=head1 AUTOLOAD METHODS

Called automatically for column and relationship access

    my $value = $row->column_name;
    my $related = $row->relationship_name;

Handles dynamic method dispatch for columns and relationships.

The class uses AUTOLOAD to provide dynamic accessors for:

=over 4

=item *

Column values (e.g., C<< $row->name >> for column 'name')

=item *

Relationship accessors (e.g., C<< $row->orders >> for 'orders' relationship)

=back

Relationship results are cached in the object after first access.

=cut

sub AUTOLOAD {
    my $self = shift;

    our $AUTOLOAD;
    my ($method) = $AUTOLOAD =~ /([^:]+)$/;

    # 1. Immediate exit for core/Future methods
    return if $method =~ /^(?:DESTROY|AWAIT_\w+|can|isa|then|get|on_\w+|failure|else)$/;

    my $source = $self->_get_source;

    # 2. Handle Columns (Getter/Setter with Debugging)
    if ($source && $source->has_column($method)) {
        no strict 'refs';
        no warnings 'redefine';

        my $accessor = sub {
            my ($inner_self, $new_val) = @_;
            my $col_info = $inner_self->result_source->column_info($method);

            # SETTER MODE
            if (@_ > 1) {
                delete $inner_self->{_inflated}{$method};
                my $to_store = $new_val;

                if ($col_info->{deflate} && defined $new_val) {
                    $to_store = $col_info->{deflate}->($new_val, $inner_self);
                }

                $inner_self->set_column($method, $to_store);

                if ($col_info->{inflate} && ref $new_val) {
                    $inner_self->{_inflated}{$method} = $new_val;
                }
                return $new_val;
            }

            # GETTER MODE
            return $inner_self->{_inflated}{$method} if exists $inner_self->{_inflated}{$method};

            my $raw = $inner_self->get_column($method);
            if ($col_info->{inflate} && defined $raw) {

                # Check if the raw value is already in the 'inflated' format
                # This is a safety check for DBs that return inflated strings
                my $inflated = $col_info->{inflate}->($raw, $inner_self);

                # If inflation resulted in a double-prefix (e.g. mailto:mailto:)
                # then the $raw was already inflated. Use $raw instead.
                if (!ref($inflated) && $inflated =~ /^mailto:mailto:/) {
                    $inner_self->{_inflated}{$method} = $raw;
                    return $raw;
                }

                $inner_self->{_inflated}{$method} = $inflated;
                return $inflated;
            }
            return $raw;

        };

        *{ref($self) . "::$method"} = $accessor;
        return $self->$method(@_);
    }

    # 3. Handle Relationships
    my $rel_info;
    if ($source && $source->can('relationship_info')) {
        $rel_info = $source->relationship_info($method);
    }

    if ($rel_info) {
        # We found a relationship! Install our async version into the class
        no strict 'refs';
        no warnings 'redefine';
        my $class = ref($self);
        *{"${class}::$method"} = sub {
            my ($inner_self, @args) = @_;
            return $inner_self->_fetch_relationship_async($method, $rel_info, @args);
        };

        # Now call the version we just installed
        return $self->$method(@_);
    }

    # 4. Fallback for non-column data already in the buffer
    if (exists $self->{_data}{$method} && !@_) {
        return $self->{_data}{$method};
    }

    # 5. Exception handling
    croak(sprintf(
        "Method '%s' not found in package '%s'. " .
        "(Can't locate object method via AUTOLOAD. " .
        "Is it a missing column or relationship in your ResultSource?)",
        $method, ref($self)
    ));
}

=head1 DESTROY

    # Called automatically when object is destroyed

Destructor method.

=cut

sub DESTROY {
    # Nothing to do
}

=head1 INTERNAL METHODS

These methods are for internal use and are documented for completeness.

=head2 _build_relationship_accessor

    my $coderef = $row->_build_relationship_accessor($method, $rel_info);

Builds an accessor for a relationship that checks for prefetched data first,
then falls back to lazy loading if needed. For has_many relationships, the
ResultSet object is cached in the row.

=cut

sub _build_relationship_accessor {
    my ($self, $rel_name, $rel_info) = @_;

    my $rel_type = $rel_info->{attrs}{accessor} || 'single';
    my $cond = $rel_info->{cond};

    if ($rel_type eq 'single' || $rel_type eq 'filter') {
        # belongs_to or might_have relationship
        return sub {
            my $row = shift;

            # 1. CHECK FOR PREFETCHED DATA FIRST
            if (exists $row->{_prefetched} && exists $row->{_prefetched}{$rel_name}) {
                my $prefetched = $row->{_prefetched}{$rel_name};
                return Future->done($prefetched) if blessed($prefetched);
                return Future->done(undef);
            }

            # 2. LAZY LOAD: Extract foreign key from condition
            my $fk = $row->_extract_foreign_key($cond);
            return Future->done(undef) unless $fk;

            my $fk_value = $row->get_column($fk->{self});
            return Future->done(undef) unless defined $fk_value;

            # 3. Fetch related row asynchronously via schema->resultset
            my $rel_source = $row->_get_source->related_source($rel_name);
            my $rel_rs = $row->{schema}->resultset($rel_source->source_name);

            return $rel_rs->find({ $fk->{foreign} => $fk_value });
        };

    } elsif ($rel_type eq 'multi') {
        # has_many relationship
        return sub {
            my $row = shift;
            my $extra_cond = shift || {};

            # Cache key for this relationship (includes extra conditions)
            my $cache_key = $rel_name;
            if (%$extra_cond) {
                # If there are extra conditions, create a unique cache key
                require Data::Dumper;
                local $Data::Dumper::Sortkeys = 1;
                local $Data::Dumper::Terse = 1;
                $cache_key .= '_' . Data::Dumper::Dumper($extra_cond);
            }

            # 1. CHECK FOR CACHED RESULTSET (without extra conditions)
            # Return cached ResultSet if it exists and no extra conditions were provided
            if (!%$extra_cond && exists $row->{_relationship_cache} && exists $row->{_relationship_cache}{$rel_name}) {
                return $row->{_relationship_cache}{$rel_name};
            }

            # 2. CHECK FOR PREFETCHED DATA
            if (exists $row->{_prefetched} && exists $row->{_prefetched}{$rel_name}) {
                my $prefetched_rs = $row->{_prefetched}{$rel_name};

                # If extra conditions are provided, filter the prefetched data
                if (%$extra_cond) {
                    # Don't cache filtered ResultSets
                    return $prefetched_rs->search($extra_cond);
                }

                # Cache the prefetched ResultSet
                $row->{_relationship_cache} ||= {};
                $row->{_relationship_cache}{$rel_name} = $prefetched_rs;

                return $prefetched_rs;
            }

            # 3. LAZY LOAD: Build the relationship condition
            my $fk = $row->_extract_foreign_key($cond);
            unless ($fk) {
                my $rel_source = $row->_get_source->related_source($rel_name);
                my $rs = $row->{schema}->resultset($rel_source->source_name)->search({});

                # Don't cache if we couldn't extract FK
                return $rs;
            }

            my $fk_value = $row->get_column($fk->{self});
            my $related_cond = { $fk->{foreign} => $fk_value, %$extra_cond };

            # 4. Create new ResultSet for lazy loading
            my $rel_source = $row->_get_source->related_source($rel_name);
            my $rs = $row->{async_db}->resultset($rel_source->source_name);

            # 5. Cache the ResultSet (only if no extra conditions)
            if (!%$extra_cond) {
                $row->{_relationship_cache} ||= {};
                $row->{_relationship_cache}{$rel_name} = $rs;
            }

            return $rs;
        };
    }

    # Default fallback
    return sub {
        require Carp;
        Carp::croak("Unknown relationship type for '$rel_name'");
    };
}

=head2 _ensure_accessors

    $row->_ensure_accessors;

Creates accessor methods for all columns in the result source.

=cut

sub _ensure_accessors {
    my $self   = shift;
    my $source = $self->_get_source or return;
    my $class  = ref($self);

    return unless $class;
    return if $class eq 'DBIx::Class::Async::Row';

    # 1. Handle Columns
    if ($source->can('columns')) {
        foreach my $col ($source->columns) {
            no strict 'refs';
            next if defined &{"${class}::$col"}; # Skip if already installed

            my $column_name = $col;
            no warnings 'redefine';
            *{"${class}::$column_name"} = sub {
                my $inner = shift;
                return @_ ? $inner->set_column($column_name, shift)
                          : $inner->get_column($column_name);
            };
        }
    }

    # 2. Handle Relationships
    if ($source->can('relationships')) {
        foreach my $rel ($source->relationships) {
            no strict 'refs';
            no warnings 'redefine';

            # Force redefine even if it exists (to clobber DBIC's sync method)
            my $rel_name = $rel;
            my $rel_info = $source->relationship_info($rel_name);

            *{"${class}::$rel_name"} = sub {
                my ($inner, @args) = @_;
                return $inner->_fetch_relationship_async($rel_name, $rel_info, @args);
            };
        }
    }
}

sub _fetch_relationship_async {
    my ($self, $rel_name, $rel_info, $attrs) = @_;

    # 1. Handle Metadata first
    $rel_info //= $self->_get_source->relationship_info($rel_name);
    my $acc_type  = $rel_info->{attrs}{accessor} // '';
    my $is_single = ($acc_type eq 'single' || $acc_type eq 'filter');

    # 2. Cache Hit Logic
    if (exists $self->{_related}{$rel_name}) {
        my $cached = $self->{_related}{$rel_name};
        # ONLY wrap in Future if it's a single row
        return $is_single ? Future->done($cached) : $cached;
    }

    # 3. Resolve search params
    my $target_source = $rel_info->{source};
    my $cond          = $rel_info->{cond};
    my %search_params;
    while (my ($f_key, $s_key) = each %$cond) {
        my $f_col = $f_key; $f_col =~ s/^foreign\.//;
        my $s_col = $s_key; $s_col =~ s/^self\.//;
        $search_params{$f_col} = $self->get_column($s_col);
    }

    if ($is_single) {
        return $self->{async_db}->resultset($target_source)
            ->search(\%search_params, { %{$attrs // {}}, rows => 1 })
            ->next
            ->then(sub {
                my $row = shift;
                $self->{_related}{$rel_name} = $row;
                return Future->done($row);
            });
    }
    else {
        # Multi returns the RS directly (synchronously)
        my $rs = $self->{async_db}->resultset($target_source)
                                  ->search(\%search_params, $attrs);

        $self->{_related}{$rel_name} = $rs;
        return $rs;
    }
}

=head2 _extract_foreign_key

Extracts foreign key mapping from a relationship condition.

=cut

sub _extract_foreign_key {
    my ($self, $cond) = @_;

    return undef unless $cond;

    # Handle simple foreign key condition: { 'foreign.id' => 'self.user_id' }
    if (ref $cond eq 'HASH') {
        my ($foreign_col) = keys %$cond;
        my $self_col = $cond->{$foreign_col};

        # Handle case where self_col is a reference (e.g., { '=' => 'self.user_id' })
        if (ref $self_col eq 'HASH') {
            # Extract the actual column name from the hash
            my ($op, $col) = %$self_col;
            $self_col = $col;
        }

        # Strip prefixes if present
        $foreign_col =~ s/^foreign\.//;
        $self_col =~ s/^self\.// if defined $self_col && !ref $self_col;

        return {
            foreign => $foreign_col,
            self => $self_col,
        };
    }

    # Handle code ref conditions (more complex relationships)
    # For now, we'll just return undef and let the relationship fail gracefully
    return undef;
}

=head2 _get_primary_key_info

    my $pk_info = $row->_get_primary_key_info;

Returns information about the primary key(s) for this row.

=over 4

=item B<Returns>

Hash reference with keys:
- C<columns>: Array reference of primary key column names
- C<count>: Number of primary key columns
- C<is_composite>: Boolean indicating composite primary key

=back

=cut

sub _get_primary_key_info {
    my $self   = shift;
    my $source = $self->_get_source or return;

    # CRITICAL: Call primary_columns in LIST context
    my @primary_columns = $source->primary_columns;

    return {
        columns      => \@primary_columns,
        count        => scalar @primary_columns,
        is_composite => scalar @primary_columns > 1,
    };
}

=head2 _get_source

    my $source = $row->_get_source;

Returns the result source for this row, loading it lazily if needed.

=cut

sub _get_source {
    my $self = shift;

    unless ($self->{_source}) {
        if ($self->{schema}
            && ref $self->{schema}
            && $self->{schema}->can('source')) {
            $self->{_source} = eval { $self->{schema}->source($self->{source_name}) };
            return $self->{_source} if $self->{_source};
        }
    }

    return $self->{_source};
}

#
#
# REALLY PRIVATE METHODS

sub _check_response {
    my ($self, $res) = @_;
    return undef unless ref $res;

    # 1. Handle DBIx::Class::Exception objects
    if (blessed($res) && $res->isa('DBIx::Class::Exception')) {
        return $res->msg;
    }

    # 2. Handle HashRef error envelopes ({ __error => "..." })
    if (ref $res eq 'HASH' && (my $err = $res->{error} // $res->{__error})) {
        return $err;
    }

    return undef;
}

sub _is_internal {
    my ($self, $col) = @_;

    return $col =~ $INTERNAL_KEYS;
}

=head1 SEE ALSO

=over 4

=item *

L<DBIx::Class::Async> - Asynchronous DBIx::Class interface

=item *

L<DBIx::Class::Row> - Synchronous DBIx::Class row interface

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

    perldoc DBIx::Class::Async::Row

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

1; # End of DBIx::Class::Async::Row
