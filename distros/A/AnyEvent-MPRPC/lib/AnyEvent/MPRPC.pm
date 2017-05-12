package AnyEvent::MPRPC;

use strict;
use warnings;
our $VERSION = '0.20';
use AnyEvent::MPRPC::Server;
use AnyEvent::MPRPC::Client;
use base 'Exporter';
use 5.008;

our @EXPORT = qw/mprpc_client mprpc_server/;

sub mprpc_client($$) { ## no critic
    my ($host, $port) = @_;

    AnyEvent::MPRPC::Client->new(
        host => $host,
        port => $port,
    );
}

sub mprpc_server($$) { ## no critic
    my ($address, $port) = @_;

    AnyEvent::MPRPC::Server->new(
        address => $address,
        port    => $port,
    );
}

1;

__END__

=head1 NAME

AnyEvent::MPRPC - Simple TCP-based MPRPC client/server

=head1 SYNOPSIS

    use AnyEvent::MPRPC;

    my $server = mprpc_server '127.0.0.1', '4423';
    $server->reg_cb(
        echo => sub {
            my ($res_cv, @params) = @_;
            $res_cv->result(@params);
        },
    );

    my $client = mprpc_client '127.0.0.1', '4423';
    my $d = $client->call( echo => 'foo bar' );

    my $res = $d->recv; # => 'foo bar';

=head1 DESCRIPTION

This module provide TCP-based MessagePack RPC server/client implementation.

L<AnyEvent::MPRPC> provide you a couple of export functions that are shortcut of L<AnyEvent::MPRPC::Client> and L<AnyEvent::MPRPC::Server>.
One is C<mprpc_client> for Client, another is C<mprpc_server> for Server.

=head1 FUNCTIONS

=head2 mprpc_server $address, $port;

Create L<AnyEvent::MPRPC::Server> object and return it.

This is equivalent to:

    AnyEvent::MPRPC::Server->new(
        address => $address,
        port    => $port,
    );

See L<AnyEvent::MPRPC::Server> for more detail.

=head2 mprpc_client $hostname, $port

Create L<AnyEvent::MPRPC::Client> object and return it.

This is equivalent to:

    AnyEvent::MPRPC::Client->new(
        host => $hostname,
        port => $port,
    );

See L<AnyEvent::MPRPC::Client> for more detail.

=head1 SEE ALSO

L<AnyEvent::MPRPC::Client>, L<AnyEvent::MPRPC::Server>.
L<AnyEvent::JSONRPC::Lite>

L<http://msgpack.org/>

L<http://wiki.msgpack.org/display/MSGPACK/RPC+specification>

=head1 AUTHOR

Tokuhiro Matsuno <tokuhirom@cpan.org>

=head1 THANKS TO

typester++ wrote AnyEvent::JSONRPC::Lite. This module takes A LOT OF CODE from that module =P

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by tokuhirom.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

