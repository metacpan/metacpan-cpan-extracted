package Alien::pandoc;
$Alien::pandoc::VERSION = '0.01';
use strict;
use warnings;
use base qw( Alien::Base );
use 5.008004;

1;

=head1 NAME

Alien::pandoc - Find or build pandoc universal document converter

=head1 SYNOPSIS

Command line tool:

 use Alien::pandoc;
 use Env qw( @PATH );

 unshift @PATH, Alien::pandoc->bin_dir;

=head1 DESCRIPTION

This distribution provides pandoc so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of pandoc on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 SEE ALSO

=over 4

=item L<https://pandoc.org/>

Pandoc homepage

=item L<Alien>

Documentation on the Alien concept itself.

=item L<Alien::Base>

The base class for this Alien.

=item L<Alien::Build::Manual::AlienUser>

Detailed manual for users of Alien classes.

=back

=cut
