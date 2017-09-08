package Crypt::Image::Util;

$Crypt::Image::Util::VERSION   = '0.12';
$Crypt::Image::Util::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Crypt::Image::Util - Helper for Crypt::Image module.

=head1 VERSION

Version 0.12

=cut

use 5.006;
use strict; use warnings;
use Data::Dumper;

use autodie;
use Math::Random;
use Crypt::Image::Axis;

=head1 DESCRIPTION

Utility module for Crypt::Image. Methods can be accessed directly.

=head1 METHODS

=head2 cloneImage()

It clone the given image (object of type GD::Image) and returns the clone of type
GD::Image.

=cut

sub cloneImage {
    my ($image) = @_;

    return $image->clone;
}

=head2 saveImage()

Saves the given image data as given file  name  of the given type. The parameters
are listed below in sequence:

=over 3

=item * Filename with the complete path.

=item * Object of type GD::Image for the image.

=item * Type of the given image.

=back

=cut

sub saveImage {
    my ($file, $image, $type) = @_;

    open(IMAGE, ">$file");
    binmode IMAGE;
    print IMAGE $image->png  if $type =~ /png/i;
    print IMAGE $image->gif  if $type =~ /gif/i;
    print IMAGE $image->jpeg if $type =~ /jpg/i;
    close(IMAGE);
}

=head2 moveDown()

Moves the given pixel down by given number.

=cut

sub moveDown {
    my ($this, $by) = @_;

    ($this < 128)?($this += $by):($this -= $by);
    return $this;
}

=head2 moveUp()

Moves the given pixel up by given number.

=cut

sub moveUp {
    my ($this, $by) = @_;

    ($this >= 128)?($this -= $by):($this += $by);
    return $this;
}

=head2 getColor()

Returns the color index for the given R, G and B.

=cut

sub getColor {
    my ($r, $g, $b) = @_;

    my $image = GD::Image->new();
    return $image->colorAllocate($r, $g, $b);
}

=head2 splitInTwo()

It  splits  the  given  point into X, Y coordinates and returns an object of type
Crypt::Image::Axis.

=cut

sub splitInTwo {
    my ($a) = @_;

    my $r = int(random_uniform() * $a);
    $a -= $r;
    return Crypt::Image::Axis->new('x' => $a, 'y' => $r);
}

=head2 splitInThree()

It splits the given point into X, Y, Z coordinates  and returns an object of type
L<Crypt::Image::Axis>.

=cut

sub splitInThree {
    my ($a) = @_;

    my $z = 0;
    my $r = int(random_uniform() * $a);
    $a -= $r;
    if ($a > $r) {
        $z = int(random_uniform() * $a);
        $a -= $z;
    }
    else {
        $z = int(random_uniform() * $r);
        $r -= $z;
    }

    return Crypt::Image::Axis->new('x' => $a, 'y' => $r, 'z' => $z);
}

=head2 differenceInAxis()

It returns the absolute difference in the R, G and B of the given  key and cloned
images at X and Y coordinates. The parameters are listed below in sequence:

=over 4

=item * Object of type GD::Image for key image.

=item * Object of type GD::Image for new image.

=item * X coordinate.

=item * Y coordinate.

=back

=cut

sub differenceInAxis {
    my ($k, $c, $x, $y) = @_;

    my ($k_r, $k_g, $k_b) = Crypt::Image::Util::getPixelColorRGB($k, $x, $y);
    my ($c_r, $c_g, $c_b) = Crypt::Image::Util::getPixelColorRGB($c, $x, $y);

    return (abs($k_r-$c_r), abs($k_g-$c_g), abs($k_b-$c_b));
}

=head2 getPixelColorRGB()

Returns the R,G,B of the given image at the given X,Y coordinates. The parameters
are listed below in sequence:

=over 3

=item * Object of type GD::Image for the image.

=item * X coordinate.

=item * Y coordinate.

=back

=cut

sub getPixelColorRGB {
    my ($image, $x, $y) = @_;

    my $index = $image->getPixel($x, $y);
    my ($r, $g, $b) = $image->rgb($index);
    return ($r, $g, $b);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Crypt-Image>

=head1 BUGS

Please report any bugs / feature requests to C<bug-crypt-image at rt.cpan.org> or
through the the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-Image>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::Image::Util

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-Image>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-Image>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-Image>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-Image/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2017 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Crypt::Image::Util
