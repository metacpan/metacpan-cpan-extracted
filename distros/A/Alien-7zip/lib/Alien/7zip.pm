package Alien::7zip;

use strict;
use warnings;
use base qw( Alien::Base );
use 5.008004;

=head1 NAME

Alien::7zip - Find or build 7-Zip

=head1 SYNOPSIS

Command line tool:

 use Alien::7zip;
 use Env qw( @PATH );

 unshift @PATH, Alien::7zip->bin_dir;
 system "@{[ Alien::7zip->exe ]}";

=head1 DESCRIPTION

This distribution provides 7-Zip so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of 7-Zip on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 METHODS

=head2 exe

 Alien::7zip->exe

Returns the command name for running 7-Zip.

=cut

sub exe {
  my($class) = @_;
  $class->runtime_prop->{command};
}

=head1 HELPERS

=head2 7z

 %{7z}

Returns '7z', '7zz', or appropriate command for
platform.

=cut

sub alien_helper {
  return +{
    '7z' => sub {
      Alien::7zip->exe;
    },
  };
}

1;

=head1 SEE ALSO

=over 4

=item L<7-Zip|https://www.7-zip.org/>

The 7-Zip home page.

=item L<Alien>

Documentation on the Alien concept itself.

=item L<Alien::Base>

The base class for this Alien.

=item L<Alien::Build::Manual::AlienUser>

Detailed manual for users of Alien classes.

=back

=cut
