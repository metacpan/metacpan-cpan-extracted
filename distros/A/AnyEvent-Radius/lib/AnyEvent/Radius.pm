package AnyEvent::Radius;
# DUMMY
use strict;
use warnings;
our $VERSION = '1.1.6';
1;

__END__

=head1 NAME

AnyEvent::Radius - modules to implement AnyEvent-based RADIUS client or server

=head1 SYNOPSYS

    use AnyEvent;
    use AnyEvent::Radius::Client;

    my $dict = AnyEvent::Radius::Client->load_dictionary('path-to-radius-dictionary');

    sub read_reply_callback {
        # $h is HASH-REF {type, request_id, av_list, from, authenticator}
        my ($self, $h) = @_;
        ...
    }

    my $client = AnyEvent::Radius::Client->new(
                        ip => $ip,
                        port => $port,
                        on_read => \&read_reply_callback,
                        dictionary => $dict,
                        secret => $secret,
                    );
    $client->send_auth(AV_LIST1);
    $client->send_auth(AV_LIST2);
    ...
    $client->wait;

=head1 SEE ALSO

L<AnyEvent::Radius::Client>, L<AnyEvent::Radius::Server>

examples/ directory for basic client and server implementation

=head1 AUTHOR

Sergey Leschenko <sergle.ua at gmail.com>

PortaOne Development Team <perl-radius at portaone.com> is the current module's maintainer at CPAN.

=head1 COPYRIGHT & LICENSE

Copyright 2016 PortaOne Inc., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
