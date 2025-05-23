package Alien::innoextract;
$Alien::innoextract::VERSION = '0.01';
use strict;
use warnings;
use base qw( Alien::Base );
use 5.008004;

sub exe {
  return 'innoextract'
}

sub alien_helper {
  my ($class) = @_;
  return +{
    innoextract => sub {
      $class->exe;
    },
  };
}


1;

=head1 NAME

Alien::innoextract - Find or build innoextract

=head1 SYNOPSIS

Command line tool:

 use Alien::innoextract;
 use Env qw( @PATH );

 unshift @PATH, Alien::innoextract->bin_dir;
 system "@{[ Alien::innoextract->exe ]}";

=head1 DESCRIPTION

This distribution provides innoextract so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of innoextract on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 HELPERS

=head2 innoextract

 %{innoextract}

Returns 'innoextract'.

=cut

=head1 SEE ALSO

=over 4

=item L<Alien>

Documentation on the Alien concept itself.

=item L<Alien::Base>

The base class for this Alien.

=item L<Alien::Build::Manual::AlienUser>

Detailed manual for users of Alien classes.

=back

=cut
