package App::Nopaste::Service::PastebinCa;

use 5.006;
use strict;
use warnings FATAL => 'all';
use base 'App::Nopaste::Service';

our $VERSION = '1.004';

sub available {
    eval 'require WWW::Pastebin::PastebinCa::Create; 1';
}
sub run {
    my $self = shift;
    my %args = @_;

    require WWW::Pastebin::PastebinCa::Create;

    $args{name} = delete $args{nick} if defined $args{nick};

    my $paster = WWW::Pastebin::PastebinCa::Create->new;
    my $ok = $paster->paste(
        delete($args{text}),
        expire  => '1 month',
        %args,
    );

    return (0, $paster->error) unless $ok;
    return (1, $paster->paste_uri);
}

q|
A guy is standing on the corner of the street smoking one cigarette after another. A lady walking by notices him and says
"Hey, don't you know that those things can kill you? I mean, didn't you see the giant warning on the box?!"
"That's OK" says the guy, puffing casually "I'm a computer programmer"
"So? What's that got to do with anything?"
"We don't really care about warnings. We only care about errors."
|;

__END__

=encoding utf8

=head1 NAME

App::Nopaste::Service::PastebinCa - App::Nopaste service for www.pastebin.ca

=head1 SEE ALSO

L<WWW::Pastebin::PastebinCa::Create>, L<App::Nopaste>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-nopaste-service-pastebinca at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Nopaste-Service-PastebinCa>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Nopaste::Service::PastebinCa

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Nopaste-Service-PastebinCa>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Nopaste-Service-PastebinCa>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Nopaste-Service-PastebinCa>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Nopaste-Service-PastebinCa/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Zoffix Znet.

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
