package DateTime::Format::Docker;

=head1 NAME

DateTime::Format::Docker - Parse and format Docker dates and times

=head1 VERSION

Version 0.010001

=cut

our $VERSION = '0.010001';

use 5.006;
use strict;
use warnings;

use DateTime::Format::Builder (
    parsers => {
        parse_datetime => [
            {
                #2017-01-12T20:25:26.027337914Z
                regex  => qr/^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)\.(\d+)(\w)$/,
                params => [qw( year month day hour minute second nanosecond time_zone)],
            },
            {
                #2017-01-12T20:25:26Z
                regex  => qr/^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(\w)$/,
                params => [qw( year month day hour minute second time_zone)],
            },
        ],
    }
);

1;

__END__

=head1 SYNOPSIS

    require DateTime::Format::Docker;

    my $dt1 = DateTime::Format::Docker->parse_datetime( $state->finished_at );
    
    my $dt2 = DateTime::Format::Docker->parse_datetime( '2017-01-12T20:25:26.027337914Z' );
    
    my $dt3 = DateTime::Format::Docker->parse_datetime( '2017-01-12T20:25:26Z' );
    ...

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-datetime-format-docker at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTime-Format-Docker>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Format::Docker


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-Docker>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DateTime-Format-Docker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DateTime-Format-Docker>

=item * Search CPAN

L<http://search.cpan.org/dist/DateTime-Format-Docker/>

=back
 

=head1 SEE ALSO

=over 4

datetime@perl.org mailing list
 
http://datetime.perl.org/

=back

=head1 LICENSE AND COPYRIGHT

=over 4

Copyright 2017 Mario Zieschang.

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

=back

=cut