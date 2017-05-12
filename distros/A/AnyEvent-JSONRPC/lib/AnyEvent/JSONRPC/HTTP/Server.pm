package AnyEvent::JSONRPC::HTTP::Server;
use Moose;

extends 'AnyEvent::JSONRPC::Server';

use Carp;
use Scalar::Util 'weaken';

use AnyEvent::JSONRPC::CondVar;

use AnyEvent::HTTPD;

use JSON::XS;
use JSON::RPC::Common::Procedure::Call;

has host => (
    is      => 'ro',
    isa     => 'Str',
    default => '127.0.0.1',
);

has port => (
    is      => 'ro',
    isa     => 'Int|Str',
    default => 8080,
);

has httpd => (
    is      => 'rw',
    isa     => 'AnyEvent::HTTPD',
    predicate => 'has_httpd',
);

has methods => (
    isa     => 'HashRef[CodeRef]',
    lazy    => 1,
    traits  => ['Hash'],
    handles => {
        reg_cb => 'set',
        method => 'get',
    },
    default => sub { {} },
);

no Moose;

sub BUILD {
    my $self = shift;

    unless ( $self->has_httpd ) {
        $self->httpd( AnyEvent::HTTPD->new( host => $self->host, port => $self->port ) );
    }

    $self->httpd->reg_cb(
        request => sub {
            my ($httpd, $req) = @_;

            my $request = eval { $self->json->decode( $req->content ) };

            unless (defined $request ) {
                $req->respond( [ 400, 'Bad Request' ] );
                warn "Bad content: [[[" . $req->content . "]]]" ;
                $httpd->stop_request;
            }

            my $response = $self->_dispatch( $request );

            if ($response) {
                $req->respond( [ 200, 'Ok', { "Content-Type" => "application/json" }, $self->json->encode( $response ) ] ); 
            } else {
                $req->respond( [ 204, 'No Content' ] );
            }

            $httpd->stop_request;
        },
    );

    $self;
}

sub _dispatch {
    my ($self, $request) = @_;

    return $self->_batch(@$request) if ref $request eq "ARRAY";
    return unless $request and ref $request eq "HASH";

    my $call   = JSON::RPC::Common::Procedure::Call->inflate($request);
    my $target = $self->method( $call->method );

    my $cv = AnyEvent::JSONRPC::CondVar->new( call => $call );

    $target ||= sub { shift->error(qq/No such method "$request->{method}" found/) };
    $target->( $cv, $call->params_list );

    return $cv->recv->deflate;
}

sub _batch {
    my ($self, @request) = @_;

    return [ map { $self->_dispatch($_) } @request ] ;
}

__PACKAGE__->meta->make_immutable;

__END__

=for stopwords JSONRPC TCP TCP-based unix Str

=head1 NAME

AnyEvent::JSONRPC::HTTP::Server - Simple HTTP-based JSONRPC server

=head1 SYNOPSIS

    use AnyEvent::JSONRPC::HTTP::Server;
    
    my $server = AnyEvent::JSONRPC::HTTP::Server->new( port => 8080 );
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

This module is server part of L<AnyEvent::JSONRPC>.

=head1 METHOD

=head1 new (%options)

Create server object, start listening socket, and return object.

    my $server = AnyEvent::JSONRPC::HTTP::Server->new(
        port => 4423,
    );

Available C<%options> are:

=over 4

=item host => 'Str'

Bind address. Default to 'localhost'.

If you want to use unix socket, this option should be set to "unix/"

=item port => 'Int | Str'

Listening port. Default to '8080'.

=back

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

=head1 SEE ALSO

=over 4

=item L<JSON::RPC::Dispatch>

A server based on PSGI/L<Plack>. Quite more flexible than this module.

=back

=head1 AUTHOR

Peter Makholm <peter@makholm.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 by Peter Makholm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
