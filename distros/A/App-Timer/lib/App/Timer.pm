package App::Timer;

$App::Timer::VERSION   = '0.02';
$App::Timer::AUTHORITY = 'cpan:MANWAR';

use strict;
use warnings;

=head1 NAME

App::Timer - Timer for your application.

=head1 VERSION

Version 0.02

=head1 DESCRIPTION

Every time, I create a command line tool in B<Perl>, I would just add
the following lines at the end of the script.

    END {
        my $time = time - $^T;
        my $mm   = $time / 60;
        my $ss   = $time % 60;
        my $hh   = $mm / 60;

        printf("The program ran for %02d:%02d:%02d.\n", $hh, $mm%60, $ss);
    }

Having done it more than once, I decided to come up with something as
smooth as possible. This is my pure Perl solution.

I found somewhat similar work done in L<Timer::Runtime>. The only issue
is that it has dependency on a non-core module L<Time::Elapse>.

=head1 SYNOPSIS

To get the timer enable for your command line tool, just add the line
below at the top of the script and you are good to go.

    use App::Timer;

Or if you don't want to pollute your script then you can do this too.

    $ perl -MApp::Timer your-script.pl

=cut

sub import {
    END {
        my $time = time - $^T;
        my $mm   = $time / 60;
        my $ss   = $time % 60;
        my $hh   = $mm / 60;

        printf("The program ran for %02d:%02d:%02d.\n", $hh, $mm%60, $ss);
    }
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/App-Timer>

=head1 SEE ALSO

L<Timer::Runtime>

=head1 BUGS

Please  report any bugs or feature requests to C<bug-app-timer at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Timer>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Timer

You can also look for information at:

=over 4

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Timer>

=item * Search MetaCPAN

L<http://search.cpan.org/dist/App-Timer/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
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

1; # End of App::Timer
