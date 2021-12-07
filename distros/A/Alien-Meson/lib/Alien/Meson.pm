package Alien::Meson;

use strict;
use warnings;
use base qw( Alien::Base );
use 5.008004;

use Path::Tiny;

=head1 NAME

Alien::Meson - Find or build meson build tool

=head1 SYNOPSIS

Command line tool:

 use Alien::Meson;
 use Env qw( @PATH );

 unshift @PATH, Alien::Meson->bin_dir;
 system "@{[ Alien::Meson->exe ]}";

=head1 DESCRIPTION

This distribution provides meson so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of meson on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=cut

=head1 METHODS

=head2 exe

 Alien::Meson->exe

Returns the command name for running meson.

=cut

sub exe {
  my($class) = @_;
  if( $class->install_type('share')
    && $^O eq 'MSWin32'
    && $class->runtime_prop->{'python-source'}
    ) {
    return ( 'python3', Path::Tiny->new( $class->bin_dir, $class->runtime_prop->{command}) );
  }
  $class->runtime_prop->{command};
}

sub bin_dir {
  my ($class) = @_;
  if($class->install_type('share')) {
    my $dir = Path::Tiny->new($class->dist_dir);
    return -d $dir ? ("$dir") : ();
  } else {
    return $class->SUPER::bin_dir(@_);
  }
}

=head1 HELPERS

=head2 meson

 %{meson}

Returns 'meson', 'meson.py', or appropriate command for
platform.

=cut

sub alien_helper {
  return +{
    meson => sub {
      Alien::Meson->exe;
    },
  };
}

=head1 SEE ALSO

=over 4

=item L<Meson|https://mesonbuild.com/>

The Meson Build system home page.

=item L<Alien>

Documentation on the Alien concept itself.

=item L<Alien::Base>

The base class for this Alien.

=item L<Alien::Build::Manual::AlienUser>

Detailed manual for users of Alien classes.

=back

=cut

1;
