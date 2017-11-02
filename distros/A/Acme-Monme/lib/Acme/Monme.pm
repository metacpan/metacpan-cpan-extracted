package Acme::Monme;

use strict;
use warnings;

=head1 NAME

Acme::Monme - Convert monme/gram to gram/monme.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Acme::Monme;

    use Acme::Monme;

    my $num="1";
    my $tmp1 = $num->Acme::Monme::monme_g; #monme to gram
    my $tmp2 = $num->Acme::Monme::g_monme; #gram to monme
    my $tmp3 = $num->Acme::Monme::kan_g; #kan to gram
    my $tmp4 = $num->Acme::Monme::g_kan; #gram to kan
    my $tmp5 = $num->Acme::Monme::sun_cm; #sun to cm
    my $tmp6 = $num->Acme::Monme::cm_sun; #cm to sun
    my $tmp7 = $num->Acme::Monme::shaku_cm; #shaku to cm
    my $tmp8 = $num->Acme::Monme::cm_shaku; #cm to shaku
    
    print $tmp1 , "\n"; #3.75
    print $tmp2 , "\n"; #0.266666666666667
    print $tmp3 , "\n"; #3750
    print $tmp4 , "\n"; #0.000266666666666667
    print $tmp5 , "\n"; #3.03
    print $tmp6 , "\n"; #0.33003300330033
    print $tmp7 , "\n"; #30.3
    print $tmp8 , "\n"; #0.033003300330033

=head1 DESCRIPTION

Long, long ago , monme is widely used as a unit of weight in Asia.
https://en.wikipedia.org/wiki/Japanese_units_of_measurement

This module can convert monme to gram.
By the way, monme is sometime used in trading of pearls even now. So this module may useful for the perl mongers who love pearl.

In addition, this module can convert kan to gram. Similarly, it can convert sun and shaku to centimeters.
Those functions are useful when Japanes who born in 300 years ago travel to the 21st century.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub monme_g {
    my $monme = shift;
    my $gram = $monme * 3.75;
    return $gram;
}

sub g_monme {
    my $gram = shift;
    my $monme = $gram / 3.75;
    return $monme;
}

sub kan_g {
    my $kan = shift;
    my $gram = $kan * 3750;
    return $gram;
}

sub g_kan {
    my $gram = shift;
    my $kan = $gram / 3750;
    return $kan;
}

sub sun_cm {
    my $sun = shift;
    my $cm = $sun * 3.03;
    return $cm;
}

sub cm_sun {
    my $cm = shift;
    my $sun = $cm / 3.03;
    return $sun;
}

sub shaku_cm {
    my $shaku = shift;
    my $cm = $shaku * 30.3;
    return $cm;
}

sub cm_shaku {
    my $cm = shift;
    my $shaku = $cm / 30.3;
    return $shaku;
}


=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Usuki Shunsuke, C<< <whisky-shusuky@gmail.co.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-monme at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Monme>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Monme


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Monme>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Monme>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Monme>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Monme/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Usuki Shunsuke.

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

1; # End of Acme::Monme
