package Acme::Pano::Util;

use 5.006;
use strict;
use encoding 'utf8';
use utf8;
use warnings FATAL => 'all';
use Exporter qw/import/;
our @EXPORT = qw/toBareword fromBareword/;
our @EXPORT_OK = ();
our %EXPORT_TAGS = (
  all       => [ @EXPORT, @EXPORT_OK ],
);

=head1 NAME

Acme::Pano::Util - Static Utility Methods 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.011';


=head1 SYNOPSIS

This module provides various random utilities that Pano Papadatos made.

=head1 EXPORT

toBareword - Converts any string to a string with only letters, underscores and numbers that does not start with a number (bareword)

fromBareword - Converts a string that was returned using toBareword back to its original form

=head1 SUBROUTINES/METHODS

=head2 toBareword

Usage: converts any string to a string with only letters, underscores and numbers that does not start with a number (bareword)

Arguments: (0) the string to convert

Returns: the converted string

Conversion Method

- A single underscore is converted into 2 _s

- A single zero is converted into 2 0s

- A number is converted into _number (To catch things that start with numbers)

- Any non [a-zA-Z] character is converted into _0_ plus its numeric value (ord) (e.g. _123)

=cut

sub toBareword {
    my ($string) = @_;
    return if(!defined($string));
    $string =~ s/_/__/g;
    $string =~ s/0/00/g;
    $string =~ s/([0-9]+)/_$1/g;
    $string =~ s/([^a-zA-Z0-9_]+)/join('',map {'_0_'.ord($_)} split('',$1))/eg;
    return $string;
}

=head2 fromBareword

Usage: converts any string that was returned using "toBareword" back to its original form

Arguments: (0) the string to convert

Returns: the converted string

=cut

sub fromBareword{
    my ($string) = @_;
    return if(!defined($string));
    $string =~ s/_0_([0-9]+)/chr($1)/eg;
    $string =~ s/_([0-9]+)/$1/g;
    $string =~ s/00/0/g;
    $string =~ s/__/_/g;
    return $string;
}

=head1 AUTHOR

Pano Papadatos, C<< <pano at heypano.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-pano-util at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Pano-Util>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Pano::Util


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Pano-Util>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Pano-Util>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Pano-Util>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Pano-Util/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Pano Papadatos.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Acme::Pano::Util
