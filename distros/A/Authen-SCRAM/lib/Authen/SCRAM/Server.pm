use 5.008;
use strict;
use warnings;

package Authen::SCRAM::Server;
# ABSTRACT: RFC 5802 SCRAM Server

our $VERSION = '0.011';

use Moo 1.001000;

use Authen::SASL::SASLprep qw/saslprep/;
use Carp qw/croak/;
use Crypt::URandom qw/urandom/;
use Encode qw/encode_utf8/;
use MIME::Base64 qw/decode_base64/;
use PBKDF2::Tiny 0.003 qw/derive digest_fcn hmac/;
use Types::Standard qw/Str Num CodeRef Bool/;

use namespace::clean;

with 'Authen::SCRAM::Role::Common';

#--------------------------------------------------------------------------#
# public attributes
#--------------------------------------------------------------------------#

#pod =attr credential_cb (required)
#pod
#pod This attribute must contain a code reference that takes a username (as a
#pod character string normalized by SASLprep) and returns the four user-credential
#pod parameters required by SCRAM: C<salt>, C<StoredKey>, C<ServerKey>, and
#pod C<iteration count>.  The C<salt>, C<StoredKey> and C<ServerKey> must be
#pod provided as octets (i.e. B<NOT> base64 encoded).
#pod
#pod If the username is unknown, it should return an empty list.
#pod
#pod     ($salt, $stored_key, $server_key, $iterations) =
#pod         $server->credential_cb->( $username );
#pod
#pod See L<RFC 5802: SCRAM Algorithm Overview|http://tools.ietf.org/html/rfc5802#section-3>
#pod for details.
#pod
#pod =cut

has credential_cb => (
    is       => 'ro',
    isa      => CodeRef,
    required => 1,
);

#pod =attr auth_proxy_cb
#pod
#pod If provided, this attribute must contain a code reference that takes an
#pod B<authentication> username and a B<authorization> username (both as character
#pod strings), and return a true value if the authentication username is permitted
#pod to act as the authorization username:
#pod
#pod     $bool = $server->auth_proxy_cb->(
#pod         $authentication_user, $authorization_user
#pod     );
#pod
#pod It will only be all called if the authentication username has successfully
#pod authenticated.  Both usernames will have been normalized via C<SASLprep> with
#pod any transport encoding removed before being passed to this function.
#pod
#pod =cut

has auth_proxy_cb => (
    is      => 'ro',
    isa     => CodeRef,
    default => sub {
        return sub { 1 }
    },
);

#--------------------------------------------------------------------------#
# provided by Authen::SCRAM::Role::Common
#--------------------------------------------------------------------------#

with 'Authen::SCRAM::Role::Common';

#pod =attr digest
#pod
#pod Name of a digest function available via L<PBKDF2::Tiny>.  Valid values are
#pod SHA-1, SHA-224, SHA-256, SHA-384, or SHA-512.  Defaults to SHA-1.
#pod
#pod =attr nonce_size
#pod
#pod Size of the client-generated nonce, in bits.  Defaults to 192.
#pod The server-nonce will be appended, so the final nonce size will
#pod be substantially larger.
#pod
#pod =attr skip_saslprep
#pod
#pod A boolean that defaults to false.  If set to true, usernames and passwords will
#pod not be normalized through SASLprep.  This is a deviation from the RFC5802 spec
#pod and is not recommended.
#pod
#pod =cut

#--------------------------------------------------------------------------#
# private attributes
#--------------------------------------------------------------------------#

has _proof_ok => (
    is     => 'ro',
    isa    => Bool,
    writer => '_set_proof_ok',
);

#--------------------------------------------------------------------------#
# public methods
#--------------------------------------------------------------------------#

#pod =method first_msg
#pod
#pod     $server_first_msg = $server->first_msg( $client_first_msg );
#pod
#pod This takes the C<client-first-message> received from the client and returns the
#pod C<server-first-message> string to be sent to the client to continue a SCRAM
#pod session.  Calling this again will reset the internal state and initiate a new
#pod session.  This will throw an exception should an error occur.
#pod
#pod =cut

sub first_msg {
    my ( $self, $msg ) = @_;
    $self->_clear_session;

    my ( $cbind, $authz, $c_1_bare, $mext, @params ) = $msg =~ $self->_client_first_re;

    if ( !defined $cbind ) {
        croak "SCRAM client-first-message could not be parsed";
    }
    if ( $cbind eq 'p' ) {
        croak
          "SCRAM client-first-message required channel binding, but we do not support it";
    }
    if ( defined $mext ) {
        croak
          "SCRAM client-first-message required mandatory extension '$mext', but we do not support it";
    }

    push @params, $authz if defined $authz;
    $self->_parse_to_session(@params);
    $self->_extend_nonce;

    my $name = $self->_get_session('n');
    my ( $salt, $stored_key, $server_key, $iters ) = $self->credential_cb->($name);

    if ( !defined $salt ) {
        croak "SCRAM client-first-message had unknown user '$name'";
    }

    $self->_set_session(
        s           => $self->_base64($salt),
        i           => $iters,
        _c1b        => $c_1_bare,
        _stored_key => $stored_key,
        _server_key => $server_key
    );

    my $reply = $self->_join_reply(qw/r s i/);
    $self->_set_session( _s1 => $reply );

    return $reply;
}

#pod =method final_msg
#pod
#pod     $server_final_msg = $server->final_msg( $client_final_msg );
#pod
#pod This takes the C<client-final-message> received from the client and returns the
#pod C<server-final-message> string containing the verification signature to be sent
#pod to the client.
#pod
#pod If an authorization identity was provided by the client, it will confirm that
#pod the authenticating username is authorized to act as the authorization id using
#pod the L</auth_proxy_cb> attribute.
#pod
#pod If the client credentials do not match or the authentication name is not
#pod authorized to act as the authorization name, then an exception will be thrown.
#pod
#pod =cut

sub final_msg {
    my ( $self, $msg ) = @_;

    my ( $c2wop, @params ) = $msg =~ $self->_client_final_re;
    $self->_set_session( _c2wop => $c2wop );

    if ( !defined $c2wop ) {
        croak "SCRAM client-first-message could not be parsed";
    }

    # confirm nonce
    my $original_nonce = $self->_get_session("r");
    $self->_parse_to_session(@params);
    my $joint_nonce = $self->_get_session("r");
    unless ( $joint_nonce eq $original_nonce ) {
        croak "SCRAM client-final-message nonce invalid";
    }

    # confirm channel bindings
    my $cbind =
      $self->_base64( encode_utf8( $self->_construct_gs2( $self->_get_session("a") ) ) );
    if ( $cbind ne $self->_get_session("c") ) {
        croak "SCRAM client-final-message channel binding didn't match";
    }

    # confirm proof

    my $client_sig   = $self->_client_sig;
    my $proof        = decode_base64( $self->_get_session("p") );
    my $client_key   = $proof ^ $client_sig;
    my $computed_key = $self->_digest_fcn->($client_key);
    my $name         = $self->_get_session("n");

    if ( !$self->_const_eq_fcn->( $computed_key, $self->_get_session("_stored_key") ) ) {
        croak "SCRAM authentication for user '$name' failed";
    }

    if ( my $authz = $self->_get_session("a") ) {
        $self->auth_proxy_cb->( $name, $authz )
          or croak("SCRAM authentication failed; '$name' not authorized to act as '$authz'");
    }

    $self->_set_session( _proof_ok => 1 );

    my $server_sig =
      $self->_hmac_fcn->( $self->_get_session('_server_key'), $self->_auth_msg );

    $self->_set_session( v => $self->_base64($server_sig) );

    $self->_join_reply('v');
}

#pod =method authorization_id 
#pod
#pod     $username = $client->authorization_id();
#pod
#pod This takes no arguments and returns the authorization identity resulting from
#pod the SCRAM exchange.  This is the client-supplied authorization identity (if one
#pod was provided and validated) or else the successfully authenticated identity.
#pod
#pod =cut

sub authorization_id {
    my ($self) = @_;
    return '' unless $self->_get_session("_proof_ok");
    my $authz = $self->_get_session("a");
    return ( defined($authz) && length($authz) ) ? $authz : $self->_get_session("n");
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Authen::SCRAM::Server - RFC 5802 SCRAM Server

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use Authen::SCRAM::Server;
    use Try::Tiny;

    $server = Authen::SCRAM::Server->new(
        credential_cb => \&get_credentials,
    );

    $username = try {
        # get client-first-message

        $server_first = $server->first_msg( $client_first );

        # send to client and get client-final-message

        $server_final = $server->final_msg( $client_final );

        # send to client

        return $server->authorization_id; # returns valid username
    }
    catch {
        die "Authentication failed!"
    };

=head1 DESCRIPTION

This module implements the server-side SCRAM algorithm.

=head1 NAME

Authen::SCRAM::Server - RFC 5802 SCRAM Server

=head1 VERSION

version 0.011

=head1 ATTRIBUTES

=head2 credential_cb (required)

This attribute must contain a code reference that takes a username (as a
character string normalized by SASLprep) and returns the four user-credential
parameters required by SCRAM: C<salt>, C<StoredKey>, C<ServerKey>, and
C<iteration count>.  The C<salt>, C<StoredKey> and C<ServerKey> must be
provided as octets (i.e. B<NOT> base64 encoded).

If the username is unknown, it should return an empty list.

    ($salt, $stored_key, $server_key, $iterations) =
        $server->credential_cb->( $username );

See L<RFC 5802: SCRAM Algorithm Overview|http://tools.ietf.org/html/rfc5802#section-3>
for details.

=head2 auth_proxy_cb

If provided, this attribute must contain a code reference that takes an
B<authentication> username and a B<authorization> username (both as character
strings), and return a true value if the authentication username is permitted
to act as the authorization username:

    $bool = $server->auth_proxy_cb->(
        $authentication_user, $authorization_user
    );

It will only be all called if the authentication username has successfully
authenticated.  Both usernames will have been normalized via C<SASLprep> with
any transport encoding removed before being passed to this function.

=head2 digest

Name of a digest function available via L<PBKDF2::Tiny>.  Valid values are
SHA-1, SHA-224, SHA-256, SHA-384, or SHA-512.  Defaults to SHA-1.

=head2 nonce_size

Size of the client-generated nonce, in bits.  Defaults to 192.
The server-nonce will be appended, so the final nonce size will
be substantially larger.

=head2 skip_saslprep

A boolean that defaults to false.  If set to true, usernames and passwords will
not be normalized through SASLprep.  This is a deviation from the RFC5802 spec
and is not recommended.

=head1 METHODS

=head2 first_msg

    $server_first_msg = $server->first_msg( $client_first_msg );

This takes the C<client-first-message> received from the client and returns the
C<server-first-message> string to be sent to the client to continue a SCRAM
session.  Calling this again will reset the internal state and initiate a new
session.  This will throw an exception should an error occur.

=head2 final_msg

    $server_final_msg = $server->final_msg( $client_final_msg );

This takes the C<client-final-message> received from the client and returns the
C<server-final-message> string containing the verification signature to be sent
to the client.

If an authorization identity was provided by the client, it will confirm that
the authenticating username is authorized to act as the authorization id using
the L</auth_proxy_cb> attribute.

If the client credentials do not match or the authentication name is not
authorized to act as the authorization name, then an exception will be thrown.

=head2 authorization_id 

    $username = $client->authorization_id();

This takes no arguments and returns the authorization identity resulting from
the SCRAM exchange.  This is the client-supplied authorization identity (if one
was provided and validated) or else the successfully authenticated identity.

=for Pod::Coverage BUILD

=head1 CHARACTER ENCODING CAVEAT

The SCRAM protocol mandates UTF-8 interchange.  However, all methods in this
module take and return B<character> strings.  You must encode to UTF-8 before
sending and decode from UTF-8 on receiving according to whatever transport
mechanism you are using.

This is done to avoid double encoding/decoding problems if your transport is
already doing UTF-8 encoding or decoding as it constructs outgoing messages or
parses incoming messages.

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
