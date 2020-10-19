package Data::Radius;

use strict;
use warnings;

our $VERSION = '1.2.5';

=head1 NAME

Data::Radius - module to encode/decode RADIUS messages

=head1 SYNOPSYS

    use Data::Radius::Constants qw(:all);
    use Data::Radius::Packet;

    my $dictionary = Data::Radius::Dictionary->load_file('./radius/dictionary');
    my $packet = Data::Radius::Packet->new(secret => 'top-secret', dict => $dictionary);

    # build request packet:
    my ($request, $req_id, $authenticator) = $packet->build(
        type => ACCESS_REQUEST,
        av_list => [
            { Name => 'User-Name', Value => 'JonSnow'},
            { Name => 'User-Password', Value => 'Castle Black' },
            { Name => 'Message-Authenticator', Value => '' },
        ],
    );

    # ... send $request and read $reply binary packets from RADIUS server

    # parse reply packet:
    my ($reply_type, $reply_id, $reply_authenticator, $av_list) = $packet->parse($reply, $authenticator);

=head1 SEE ALSO

L<Data::Radius::Packet>

=head1 AUTHOR

Sergey Leschenko <sergle.ua at gmail.com>

PortaOne Development Team <perl-radius at portaone.com> is the current module's maintainer at CPAN.

=head1 COPYRIGHT & LICENSE

Copyright 2016 PortaOne Inc., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
