package Alzabo::Table;

use strict;
use vars qw($VERSION);

use Alzabo;

use Params::Validate qw( :all );
Params::Validate::validation_options( on_fail => sub { Alzabo::Exception::Params->throw( error => join '', @_ ) } );

use Tie::IxHash;

$VERSION = 2.0;

1;

sub schema
{
    my $self = shift;

    return $self->{schema};
}

sub name
{
    my $self = shift;

    return $self->{name};
}

use constant HAS_COLUMN_SPEC => { type => SCALAR };

sub has_column
{
    my $self = shift;

    validate_pos( @_, HAS_COLUMN_SPEC );

    return $self->{columns}->FETCH(shift);
}

sub column
{
    my $self = shift;
    my $name = shift;

    if ( my $col = $self->{columns}->FETCH($name) )
    {
        return $col;
    }
    else
    {
        Alzabo::Exception::Params->throw
            ( error => "Column $name doesn't exist in $self->{name}" );
    }
}

sub columns
{
    my $self = shift;

    return $self->column(@_) if @_ ==1 ;
    return map { $self->column($_) } @_ if @_ > 1;
    return $self->{columns}->Values;
}

sub primary_key
{
    my $self = shift;

    return unless @{ $self->{pk} };

    return ( wantarray ?
             $self->{columns}->Values( @{ $self->{pk} } ) :
             $self->{columns}->Values( $self->{pk}[0] )
           );
}

sub primary_key_size
{
    my $self = shift;

    return scalar @{ $self->{pk} };
}

use constant COLUMN_IS_PRIMARY_KEY_SPEC => { isa => 'Alzabo::Column' };

sub column_is_primary_key
{
    my $self = shift;

    validate_pos( @_, COLUMN_IS_PRIMARY_KEY_SPEC );

    my $name = shift->name;

    Alzabo::Exception::Params->throw( error => "Column $name doesn't exist in $self->{name}" )
        unless $self->{columns}->EXISTS($name);

    my $idx = $self->{columns}->Indices($name);
    return 1 if grep { $idx == $_ } @{ $self->{pk} };

    return 0;
}

sub attributes
{
    return keys %{ $_[0]->{attributes} };
}

use constant HAS_ATTRIBUTE_SPEC => { attribute => { type => SCALAR },
                                     case_sensitive => { type => SCALAR,
                                                         default => 0 },
                                   };

sub has_attribute
{
    my $self = shift;
    my %p = validate( @_, HAS_ATTRIBUTE_SPEC );

    if ( $p{case_sensitive} )
    {
        return exists $self->{attributes}{ $p{attribute} };
    }
    else
    {
        return 1 if grep { lc $p{attribute} eq lc $_ } keys %{ $self->{attributes} };
    }
}

use constant FOREIGN_KEYS_SPEC => { column => { isa => 'Alzabo::Column' },
                                    table  => { isa => 'Alzabo::Table' },
                                  };

sub foreign_keys
{
    my $self = shift;

    validate( @_, FOREIGN_KEYS_SPEC );
    my %p = @_;

    my $c_name = $p{column}->name;
    my $t_name = $p{table}->name;

    Alzabo::Exception::Params->throw( error => "Column $c_name doesn't exist in $self->{name}" )
        unless $self->{columns}->EXISTS($c_name);

    Alzabo::Exception::Params->throw( error => "No foreign keys to $t_name exist in $self->{name}" )
        unless exists $self->{fk}{$t_name};

    Alzabo::Exception::Params->throw( error => "Column $c_name is not a foreign key to $t_name in $self->{name}" )
        unless exists $self->{fk}{$t_name}{$c_name};

    return wantarray ? @{ $self->{fk}{$t_name}{$c_name} } : $self->{fk}{$t_name}{$c_name}[0];
}

use constant FOREIGN_KEYS_BY_TABLE_SPEC => { isa => 'Alzabo::Table' };

sub foreign_keys_by_table
{
    my $self = shift;

    validate_pos( @_, FOREIGN_KEYS_BY_TABLE_SPEC );
    my $name = shift->name;

    my $fk = $self->{fk};

    my %fk;
    if ( exists $fk->{$name} )
    {
        foreach my $c ( keys %{ $fk->{$name} } )
        {
            return $fk->{$name}{$c}[0] unless wantarray;

            $fk{$_} = $_ for @{ $fk->{$name}{$c} };
        }
    }

    return values %fk;
}

use constant FOREIGN_KEYS_BY_COLUMN_SPEC => { isa => 'Alzabo::Column' };

sub foreign_keys_by_column
{
    my $self = shift;

    my ($col) = validate_pos( @_, FOREIGN_KEYS_BY_COLUMN_SPEC );

    Alzabo::Exception::Params->throw( error => "Column " . $col->name . " doesn't exist in $self->{name}" )
        unless $self->{columns}->EXISTS( $col->name );

    my $fk = $self->{fk};

    my %fk;
    foreach my $t (keys %$fk)
    {
        if ( exists $fk->{$t}{ $col->name } )
        {
            return $fk->{$t}{ $col->name }[0] unless wantarray;

            $fk{$_} = $_ for @{ $fk->{$t}{ $col->name } };
        }
    }

    return values %fk;
}

sub all_foreign_keys
{
    my $self = shift;

    my %seen;
    my @fk;
    my $fk = $self->{fk};
    foreach my $t (keys %$fk)
    {
        foreach my $c ( keys %{ $fk->{$t} } )
        {
            foreach my $key ( @{ $fk->{$t}{$c} } )
            {
                next if $seen{$key};
                push @fk, $key;
                $seen{$key} = 1;
            }
        }
    }

    return wantarray ? @fk : $fk[0];
}

sub index
{
    my $self = shift;

    validate_pos( @_, { type => SCALAR } );
    my $id = shift;

    Alzabo::Exception::Params->throw( error => "Index $id doesn't exist in $self->{name}" )
        unless $self->{indexes}->EXISTS($id);

    return $self->{indexes}->FETCH($id);
}

sub has_index
{
    my $self = shift;

    validate_pos( @_, { type => SCALAR } );
    my $id = shift;

    return $self->{indexes}->EXISTS($id);
}

sub indexes
{
    my $self = shift;

    return $self->{indexes}->Values;
}

sub comment { $_[0]->{comment} }

__END__

=head1 NAME

Alzabo::Table - Table objects

=head1 SYNOPSIS

  use Alzabo::Table;

  my $t = $schema->table('foo');

  foreach $pk ($t->primary_keys)
  {
     print $pk->name;
  }

=head1 DESCRIPTION

Objects in this class represent tables.  They contain foreign key,
index, and column objects.

=head1 METHODS

=head2 schema

Returns the L<C<Alzabo::Schema>|Alzabo::Schema> object to which this
table belongs.

=head2 name

Returns the name of the table.

=head2 column ($name)

Returns the L<C<Alzabo::Column>|Alzabo::Column> object that matches
the name given.

An L<C<Alzabo::Exception::Params>|Alzabo::Exceptions> exception is
throws if the table does not contain the column.

=head2 columns (@optional_list_of_column_names)

If no arguments are given, returns a list of all
L<C<Alzabo::Column>|Alzabo::Column> objects in the schema, or in a
scalar context the number of such tables.  If one or more arguments
are given, returns a list of table objects with those names, in the
same order given.

An L<C<Alzabo::Exception::Params>|Alzabo::Exceptions> exception is
throws if the table does not contain one or more of the specified
columns.

=head2 has_column ($name)

Returns a voolean value indicating whether the column exists in the
table.

=head2 primary_key

In array context, return an ordered list of column objects that make
up the primary key for the table.  In scalar context, it returns the
first element of that list.

=head2 primary_key_size

The number of columns in the table's primary key.

=head2 column_is_primary_key (C<Alzabo::Column> object)

Returns a boolean value indicating whether the column given is part of
the table's primary key.

This method is really only needed if you're not sure that the column
belongs to the table.  Otherwise just call the
L<C<< Alzabo::Column->is_primary_key >>|Alzabo::Column/is_primary_key>
method on the column object.

=head2 attributes

A table's attributes are strings describing the table (for example,
valid attributes in MySQL are thing like "TYPE = INNODB".

Returns a list of strings.

=head2 has_attribute

This method can be used to test whether or not a table has a
particular attribute.  By default, the check is case-insensitive.

=over 4

=item * attribute => $attribute

=item * case_sensitive => 0 or 1 (defaults to 0)

=back

Returns a boolean value indicating whether the table has this
particular attribute.

=head2 foreign_keys

Thie method takes two parameters:

=over 4

=item * column => C<Alzabo::Column> object

=item * table  => C<Alzabo::Table> object

=back

It returns a list of L<C<Alzabo::ForeignKey>|Alzabo::ForeignKey>
objects B<from> the given column B<to> the given table, if they exist.
In scalar context, it returns the first item in the list.  There is no
guarantee as to what the first item will be.

An L<C<Alzabo::Exception::Params>|Alzabo::Exceptions> exception is
throws if the table does not contain the specified column.

=head2 foreign_keys_by_table (C<Alzabo::Table> object)

Returns a list of all the L<C<Alzabo::ForeignKey>|Alzabo::ForeignKey>
objects B<to> the given table.  In scalar context, it returns the
first item in the list.  There is no guarantee as to what the first
item will be.

=head2 foreign_keys_by_column (C<Alzabo::Column> object)

Returns a list of all the L<C<Alzabo::ForeignKey>|Alzabo::ForeignKey>
objects that the given column is a part of, if any.  In scalar
context, it returns the first item in the list.  There is no guarantee
as to what the first item will be.

An L<C<Alzabo::Exception::Params>|Alzabo::Exceptions> exception is
throws if the table does not contain the specified column.

=head2 all_foreign_keys

Returns a list of all the L<C<Alzabo::ForeignKey>|Alzabo::ForeignKey>
objects for this table.  In scalar context, it returns the first item
in the list.  There is no guarantee as to what the first item will be.

=head2 index ($index_id)

This method expects an index id as returned by the
L<C<Alzabo::Index-E<gt>id>|Alzabo::Index/id> method as its parameter.

The L<C<Alzabo::Index>|Alzabo::Index> object matching this id, if it
exists in the table.

An L<C<Alzabo::Exception::Params>|Alzabo::Exceptions> exception is
throws if the table does not contain the specified index.

=head2 has_index ($index_id)

This method expects an index id as returned by the
L<C<Alzabo::Index-E<gt>id>|Alzabo::Index/id> method as its parameter.

Returns a boolean indicating whether the table has an index with the
same id.

=head2 indexes

Returns all the L<C<Alzabo::Index>|Alzabo::Index> objects for the
table.

=head2 comment

Returns the comment associated with the table object, if any.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
