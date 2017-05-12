package Alien::libsndfile;
use strict;
use warnings;

our $VERSION = 0.01;
$VERSION = eval $VERSION;

use parent 'Alien::Base';

1;

__END__

=head1 NAME

Alien::libsndfile - libsndfile distribution for CPAN.

=head1 Description

This is a Alien distribution based on L<Alien::Base>, class methods
such as C<cflags> and C<libs> are inherited from there. See the
documentation for L<Alien::Base> for full list of methods. This module
does not override or extend any of those inherited methods.

See also L<http://www.mega-nerd.com/libsndfile/> and L<Audio::Sndfile>

If you are authoring a CPAN distribution that requires libsndfile, you could
get the cflags by running this L<palien|App::palien> command:

   palien --cflags Alien::libsndfile

Or alternativly, this one-liner:

   perl -MAlien::libsndfile -E 'say Alien::libsndfile->cflags'

Run this command to obtain the library flags

   palien --cflags Alien::libsndfile

Or alternativly, this one-liner:

   perl -MAlien::libsndfile -E 'say Alien::libsndfile->libs'

See also L<palien|App::palien> and L<Alien::Base>

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=cut
