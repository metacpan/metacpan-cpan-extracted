use 5.014;
use warnings;

package MailX::Qmail::Queue::Message;

our $VERSION = '0.11';

use base 'Mail::Qmail::Queue::Message';

use Mail::Address;
use Mail::Header;

# Use inside-out attributes to avoid interference with base class:
my %header;

sub header {
    my $self = shift;
    return $header{$self} if exists $header{$self};
    open my $fh, '<', $self->body_ref or die 'Cannot read message';
    $header{$self} = Mail::Header->new($fh);
}

sub header_from {
    my $from = shift->header->get('From') or return;
    ($from) = Mail::Address->parse($from);
    $from;
}

sub helo {
    my $header = shift->header;
    my $received = $header->get('Received') or return;
    $received =~ /^from .*? \(HELO (.*?)\) /
      or $received =~ /^from (\S+) \(/
      or return;
    $1;
}

sub add_header {
    my $self = shift;
    ${$self->body_ref} = join "\n", @_, $self->body;
}

sub DESTROY {
    my $self = shift;
    delete $header{$self};
}

1;

__END__

=head1 NAME

MailX::Qmail::Queue::Message - extensions to Mail::Qmail::Queue::Message

=head1 DESCRIPTION

This class only contains some extensions to L<Mail::Qmail::Queue::Message>
needed by C<qmail-dmarc>.
You normally should not need to use it yourself.

=head1 METHODS

=over 4

=item ->header

get the header of the incoming message as L<Mail::Header> object

=item ->header_from

get the C<From:> header field of the incoming message as L<Mail::Address> object

=item ->helo

get the C<HELO>/C<EHLO> string used by the client

=item ->add_header

Add header fields to the message.
Expects C<Field: Value> as argument, without newlines at the end.

=back

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
