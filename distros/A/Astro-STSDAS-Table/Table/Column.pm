package Astro::STSDAS::Table::Column;

require 5.005_62;
use strict;
use warnings;

use Carp;

our $VERSION = '0.01';

use Astro::STSDAS::Table::Constants;
  
  # Column attributes
  #
  # All tables:
  #
  #  name	        - the column name
  #  units	- the units string
  #  format	- the format string
  #  idx		- the column number (unary based)
  #
  # Binary Tables:
  #
  #  offset       - the byte offset from the start of the row
  #		    (for row ordered tables)
  #
  #  type         - the data representation type (TY_REAL,
  #  	          TY_DOUBLE, TY_INT, etc.)  see the constants defined
  #  	          above
  #
  #  nelem	- the number of elements in the cell. if the data type
  #                 is TY_STRING, this is the maximum number of
  #		  characters.  if not a string, and if greater than
  #		  one, it indicates a vector.
  #
  #  fmt          - the pack() compatible format to parse this column
  #                 (taking into account vectors)
  #
  #  size         - # bytes in the data type
  #  ifmt	  - pack() compatible format for this type (doesn't take
  #                 into account vectors)

our @colkeys = qw { name units format idx offset type nelem };
  
sub new
{
  my $class = shift;
  $class = ref($class) || $class;
  
  my $self = bless {}, $class;
  
  @{$self}{@colkeys} = @_;
  
  $self->{nelem} = 1 unless defined $self->{nelem};

  if ( defined $self->{type} )
  {
    croak( __PACKAGE__, '->new: illegal column type' )
      unless exists $Types{$self->{type}};
    $self->{size} = $TypeSize{$self->{type}};
    $self->{fmt} = $self->{ifmt} = $TypeUPack{$self->{type}};
    $self->{fmt} .= $self->{nelem} if $self->{nelem} > 1;
    $self->{indef} = $TypeIndef{$self->{type}};
  }
  
  $self;
}
  
sub _access_rw
{
  my $what = shift;
  
  sub { 
    my $self = shift;
    $self->{$what} = $_[0] if @_;
    $self->{$what};
  }
}

sub _access_ro
{
  my $what = shift;
  sub { croak( __PACKAGE__, "->$what: attempt to write to RO attribute" )
	  if @_ > 1;
	$_[0]->{$what}
      }
}

{ 
  no strict 'refs';
  *$_ = _access_rw( $_ ) 
    foreach qw( name units format );
  
  *$_ = _access_ro( $_ )
    foreach qw ( idx offset type fmt size ifmt );
}

sub is_string
{
  defined $_[0]->{type} ? ($_[0]->{type} == TY_STRING ? 1 : 0) : undef;
}

sub is_indef
{
  $_[0]->{type} != TY_STRING && $_[0]->{indef} == $_[1];
}

sub is_vector
{
  $_[0]->{type} != TY_STRING && $_[0]->{nelem} > 1;
}

sub nelem
{
  croak( __PACKAGE__, "->nelem: attempt to write to RO attribute" )
	  if @_ > 1;

  defined $_[0]->{type} && $_[0]->{type} == TY_STRING ? 
    1 : $_[0]->{nelem};
}

sub copy
{
  $_[0]->new( @{$_[0]}{@colkeys} );
}

1;
__END__

=head1 NAME

Astro::STSDAS::Table::Column - An object representing column information

=head1 SYNOPSIS

  use Astro::STSDAS::Table::Column;


=head1 DESCRIPTION

An B<Astro::STSDAS::Table::Column> object represents a single column
in an STSDAS table.  It does not store data for the column; it simply
manages attributes of the column.  The following attributes exist
for all columns:

=over 8

=item name

the column name

=item units

the column units

=item format

the column format

=item idx

the index of the column in the table (unary based)

=back

Binary table columns have the following additional attributes:

=over 

=item offset

the byte offset from the start of the row (for row ordered tables)

=item type

the data representation type.  See B<Astro::STSDAS::Table::Constants>.

=item nelem

the number of items in a column element. If the data type is a string,
this is the maximum number of characters.  if not a string, and if
greater than one, it indicates a vector.

=item fmt

A Perl B<pack()> compatible format used to parse this column.  This
takes into account the number of elements in a vector.

=item size

The number of bytes in the data type

=item ifmt

A Perl B<pack()> compatible format used to parse this column.  This
I<does not> take into account the number of elements in a vector.

=back


=head2 Accessing attributes

Each attribute has an eponymously named method with which the attribute value
may be retrieved.  The method may also be used to set attributes' values
for modifiable attributes.  For example:

   $oldname = $col->name;
   $col->name( $newname );

Modifiable attributes are: C<name>, C<units>, C<format>.  If a set of columns
is being managed in an B<Astro::STSDAS::Table::Columns> container, it is
very important to use that container's B<rename> method to change a
column's name, else the container will get very confused.

=head2 Other Methods

=over 8

=item new

  $column = Astro::STSDAS::Table::Column->new(
             $name, $units, $format, $idx, $offset, $type, $nelem );

This is the constructor.  It returns an
B<Astro::STSDAS::Table::Column> object.  Attributes which are
inappropriate for the column may be passed as B<undef>.  See above for
the definition of the attributes. This is generally only called by a
B<Astro::STSDAS::Table::Columns> object.

=item is_string

This returns true if the column is a string column.

=item is_indef

  $bad_value = $col->is_indef( $value );

This determines if the passed value matches the undefined value appropriate
to the column.

=item is_vector

Returns true if the column's elements are vectors.

=item nelem

This returns the number of items in a column element.  This will normally
be C<1>, except for vector columns.

=item copy

This returns a copy of the column (as an B<Astro::STSDAS::Table::Column>
object). 

=back


=head2 EXPORT

None by default.


=head1 LICENSE

This software is released under the GNU General Public License.  You
may find a copy at 

   http://www.fsf.org/copyleft/gpl.html

=head1 AUTHOR

Diab Jerius (djerius@cpan.org)

=head1 SEE ALSO

perl(1).

=cut
