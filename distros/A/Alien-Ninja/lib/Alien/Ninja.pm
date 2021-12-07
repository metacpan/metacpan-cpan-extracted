package Alien::Ninja;

use strict;
use warnings;
use base qw( Alien::Base );
use 5.008004;

=head1 NAME

Alien::Ninja - Find or build Ninja build tool

=head1 SYNOPSIS

Command line tool:

 use Alien::Ninja;
 use Env qw( @PATH );

 unshift @PATH, Alien::Ninja->bin_dir;
 system "@{[ Alien::Ninja->exe ]}";

=head1 DESCRIPTION

This distribution provides Ninja so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of Ninja on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=cut

sub exe {
  my($class) = @_;
  $class->runtime_prop->{command};
}

=head1 HELPERS

=head2 ninja

 %{ninja}

Returns 'ninja'.

=cut

sub alien_helper {
  return +{
    ninja => sub {
      Alien::Ninja->exe;
    },
  };
}


=head1 SEE ALSO

=over 4

=item L<Ninja|https://ninja-build.org/>

The Ninja build system home page.

=item L<Alien>

Documentation on the Alien concept itself.

=item L<Alien::Base>

The base class for this Alien.

=item L<Alien::Build::Manual::AlienUser>

Detailed manual for users of Alien classes.

=back

=cut

1;
