package API::MailboxOrg::APIBase;

# ABSTRACT: Base class for all entity classes

use v5.24;

use strict;
use warnings;

use Carp;
use Moo;
use Params::ValidationCompiler qw(validation_for);
use Types::Mojo qw(:all);
use Types::Standard qw(Str Object Int);

use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '1.0.2'; # VERSION

has api      => ( is => 'ro', isa => Object, required => 1 );
has json_rpc => ( is => 'ro', isa => Str, default => sub { '2.0' } );

state $request_id = 1;

sub _request ( $self, $method, $params = {}, $opts = {} ) {
    my $rpc_data = {
        jsonrpc => $self->json_rpc,
        id      => $request_id++,
        method  => $method,
    };

    $rpc_data->{params} = $params->%* ? $params : "";

    my $api = $self->api;

    if ( $opts->{needs_auth} && !$api->token ) {
        my $auth_result = $api->base->auth(
            user => $api->user,
            pass => $api->password,
        );

        my $token = ref $auth_result ?
            $auth_result->{session} :
            croak 'Could not login: ' . $auth_result;

        $api->_set_token( $token );
    }

    my %header = ( 'Content-Type' => 'application/json' );
    $header{'HPLS-AUTH'} = $api->token if $api->token;

    my $uri = join '/',
        $api->host,
        $api->base_uri;

    my $tx = $api->client->post(
        $uri,
        \%header,
        json => $rpc_data,
    );

    my $response = $tx->res;

    if ( $tx->error ) {
        carp $tx->error->{message};
        return;
    }

    my $data = $response->json;

    if ( $data->{error} ) {
        carp $data->{error}->{message};
        return;
    }

    return $data->{result};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::MailboxOrg::APIBase - Base class for all entity classes

=head1 VERSION

version 1.0.2

=head1 ATTRIBUTES

=over 4

=item * json_rpc

I<(optional)> The version of JSON-RPC used. Defaults to C<2.0>.

=item * api

I<mandatory> An L<API::MailboxOrg> object.

=back

=head1 METHODS

=head2 request

This method builds the API request. If a method is called that needs authentification
and there's no session, then the C<auth> method is called.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
