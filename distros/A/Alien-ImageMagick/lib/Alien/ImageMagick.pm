package Alien::ImageMagick;

use 5.006;
use strict;
use warnings;

use parent 'Alien::Base';

=head1 NAME

Alien::ImageMagick - cpanm compatible Image::Magick packaging.

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 DESCRIPTION

This package's purpose is to make the installation
of the official Image Magick library and Perl interface
compatible with cpanm ( L<https://metacpan.org/pod/distribution/App-cpanminus/bin/cpanm> )
and perlbrew ( L<https://metacpan.org/pod/distribution/App-perlbrew/bin/perlbrew> ).

Installing it will download and install the B<freshest image magick library and Perl interface>
from the official Image magick website ( See L<http://www.imagemagick.org/script/install-source.php> )
in a way that is compatible with perlbrew and/or cpanm.

If you use cpanm or perlbrew, this will not conflict with your system's Image Magick installation.

=head1 INSTALLATION

To use this package and use Image::Magick from your application code:

Instead of depending on 'Image::Magick', just B<depend on 'Alien::ImageMagick'>.

Then see L<http://www.imagemagick.org/script/perl-magick.php#overview> for more on using image magic with perl.

=over

=item With System Perl

If you need to use Image::Magick and use system perl and system PerlMagick, you only
need this package if you want the freshest version of Image Magick.

Install Alien::ImageMagick with your favorite package manager.

=item With cpanm

If you need to use Image::Magick and use cpanm, you only need this package
if you want the freshest version of Image Magick. Otherwise you can install
your system's one.

   cpanm Alien::ImageMagick

=item With perlbrew + cpanm

If you need to use Image::Magick and use perlbrew w/ cpanm, you will need this
package.

   cpanm Alien::ImageMagick

=back

=head1 SYNOPSIS

  use Image::Magick
  ...

=head1 AUTHOR

Jerome Eteve, C<< <jerome.eteve at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

This is inspired by David Farrell's post on perltricks.com L<http://perltricks.com/article/57/2014/1/1/Shazam-Use-Image-Magick-with-Perlbrew-in-minutes>

=head1 BUGS

Please report any bugs or feature requests to C<bug-alien-imagemagick at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Alien-ImageMagick>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Alien::ImageMagick


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-ImageMagick>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Alien-ImageMagick>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Alien-ImageMagick>

=item * Search CPAN

L<http://search.cpan.org/dist/Alien-ImageMagick/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jerome Eteve.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Alien::ImageMagick
