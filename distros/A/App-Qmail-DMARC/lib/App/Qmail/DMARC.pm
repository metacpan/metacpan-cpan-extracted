package App::Qmail::DMARC;

our $VERSION = '0.43';

__END__

=head1 NAME

qmail-dmarc - verify using DMARC and queue a mail message for delivery

=head1 DESCRIPTION

qmail-dmarc is designed to be called by qmail-smtpd instead of qmail-queue
and will verify if incoming e-mail conforms to the DMARC policy of its
sender domain:

=over 4

=item 1.

If the environment variable C<RELAYCLIENT> exists, no verification is done,
and the e-mail is immediately passed to C<qmail-queue>.

=item 2.

In any other case, we check if the message contains a valid DKIM signature
matching the domain of the C<From:> header field.
If this is the case, the e-mail is passed to C<qmail-queue>.

=item 3.

If not, but the message has a C<From:> domain contained in
C</var/qmail/control/rcpthosts> and the environment variable C<DMARC_REJECT>
is set to a true value, the message is rejected with message
C<554 Valid DKIM signature required for sender domain ...>

=item 4.

If not, a SPF check is done, and a C<Received-SPF:> header field is added to
the message.
Then we check if the message is aligned with its sender's DMARC policy.
A C<DMARC-Status:> header field is added.

If the message does not align to the policy, the policy advises to reject such
messages and when the environment variable C<DMARC_REJECT> is set to a true
value, the message will be rejected with C<554 Failed DMARC test.>

=item 5.

In any other case the message is passed on to C<qmail-queue>.

=back

Diagnostic messages are written as a single line to standard error,
so you should find them in your C<qmail-smtpd>'s log.

=head1 OPTIONS

Apart from controlling the rejection of messages via the environment variable
C<DMARC_REJECT>, none.
It just works the way I need it.
If you need it to operate in any other way, please let me know.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-qmail-dmarc at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Qmail-DMARC>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Qmail::DMARC

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Qmail-DMARC>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Qmail-DMARC>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/App-Qmail-DMARC>

=item * Search CPAN

L<https://metacpan.org/release/App-Qmail-DMARC>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Martin H. Sluka.

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
