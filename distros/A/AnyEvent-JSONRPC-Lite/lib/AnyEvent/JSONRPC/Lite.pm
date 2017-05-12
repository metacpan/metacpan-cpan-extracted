package AnyEvent::JSONRPC::Lite;
use strict;
use warnings;
use base 'Exporter';

our $VERSION = '0.15';

our @EXPORT = qw/jsonrpc_client jsonrpc_server/;

use AnyEvent::JSONRPC::Lite::Client;
use AnyEvent::JSONRPC::Lite::Server;

sub jsonrpc_client($$) {
    my ($host, $port) = @_;

    AnyEvent::JSONRPC::Lite::Client->new(
        host => $host,
        port => $port,
    );
}

sub jsonrpc_server($$) {
    my ($address, $port) = @_;

    AnyEvent::JSONRPC::Lite::Server->new(
        address => $address,
        port    => $port,
    );
}

1;

__END__

=encoding utf-8

=for stopwords TCP TCP-based JSONRPC RPC

=head1 NAME

AnyEvent::JSONRPC::Lite - Simple TCP-based JSONRPC client/server

=head1 SYNOPSIS

    use AnyEvent::JSONRPC::Lite;
    
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

L<AnyEvent::JSONRPC::Lite> provide you a couple of export functions that are shortcut of L<AnyEvent::JSONRPC::Lite::Client> and L<AnyEvent::JSONRPC::Lite::Server>.
One is C<jsonrpc_client> for Client, another is C<jsonrpc_server> for Server.

=head2 WHY I NAMED "Lite" TO THIS MODULE

This module implement only JSONRPC 1.0's TCP part, not HTTP protocol, and not full of JSONRPC 2.0 spec.
But I think this is enough as simple RPC client/server, so I don't want to implement 2.0 things at this point.

That's why this module name is AnyEvent::JSONRPC::Lite, not AnyEvent::JSONRPC (this should be full-spec)

=head1 FUNCTIONS

=head2 jsonrpc_server $address, $port;

Create L<AnyEvent::JSONRPC::Lite::Server> object and return it.

This is equivalent to:

    AnyEvent::JSONRPC::Lite::Server->new(
        address => $address,
        port    => $port,
    );

See L<AnyEvent::JSONRPC::Lite::Server> for more detail.

=head2 jsonrpc_client $hostname, $port

Create L<AnyEvent::JSONRPC::Lite::Client> object and return it.

This is equivalent to:

    AnyEvent::JSONRPC::Lite::Client->new(
        host => $hostname,
        port => $port,
    );

See L<AnyEvent::JSONRPC::Lite::Client> for more detail.

=head1 SEE ALSO

L<AnyEvent::JSONRPC::Lite::Client>, L<AnyEvent::JSONRPC::Lite::Server>.

L<http://json-rpc.org/>

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

