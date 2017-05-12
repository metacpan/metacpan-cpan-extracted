package Alzabo::Runtime::Row;

use strict;
use vars qw($VERSION);

use Alzabo;

use Alzabo::Exceptions ( abbr => [ qw( logic_exception no_such_row_exception
                                       params_exception storable_exception ) ] );

use Alzabo::Runtime;
use Alzabo::Runtime::RowState::Deleted;
use Alzabo::Runtime::RowState::Live;
use Alzabo::Runtime::RowState::Potential;
use Alzabo::Utils;

use Params::Validate qw( validate validate_with UNDEF SCALAR HASHREF BOOLEAN );
Params::Validate::validation_options
    ( on_fail => sub { params_exception join '', @_ } );

use Storable ();

$VERSION = 2.0;

BEGIN
{
    no strict 'refs';
    foreach my $meth ( qw( select select_hash update refresh delete
                           id_as_string is_live is_potential is_deleted ) )
    {
        *{ __PACKAGE__ . "::$meth" } =
            sub { my $s = shift;
                  $s->{state}->$meth( $s, @_ ) };
    }
}

use constant NEW_SPEC => { table => { isa => 'Alzabo::Runtime::Table' },
                           pk    => { type => SCALAR | HASHREF,
                                      optional => 1,
                                    },
                           prefetch => { type => UNDEF | HASHREF,
                                         optional => 1,
                                       },
                           state => { type => SCALAR,
                                      default => 'Alzabo::Runtime::RowState::Live',
                                    },
                           potential_row => { isa => 'Alzabo::Runtime::Row',
                                              optional => 1,
                                            },
                           values => { type => HASHREF,
                                       default => {},
                                     },
                           no_cache => { type => BOOLEAN, default => 0 },
                         };

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %p =
        validate( @_, NEW_SPEC );

    my $self = $p{potential_row} ? $p{potential_row} : {};

    bless $self, $class;

    $self->{table} = $p{table};
    $self->{state} = $p{state};

    $self->{state}->_init($self, @_) or return;

    return $self;
}

sub table
{
    my $self = shift;

    return $self->{table};
}

sub schema
{
    my $self = shift;

    return $self->table->schema;
}

sub set_state { $_[0]->{state} = $_[1] };

use constant ROWS_BY_FOREIGN_KEY_SPEC => { foreign_key => { isa => 'Alzabo::ForeignKey' } };

sub rows_by_foreign_key
{
    my $self = shift;
    my %p = validate_with( params => \@_,
                           spec   => ROWS_BY_FOREIGN_KEY_SPEC,
                           allow_extra => 1,
                         );

    my $fk = delete $p{foreign_key};

    if ($p{where})
    {
        $p{where} = [ $p{where} ] unless Alzabo::Utils::is_arrayref( $p{where}[0] );
    }

    push @{ $p{where} },
        map { [ $_->[1], '=', $self->select( $_->[0]->name ) ] } $fk->column_pairs;

    # if the relationship is not 1..n, then only one row can be
    # returned (or referential integrity has been hosed in the
    # database).
    return $fk->is_one_to_many ? $fk->table_to->rows_where(%p) : $fk->table_to->one_row(%p);
}

# class method
sub id_as_string_ext
{
    my $class = shift;
    my %p = @_;
    my $id_hash = $class->_make_id_hash(%p);

    local $^W; # weirdly, enough there are code paths that can
    # lead here that'd lead to $id_hash having some
    # values that are undef
    return join ';:;_;:;', ( $p{table}->schema->name,
                             $p{table}->name,
                             map { $_, $id_hash->{$_} } sort keys %$id_hash );
}

sub _make_id_hash
{
    my $self = shift;
    my %p = @_;

    return $p{pk} if ref $p{pk};

    return { ($p{table}->primary_key)[0]->name => $p{pk} };
}

sub _update_pk_hash
{
    my $self = shift;

    my @pk = keys %{ $self->{pk} };

    @{ $self->{pk} }{ @pk } = @{ $self->{data} }{ @pk };

    delete $self->{id_string};
}

sub make_live
{
    my $self = shift;

    logic_exception "Can only call make_live on potential rows"
        unless $self->{state}->is_potential;

    my %p = @_;

    my %values;
    foreach ( $self->table->columns )
    {
        next unless exists $p{values}->{ $_->name } || exists $self->{data}->{ $_->name };
        $values{ $_->name } = ( exists $p{values}->{ $_->name } ?
                                $p{values}->{ $_->name } :
                                $self->{data}->{ $_->name } );
    }

    my $table = $self->table;
    delete @{ $self }{keys %$self}; # clear out everything

    $table->insert( @_,
                    potential_row => $self,
                    %values ? ( values => \%values ) : (),
                  );
}

sub _cached_data_is_same
{
    my $self = shift;
    my ( $key, $val ) = @_;

    # The convolutions here are necessary to avoid avoid treating
    # undef as being equal to 0 or ''.  Stupid NULLs.
    return 1
        if ( exists $self->{data}{$key} &&
             ( ( ! defined $val && ! defined $self->{data}{$key} ) ||
               ( defined $val &&
                 defined $self->{data}{$key} &&
                 ( $val eq $self->{data}{$key} )
               )
             )
           );

    return 0;
}

sub _no_such_row_error
{
    my $self = shift;

    my $err = 'Unable to find a row in ' . $self->table->name . ' where ';
    my @vals;
    while ( my( $k, $v ) = each %{ $self->{pk} } )
    {
        $v = '<NULL>' unless defined $v;
        my $val = "$k = $v";
        push @vals, $val;
    }
    $err .= join ', ', @vals;

    no_such_row_exception $err;
}

sub STORABLE_freeze
{
    my $self = shift;
    my $cloning = shift;

    my %data = %$self;

    my $table = delete $data{table};

    $data{schema} = $table->schema->name;
    $data{table_name} = $table->name;

    my $ser = eval { Storable::nfreeze(\%data) };

    storable_exception $@ if $@;

    return $ser;
}

sub STORABLE_thaw
{
    my ( $self, $cloning, $ser ) = @_;

    my $data = eval { Storable::thaw($ser) };

    storable_exception $@ if $@;

    %$self = %$data;

    my $s = Alzabo::Runtime::Schema->load_from_file( name => delete $self->{schema} );
    $self->{table} = $s->table( delete $self->{table_name} );

    return $self;
}

BEGIN
{
    # dumb hack to fix bugs in Storable 2.00 - 2.03 w/ a non-threaded
    # Perl
    #
    # Basically, Storable somehow screws up the hooks business the
    # _first_ time an object from a class with hooks is stored.  So
    # we'll just _force_ it do it once right away.
    if ( $Storable::VERSION >= 2 && $Storable::VERSION <= 2.03 )
    {
        eval <<'EOF';
        { package ___name; sub name { 'foo' } }
        { package ___table;  @table::ISA = '___name'; sub schema { bless {}, '___name' } }
        my $row = bless { table => bless {}, '___table' }, __PACKAGE__;
        Storable::thaw(Storable::nfreeze($row));
EOF
    }
}


1;

__END__

=head1 NAME

Alzabo::Runtime::Row - Row objects

=head1 SYNOPSIS

  use Alzabo::Runtime::Row;

  my $row = $table->row_by_pk( pk => 1 );

  $row->select('foo');

  $row->update( bar => 5 );

  $row->delete;

=head1 DESCRIPTION

These objects represent actual rows from the database containing
actual data.  In general, you will want to use the
L<C<Alzabo::Runtime::Table>|Alzabo::Runtime::Table> object to retrieve
rows.  The L<C<Alzabo::Runtime::Table>|Alzabo::Runtime::Table> object
can return either single rows or L<row
cursors|Alzabo::Runtime::RowCursor>.

=head1 ROW STATES

Row objects can have a variety of states.  Most row objects are
"live", which means they represent an actual row object.  A row can be
changed to the "deleted" state by calling its C<delete()> method.
This is a row that no longer exists in the database.  Most method
calls on rows in this state cause an exception.

There is also a "potential" state, for objects which do not represent
actual database rows.  You can call L<C<make_live()>|make_live> on
these rows in order to change their state to "live".

Finally, there is an "in cache" state, which is identical to the
"live" state, except that it is used for object's that are cached via
the
L<C<Alzabo::Runtime::UniqueRowCache>|Alzabo::Runtime::UniqueRowCache>
class.

=head1 METHODS

Row objects offer the following methods:

=head2 select (@list_of_column_names)

Returns a list of values matching the specified columns in a list
context.  In scalar context it returns only a single value (the first
column specified).

If no columns are specified, it will return the values for all of the
columns in the table, in the order that are returned by
L<C<Alzabo::Runtime::Table-E<gt>columns>|Alzabo::Runtime::Table/columns>.

This method throws an
L<C<Alzabo::Runtime::NoSuchRowException>|Alzabo::Exceptions> if called
on a deleted row.

=head2 select_hash (@list_of_column_names)

Returns a hash of column names to values matching the specified
columns.

If no columns are specified, it will return the values for all of the
columns in the table.

This method throws an
L<C<Alzabo::Runtime::NoSuchRowException>|Alzabo::Exceptions> if called
on a deleted row.

=head2 update (%hash_of_columns_and_values)

Given a hash of columns and values, attempts to update the database to
and the object to represent these new values.

It returns a boolean value indicating whether or not any data was
actually modified.

This method throws an
L<C<Alzabo::Runtime::NoSuchRowException>|Alzabo::Exceptions> if called
on a deleted row.

=head2 refresh

Refreshes the object against the database.  This can be used when you
want to ensure that a row object is up to date in regards to the
database state.

This method throws an
L<C<Alzabo::Runtime::NoSuchRowException>|Alzabo::Exceptions> if called
on a deleted row.

=head2 delete

Deletes the row from the RDBMS and changes the object's state to
deleted.

For potential rows, this method simply changes the object's state.

This method throws an
L<C<Alzabo::Runtime::NoSuchRowException>|Alzabo::Exceptions> if called
on a deleted row.

=head2 id_as_string

Returns the row's id value as a string.  This can be passed to the
L<C<Alzabo::Runtime::Table-E<gt>row_by_id>|Alzabo::Runtime::Table/row_by_id>
method to recreate the row later.

For potential rows, this method always return an empty string.

This method throws an
L<C<Alzabo::Runtime::NoSuchRowException>|Alzabo::Exceptions> if called
on a deleted row.

=head2 is_live

Indicates whether or not the given row represents an actual row in the
database.

=head2 is_potential

Indicates whether or not the given row represents an actual row in the
datatbase.

=head2 is_deleted

Indicates whether or not the given row has been deleted

=head2 table

Returns the L<C<Alzabo::Runtime::Table>|Alzabo::Runtime::Table> object
that this row belongs to.

=head2 schema

Returns the L<C<Alzabo::Runtime::Schema>|Alzabo::Runtime::Schema>
object that this row's table belongs to.  This is a shortcut for C<<
$row->table->schema >>.

=head2 rows_by_foreign_key

This method is used to retrieve row objects from other tables by
"following" a relationship between two tables.

It takes the following parameters:

=over 4

=item * foreign_key => C<Alzabo::Runtime::ForeignKey> object

=back

Given a foreign key object, this method returns either a row object or
a row cursor object the row(s) in the table to which the relationship
exist.

The type of object returned is based on the cardinality of the
relationship.  If the relationship says that there could only be one
matching row, then a row object is returned, otherwise it returns a
cursor.

=head1 POTENTIAL ROWS

The "potential" row state is used for rows which do not yet exist in
the database.  These are created via the L<C<<
Alzabo::Runtime::Table->potential_row
>>|Alzabo::Runtime::Table/potential_row> method.

They are useful when you need a placeholder object which you can
update and select from, but you don't actually want to commit the data
to the database.

These objects are not cached.

Once L<C<make_live()>|/make_live> is called, the object's state
becomes "live".

Potential rows have looser constraints for column values than regular
rows.  When creating a new potential row, it is ok if none of the
columns are defined.  If a column has a default, and a value for that
column is not given, then the default will be used.  However, you
cannot update a column in a potential row to undef (NULL) if the
column is not nullable.

No attempt is made to enforce L<referential integrity
constraints|Alzabo/Referential Integrity> on these objects.

You cannot set a column's value to a database function like "NOW()",
because this requires interaction with the database.

=head2 make_live

This method inserts the row into the database and changes the object's
state to "live".

This means that all references to the potential row object will now be
references to the real object (which is a good thing).

This method can take any parameters that can be passed to the
L<C<Alzabo::Runtime::Table-E<gt>insert>|Alzabo::Runtime::Table/insert>
method.

Any columns already set will be passed to the C<insert> method,
including primary key values.  However, these will be overridden, on
a column by column basis, by a "pk" or "values" parameters given to
the C<(make_live()> method.

Calling this method on a row object that is not in the "potential"
state will cause an
L<C<Alzabo::Runtime::LogicException>|Alzabo::Exceptions>

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
