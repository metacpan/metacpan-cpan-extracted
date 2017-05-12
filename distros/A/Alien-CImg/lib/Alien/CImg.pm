package Alien::CImg;
use strict;
use warnings;
our $VERSION = '0.01';
use parent 'Alien::Base';

1;

__END__

=head1 NAME

Alien::CImg - CImg distribution for CPAN.

=head1 Description

This is a Alien distribution based on L<Alien::Base>, class methods
such as C<cflags> and C<libs> are inherited from there. See the
documentation for L<Alien::Base> for full list of methods. This module
does not override or extend any of those inherited methods.

Quote from the L<cimg website|http://cimg.eu/>

=over 4

CImg stands for Cool Image : It is easy to use, efficient and is
intended to be a very pleasant toolbox to design image processing
algorithms in C++. Due to its generic conception, it can cover a wide
range of image processing applications.

=back

The CImg distribution is only a .h file CImg.h, the way you use it is
to just include it in your C/C++ source code.

=over 4

#inculed <CImg.h>

=back

If you are authoring a CPAN distribution that requires CImg, you could
get the cflags by running this L<palien|App::palien> command:

   palien --cflags Alien::CImg

Or alternativly, this one-liner:

   perl -MAlien::CImg -E 'say Alien::CImg->cflags'

Since CImg installation only contains source code, it does not require
linking. So there is no need for a C<-lcimg> command flag.

See also L<palien|App::palien> and L<Alien::Base>

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=cut
