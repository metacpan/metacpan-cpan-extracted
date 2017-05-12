package Alzabo::Column;

use strict;
use vars qw($VERSION);

use Alzabo;

use Tie::IxHash;

use Params::Validate qw( :all );
Params::Validate::validation_options( on_fail => sub { Alzabo::Exception::Params->throw( error => join '', @_ ) } );

$VERSION = 2.0;

1;

sub table
{
    $_[0]->{table};
}

sub name
{
    $_[0]->{name};
}

sub nullable
{
    $_[0]->{nullable};
}

sub attributes
{
    return keys %{ $_[0]->{attributes} };
}

sub has_attribute
{
    my $self = shift;
    my %p = validate( @_, { attribute => { type => SCALAR },
                            case_sensitive => { type => SCALAR,
                                                default => 0 } } );

    if ( $p{case_sensitive} )
    {
        return exists $self->{attributes}{ $p{attribute} };
    }
    else
    {
        return 1 if grep { lc $p{attribute} eq lc $_ } keys %{ $self->{attributes} };
    }
}

sub type
{
    $_[0]->definition->type;
}

sub sequenced
{
    $_[0]->{sequenced};
}

sub default
{
    $_[0]->{default};
}

sub default_is_raw
{
    $_[0]->{default_is_raw};
}

sub length
{
    $_[0]->definition->length;
}

sub precision
{
    $_[0]->definition->precision;
}

sub definition
{
    $_[0]->{definition};
}

sub is_primary_key
{
    $_[0]->table->column_is_primary_key($_[0]);
}

sub is_numeric
{
    $_[0]->table->schema->rules->type_is_numeric($_[0]);
}

sub is_integer
{
    $_[0]->table->schema->rules->type_is_integer($_[0]);
}

sub is_floating_point
{
    $_[0]->table->schema->rules->type_is_floating_point($_[0]);
}

sub is_character
{
    $_[0]->table->schema->rules->type_is_char($_[0]);
}

sub is_date
{
    $_[0]->table->schema->rules->type_is_date($_[0]);
}

sub is_datetime
{
    $_[0]->table->schema->rules->type_is_datetime($_[0]);
}

sub is_time
{
    $_[0]->table->schema->rules->type_is_time($_[0]);
}

sub is_time_interval
{
    $_[0]->table->schema->rules->type_is_time_interval($_[0]);
}

sub is_blob
{
    $_[0]->table->schema->rules->type_is_blob($_[0]);
}

sub generic_type
{
    my $self = shift;

    foreach my $type ( qw( integer floating_point character date datetime time blob ) )
    {
        my $method = "is_$type";
        return $type if $self->$method();
    }

    return 'unknown';
}

sub comment { $_[0]->{comment} }

__END__

=head1 NAME

Alzabo::Column - Column objects

=head1 SYNOPSIS

  use Alzabo::Column;

  foreach my $c ($table->columns)
  {
      print $c->name;
  }

=head1 DESCRIPTION

This object represents a column.  It holds data specific to a column.

=head1 METHODS

=head2 table

Returns the table object to which this column belongs.

=head2 name

Returns the column's name as a string.

=head2 nullable

Returns a boolean value indicating whether or not NULLs are allowed in
this column.

=head2 attributes

A column's attributes are strings describing the column (for example,
valid attributes in MySQL are 'UNSIGNED' or 'ZEROFILL'.

This method returns a list of strings of such strings.

=head2 has_attribute

This method can be used to test whether or not a column has a
particular attribute.  By default, the check is case-insensitive.

It takes the following parameters:

=over 4

=item * attribute => $attribute

=item * case_sensitive => 0 or 1 (defaults to 0)

=back

It returns a boolean value indicating whether or not the column has
this particular attribute.

=head2 type

Returns the column's type as a string.

=head2 sequenced

The meaning of a sequenced column varies from one RDBMS to another.
In those with sequences, it means that a sequence is created and that
values for this column will be drawn from it for inserts into this
table.  In databases without sequences, the nearest analog for a
sequence is used (in MySQL the column is given the AUTO_INCREMENT
attribute, in Sybase the identity attribute).

In general, this only has meaning for the primary key column of a
table with a single column primary key.  Setting the column as
sequenced means its value never has to be provided to when calling
C<Alzabo::Runtime::Table-E<gt>insert>.

Returns a boolean value indicating whether or not this column is
sequenced.

=head2 default

Returns the default value of the column as a string, or undef if there
is no default.

=head2 default_is_raw

Returns true if the default is intended to be provided to the DBMS
as-is, without quoting, fore example C<NOW()> or C<current_timestamp>.

=head2 length

Returns the length attribute of the column, or undef if there is none.

=head2 precision

Returns the precision attribute of the column, or undef if there is
none.

=head2 is_primary_key

Returns a boolean value indicating whether or not this column is part
of its table's primary key.

=head2 is_numeric

Returns a boolean value indicating whether the column is a numeric
type column.

=head2 is_integer

Returns a boolean value indicating whether the column is a numeric
type column.

=head2 is_floating_point

Returns a boolean value indicating whether the column is a numeric
type column.

=head2 is_character

Returns a boolean value indicating whether the column is a character
type column.

This is true only for any columns which are defined to hold I<text>
data, regardless of size.

=head2 is_date

Returns a boolean value indicating whether the column is a date type
column.

=head2 is_datetime

Returns a boolean value indicating whether the column is a datetime
type column.

=head2 is_time

Returns a boolean value indicating whether the column is a time type
column.

=head2 is_time_interval

Returns a boolean value indicating whether the column is a time
interval type column.

=head2 is_blob

Returns a boolean value indicating whether the column is a blob
column.

This is true for any columns defined to hold binary data, regardless
of size.

=head2 generic_type

This methods returns one of the following strings:

=over 4

=item integer

=item floating_point

=item character

=item date

=item datetime

=item time

=item blob

=item unknown

=back

=head2 definition

The definition object is very rarely of interest.  Use the
L<C<type()>|type> method if you are only interested in the column's
type.


This methods returns the
L<C<Alzabo::ColumnDefinition>|Alzabo::ColumnDefinition> object which
holds this column's type information.

=head2 comment

Returns the comment associated with the column object, if any.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
