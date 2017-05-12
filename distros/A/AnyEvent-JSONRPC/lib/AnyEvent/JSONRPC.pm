package AnyEvent::JSONRPC;
use strict;
use warnings;
use base 'Exporter';

our $VERSION = '0.15';

our @EXPORT = qw/jsonrpc_client jsonrpc_server/;

use AnyEvent::JSONRPC::TCP::Client;
use AnyEvent::JSONRPC::TCP::Server;

sub jsonrpc_client($$) {
    my ($host, $port) = @_;

    AnyEvent::JSONRPC::TCP::Client->new(
        host => $host,
        port => $port,
    );
}

sub jsonrpc_server($$) {
    my ($address, $port) = @_;

    AnyEvent::JSONRPC::TCP::Server->new(
        address => $address,
        port    => $port,
    );
}

1;

__END__

=encoding utf-8

=for stopwords TCP TCP-based JSONRPC RPC

=head1 NAME

AnyEvent::JSONRPC - Simple TCP-based JSONRPC client/server

=head1 SYNOPSIS

    use AnyEvent::JSONRPC;
    
    my $server = jsonrpc_server '127.0.0.1', '4423';
    $server->reg_cb(
        echo => sub {
            my ($res_cv, @params) = @_;
            $res_cv->result(@params);
        },
    );
    
    my $client = jsonrpc_client '127.0.0.1', '4423';
    my $d = $client->call( echo => 'foo bar' );
    
    my $res = $d->recv; # => 'foo bar';

=head1 DESCRIPTION

This module provide TCP-based JSONRPC server/client implementation.

L<AnyEvent::JSONRPC> provide you a couple of export functions that are
shortcut of L<AnyEvent::JSONRPC::TCP::Client> and L<AnyEvent::JSONRPC::TCP::Server>.
One is C<jsonrpc_client> for Client, another is C<jsonrpc_server> for Server.

=head2 DIFFERENCES FROM THE "Lite" MODULE

This module is a fork of Daisuke Murase's L<AnyEvent::JSONRPC::Lite> updated
to use Yuval Kogman's JSON::RPC::Common for handling the JSONRPC messages.
This enables support for handling messages complying to all versions of the
JSONRPC standard.

The System Services/Service Description parts of version 1.1-wd and 1.1-alt is
unimplemented and left to users to implement.

As none of the specs really defines JSON-RPC over TCP I consider this module
an otherwise full-spec implementation.

=head1 FUNCTIONS

=head2 jsonrpc_server $address, $port;

Create L<AnyEvent::JSONRPC::TCP::Server> object and return it.

This is equivalent to:

    AnyEvent::JSONRPC::TCP::Server->new(
        address => $address,
        port    => $port,
    );

See L<AnyEvent::JSONRPC::TCP::Server> for more detail.

=head2 jsonrpc_client $hostname, $port

Create L<AnyEvent::JSONRPC::TCP::Client> object and return it.

This is equivalent to:

    AnyEvent::JSONRPC::TCP::Client->new(
        host => $hostname,
        port => $port,
    );

See L<AnyEvent::JSONRPC::TCP::Client> for more detail.

=head1 SEE ALSO

L<AnyEvent>, L<AnyEvent::JSONRPC::Lite>, L<JSON::RPC::Common>.

L<http://json-rpc.org/>

=head1 AUTHOR

Peter Makholm <peter@makholm.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 by Peter Makholm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

