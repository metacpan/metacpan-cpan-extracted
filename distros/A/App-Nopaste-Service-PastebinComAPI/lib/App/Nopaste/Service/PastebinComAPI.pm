package App::Nopaste::Service::PastebinComAPI;

use 5.006;
use strict;
use warnings FATAL => 'all';
use base 'App::Nopaste::Service';

our $VERSION = '1.002';

sub available {
    eval 'require WWW::Pastebin::PastebinCom::API; 1';
}
sub run {
    my $self = shift;
    my %args = @_;

    my ( $api_key, $user_key ) = @ENV{qw/
        APP_NOPASTE_PASTEBINCOM_API_KEY
        APP_NOPASTE_PASTEBINCOM_USER_KEY
    /};

    unless ( defined $api_key and length $api_key
        and defined $user_key and length $user_key
    ) {
        return (0,'You must specify the pastebin.com API keys'
            . ' using the APP_NOPASTE_PASTEBINCOM_API_KEY and'
            . ' APP_NOPASTE_PASTEBINCOM_USER_KEY environmental'
            . ' variables! To generate your user key, run this piece of'
            . ' code: '
            . q{perl -MWWW::Pastebin::PastebinCom::API -wle "print }
            . q{WWW::Pastebin::PastebinCom::API->new( api_key => }
            . q{ q|YOUR_API_KEY_HERE|)->get_user_key(qw/ }
            . q{YOUR_PASTEBIN_LOGIN_HERE  YOUR_PASTEBIN_PASSWORD_HERE/);"}
        );
    }

    require WWW::Pastebin::PastebinCom::API;

    my $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key  => $api_key,
        user_key => $user_key,
    );

    delete $args{nick} if defined $args{nick};
    $args{title}  = delete $args{desc} if defined $args{desc};
    $args{format} = delete $args{lang} if defined $args{lang};
    $args{unlisted} = 1 unless $args{private};

    my $ok = $bin->paste(
        delete($args{text}),
        expiry => 'm1',
        %args,
    );

    return (0, $bin->error) unless $ok;
    return (1, $bin->paste_url);
}



q|
Q: How many programmers does it take to change a light bulb?
A: None. It's a hardware problem.
|;

__END__

=encoding utf8

=head1 NAME

App::Nopaste::Service::PastebinComAPI - App::Nopaste service for www.pastebin.com using their API

=head1 CONFIGURATION

To use this L<App::Nopaste> service, you need to setup two
environmental variables: B<APP_NOPASTE_PASTEBINCOM_API_KEY> and
B<APP_NOPASTE_PASTEBINCOM_USER_KEY>

=head2 C<APP_NOPASTE_PASTEBINCOM_API_KEY>

The C<APP_NOPASTE_PASTEBINCOM_API_KEY> environmental variable needs
to contain your pastebin.com API key. To obtain the key, create
a free pastebin.com account, and then go on L<http://pastebin.com/api>
and the key will be shown in the 'Your Unique Developer API Key' section.

=head2 C<APP_NOPASTE_PASTEBINCOM_USER_KEY>

The C<APP_NOPASTE_PASTEBINCOM_USER_KEY> environmental variable needs to
contain your pastebin.com USER key. You can obtain a user key by
running this piece of code, changing C<YOUR_API_KEY_HERE> to your
pastebin.com API key, C<YOUR_PASTEBIN_LOGIN_HERE> to your pastebin.com
login, and C<YOUR_PASTEBIN_PASSWORD_HERE> to your pastebin.com password:

    perl -MWWW::Pastebin::PastebinCom::API -wle "print WWW::Pastebin::PastebinCom::API->new( api_key =>  q|YOUR_API_KEY_HERE|)->get_user_key(qw/YOUR_PASTEBIN_LOGIN_HERE  YOUR_PASTEBIN_PASSWORD_HERE/);"

Note: pastebin.com/api has this to say about the user key:
C<if an invalid api_user_key or no key is used, the paste will be
created as a guest>.

=head1 SEE ALSO

L<WWW::Pastebin::PastebinCom::API>, L<App::Nopaste>,
L<App::Nopaste::Service::PastebinCom>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-nopaste-service-pastebincomapi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Nopaste-Service-PastebinComAPI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Nopaste::Service::PastebinComAPI

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Nopaste-Service-PastebinComAPI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Nopaste-Service-PastebinComAPI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Nopaste-Service-PastebinComAPI>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Nopaste-Service-PastebinComAPI/>

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
