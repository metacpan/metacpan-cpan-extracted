package Astro::STSDAS::Table::HeaderPar;

require 5.005_62;
use strict;
use warnings;

use Carp;

our $VERSION = '0.01';

use Astro::STSDAS::Table::Constants;

our @hdrkeys = qw( idx name value comment type );


sub new
{
  my $class = shift;
  $class = ref($class) || $class;
  
  my $self = bless {}, $class;
  
  @{$self}{@hdrkeys} = @_;

  $self->{name} = uc $self->{name};
  
  croak( __PACKAGE__, '->new: illegal header type' )
    if defined $self->{type} && ! exists $Types{$self->{type}};

  $self;
}

sub name 
{ 
  my $self = shift;
  $self->{name} = uc $_[0] if @_;
  $self->{name};
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
  *$_ = _access_rw( $_ ) foreach qw( value comment type );
  
  *$_ = _access_ro( $_ ) foreach qw( idx );
}

sub copy
{
  $_[0]->new( @{$_[0]}{@hdrkeys} );
}


1;
__END__

=head1 NAME

Astro::STSDAS::Table::HeaderPar - a header parameter

=head1 SYNOPSIS

  use Astro::STSDAS::Table::HeaderPar;


=head1 DESCRIPTION

An B<Astro::STSDAS::Table::HeaderPar> object encapsulates an B<Astro::STSDAS::Table> header parameter.  The following attributes exist for a parameter:

=over

=item idx

The unary based index of the parameter in the list of parameters.

=item name

The parameter name.  It is stored in all upper case.

=item value

The parameter value.  It is always stored as an ASCII string.

=item comment

An optional header comment.  This is available only for STSDAS format
text tables.

=item type

An optional type.  This is somewhat meaningless as the header value is
stored as an ASCII string.  It is available only for STSDAS format
binary Tables.

=back

=head2 Accessing attributes

Each attribute has an eponymously named method with which the attribute value
may be retrieved.  The method may also be used to set attributes' values
for modifiable attributes.  For example:

   $oldname = $col->name;
   $col->name( $newname );

Modifiable attributes are: C<name>, C<value>, C<comment>, C<type>.  If
a set of header parameters is being managed in an
B<Astro::STSDAS::Table::HeaderPars> container, it is very important to
use that container's B<rename> method to change a column's name, else
the container will get very confused.

=head2 Other Methods

=over 8

=item new

  $column = Astro::STSDAS::Table::HeaderPar->new(
             $idx, $name, $value, $comment, $type );

This is the constructor.  It returns an
B<Astro::STSDAS::Table::HeaderPar> object.  Attributes which are
inappropriate for the column may be passed as B<undef>.  See above for
the definition of the attributes. This is generally only called by a
B<Astro::STSDAS::Table::HeaderPars> object.

=item copy

This returns a copy of the parameter (as an B<Astro::STSDAS::Table::HeaderPar>
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
