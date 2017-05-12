package AnyEvent::JSONRPC::Server;

use Moose;
use JSON::XS;

has json => (
    is      => "ro",
    default => sub {
        JSON::XS->new->allow_blessed(1)->convert_blessed(1);
    },
);

no Moose;

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

AnyEvent::JSONRPC::Server - Base class for JSON-RPC Servers

=head1 SYNOPSIS

    use AnyEvent::JSONRPC::XXX::Server;
    
    my $server = AnyEvent::JSONRPC::TCP::Server->new( ... );
    $server->reg_cb(
        echo => sub {
            my ($res_cv, @params) = @_;
            $res_cv->result(@params);
        },
        sum => sub {
            my ($res_cv, @params) = @_;
            $res_cv->result( $params[0] + $params[1] );
        },
    );

=head1 DESCRIPTION

This is the base class for servers in the L<AnyEvent::JSONRPC> suite of
modules. Current implementations includes a
L<TCP|AnyEvent::JSONRPC::TCP::Server> client and a
L<HTTP|AnyEvent::JSONRPC::HTTP::Server> client. See these for arguments to the
constructors.

=head1 METHOD

=head1 new (%options)

Create server object, start listening socket, and return object.

    my $server = AnyEvent::JSONRPC::TCP::Server->new(
        port => 4423,
    );

Available C<%options> are specific to each implementation

=head2 reg_cb (%callbacks)

Register JSONRPC methods.

    $server->reg_cb(
        echo => sub {
            my ($res_cv, @params) = @_;
            $res_cv->result(@params);
        },
        sum => sub {
            my ($res_cv, @params) = @_;
            $res_cv->result( $params[0] + $params[1] );
        },
    );

=head3 callback arguments

JSONRPC callback arguments consists of C<$result_cv>, and request C<@params>.

    my ($result_cv, @params) = @_;

C<$result_cv> is L<AnyEvent::JSONRPC::CondVar> object.
Callback must be call C<< $result_cv->result >> to return result or C<< $result_cv->error >> to return error.

If C<$result_cv-E<gt>is_notification()> returns true, this is a notify request
and the result will not be send to the client.

C<@params> is same as request parameter.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
