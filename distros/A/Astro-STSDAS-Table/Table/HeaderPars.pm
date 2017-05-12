package Astro::STSDAS::Table::HeaderPars;

require 5.005_62;
use strict;
use warnings;

use Carp;

our $VERSION = '0.02';

use Astro::STSDAS::Table::HeaderPar;

# manages the header parameters

sub new
{
  my $class = shift;
  $class = ref($class) || $class;


  my $self = {
	      vars => {},
	      idx => 0,
	      };

  bless $self, $class;
}

sub npars
{
  scalar keys %{$_[0]->{vars}};
}

sub add
{
  my $self = shift;

  my $name = uc shift;

  $self->_add( 
	      Astro::STSDAS::Table::HeaderPar->new( ++$self->{idx},
							  $name, @_ ) );
}

sub _add
{
  my ( $self, $par ) = @_;

  if ( exists $self->{vars}{uc $par->name} )
  {
    $self->{idx}--;
    croak( __PACKAGE__, "->add: duplicate parameter name `",
	   $par->name, "'\n" );
  }

  $self->{vars}{$par->name} = $par;

  $par;
}

sub pars
{
  return sort { $a->idx <=> $b->idx } values %{$_[0]->{vars}};
}

sub byname
{
  my $name = uc $_[1];
  return undef unless exists $_[0]->{vars}{$name};
  $_[0]->{vars}{$name};
}


sub delbyname
{
  my $self = shift;
  my $name = uc shift;

  return 0 unless exists $self->{vars}{$name};

  delete $self->{vars}{$name};
  1;
}

sub rename
{
  my ( $self, $name, $newname ) = @_;

  my $hdrp = $self->byname($name);
  return undef unless defined $hdrp;

  $self->delbyname( $name );

  $hdrp->name($newname);
  $self->_add( $hdrp );
}


sub copy
{
  my $self = shift;

  my $new = $self->new;

  $new->_add( $_->copy ) foreach values %{$self->{vars}};
}


1;
__END__

=head1 NAME

Astro::STSDAS::Table::HeaderPars - Container for header values

=head1 SYNOPSIS

  use Astro::STSDAS::Table::HeaderPars;


=head1 DESCRIPTION

B<Astro::STSDAS::Table::HeaderPars> is a container for a set of
B<Astro::STSDAS::Table::HeaderPar> objects.

Column names are stored as upper case, but case is ignored
when searching by name.

=head2 Methods

=item new

  $pars = Astro::STSDAS::Table::HeaderPars->new;

The constructor.  It takes no arguments.

=item npars

  $npars = $pars->npars;

The number of header parameters.

=item add

  $hdrp = $hdrp->add( ... );

Add a parameter to the container.  The argument list is the same
as for the B<Astro::STSDAS::Table::HeaderPar> constructor, except
that the C<$idx> argument should not be specified.

It returns a reference to the new header parameter object.

=item pars

  @pars = $pars->pars;

This returns a list of header parameters, as
B<Astro::STSDAS::Table::HeaderPar> objects, in the order in which
they were added to the container.

=item byname

  $hdrp = $hdrp->byname( $name );

return the parameter with the specified name.

=item delbyname

  $pars->delbyname( $name )

Delete the parameter with the given name from the container.

=item rename

  $pars->rename( $oldname, $newname );

Rename the named header parameter.  It is important to use this method rather
than a header's B<name> method, to ensure the integrity of the
container.

=item copy

  $new_pars = $pars->copy;

This returns a new B<Astro::STSDAS::Table::HeaderPars> object which is
a copy of the current object.  The contained
B<Astro::STSDAS::Table::HeaderPar> objects are copies of the
originals.

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
