package AnyEvent::JSONRPC::HTTP::Client;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';

extends 'AnyEvent::JSONRPC::Client';

use Carp;
use Scalar::Util 'weaken';

use AnyEvent;
use AnyEvent::HTTP;

use JSON::RPC::Common::Procedure::Call;
use JSON::RPC::Common::Procedure::Return;

use MIME::Base64;
use JSON::XS;

has url => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has version => (
    is      => 'rw',
    isa     => enum( [qw( 1.0 1.1 2.0 )] ),
    default => "2.0",
);

has username => (
    is => "rw",
    isa => 'Str',
    predicate => "has_username"
);

has password => (
    is => "rw",
    isa => "Str"
);

has _request_pool => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has _next_id => (
    is      => 'ro',
    isa     => 'CodeRef',
    lazy    => 1,
    default => sub {
        my $id = 0;
        sub { ++$id };
    },
);

no Any::Moose;

sub call {
    my ($self, $method, @params) = @_;

    my $request = JSON::RPC::Common::Procedure::Call->inflate ( 
        version => $self->version,
        id      => $self->_next_id->(),
        method  => $method,
        params  => $self->_params( @params ),
    );

    my $guard = http_post $self->url, 
                          encode_json( $request->deflate ) . "   ",
                          headers => { 
                              "Content-Type" => "application/json",
                              $self->_authorization_header,
                          },
                          sub { $self->_handle_response( @_ ) };
    
    my $cv = AnyEvent->condvar;

    $self->_request_pool->{ $request->id } = [ $guard, $cv ];

    return $cv;
}

sub _authorization_header {
    my $self = shift;

    return unless $self->has_username;

    return Authorization => "Basic " . encode_base64( $self->username . ":" . $self->password );
}

sub _handle_response {
    my ($self, $json, $header) = @_;

    unless ( $header->{Status} =~ /^2/) {
        warn qq/Invalid response from server: $header->{Status} $header->{Reason}/;
        return;
    }

    my $response = JSON::RPC::Common::Procedure::Return->inflate( decode_json $json );
    my $d = delete $self->_request_pool->{ $response->id };
    unless ($d) {
        warn q/Invalid response from server/;
        return;
    }

    if (my $error = $response->error) {
        $d->[1]->croak($error);
    }
    else {
        $d->[1]->send($response->result);
    }
}

sub notify {
    my ($self, $method, @params) = @_;

    my $request = JSON::RPC::Common::Call->inflate (
        version => $self->version,
        method  => $method,
        params  => $self->_params( @params ),
    );

    http_post $self->url, 
              encode_json( $request->deflate ),
              headers => { 
                  "Content-Type" => "application/json",
                  $self->_authorization_header,
              },
              sub { 1; };
}

sub _params {
    my $self = shift;

    my $param;
    if (scalar( @_ ) == 1) {
        $param = shift;
        
        $param = [ $param ] if (ref $param eq "HASH" and $self->version eq "1.0")
                            || not ref $param;
         
    } else {
        $param = [ @_ ];
    }

    return $param;
}

__PACKAGE__->meta->make_immutable;

__END__

=encoding utf-8

=begin stopwords

AnyEvent Coro JSONRPC Hostname Str HTTP HTTP-based
blockingly condvar condvars coroutine unix

=end stopwords

=head1 NAME

AnyEvent::JSONRPC::HTTP::Client - Simple HTTP-based JSONRPC client

=head1 SYNOPSIS

    use AnyEvent::JSONRPC::HTTP::Client;
    
    my $client = AnyEvent::JSONRPC::HTTP::Client->new(
        url      => 'http://rpc.example.net/issues',
        username => "pmakholm",
        password => "secret",
    );
    
    # blocking interface
    my $res = $client->call( echo => 'foo bar' )->recv; # => 'foo bar';
    
    # non-blocking interface
    $client->call( echo => 'foo bar' )->cb(sub {
        my $res = $_[0]->recv;  # => 'foo bar';
    });

=head1 DESCRIPTION

This module is the HTTP client part of L<AnyEvent::JSONRPC>.

=head2 AnyEvent condvars

The main thing you have to remember is that all the data retrieval methods
return an AnyEvent condvar, C<$cv>.  If you want the actual data from the
request, there are a few things you can do.

You may have noticed that many of the examples in the SYNOPSIS call C<recv>
on the condvar.  You're allowed to do this under 2 circumstances:

=over 4

=item Either you're in a main program,

Main programs are "allowed to call C<recv> blockingly", according to the
author of L<AnyEvent>.

=item or you're in a Coro + AnyEvent environment.

When you call C<recv> inside a coroutine, only that coroutine is blocked
while other coroutines remain active.  Thus, the program as a whole is
still responsive.

=back

If you're not using Coro, and you don't want your whole program to block,
what you should do is call C<cb> on the condvar, and give it a coderef to
execute when the results come back.  The coderef will be given a condvar
as a parameter, and it can call C<recv> on it to get the data.  The final
example in the SYNOPSIS gives a brief example of this.

Also note that C<recv> will throw an exception if the request fails, so be
prepared to catch exceptions where appropriate.

Please read the L<AnyEvent> documentation for more information on the proper
use of condvars.

=head1 METHODS

=head2 new (%options)

Create new client object and return it.

    my $client = AnyEvent::JSONRPC::HTTP::Client->new(
        host => '127.0.0.1',
        port => 4423,
        %options,
    );

Available options are:

=over 4

=item url => 'Str'

URL to json-RPC endpoint to connect. (Required)

=item username => 'Str'

Username to use for authorization (Optional).

If this is set an Authorization header containing basic auth credential is
always sent with request.

=item password => 'Str'

Password used for authorization (optional)

=back

=head2 call ($method, @params)

Call remote method named C<$method> with parameters C<@params>. And return condvar object for response.

    my $cv = $client->call( echo => 'Hello!' );
    my $res = $cv->recv;

If server returns an error, C<< $cv->recv >> causes croak by using C<< $cv->croak >>. So you can handle this like following:

    my $res;
    eval { $res = $cv->recv };
    
    if (my $error = $@) {
        # ...
    }

=head2 notify ($method, @params)

Same as call method, but not handle response. This method just notify to server.

    $client->notify( echo => 'Hello' );

=head1 AUTHOR

Peter Makholm <peter@makholm.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 by Peter Makholm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
