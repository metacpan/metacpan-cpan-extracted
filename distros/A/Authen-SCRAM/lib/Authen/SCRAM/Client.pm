use 5.008;
use strict;
use warnings;

package Authen::SCRAM::Client;
# ABSTRACT: RFC 5802 SCRAM client

our $VERSION = '0.011';

use Moo 1.001000;

use Carp qw/croak/;
use Encode qw/encode_utf8/;
use MIME::Base64 qw/decode_base64/;
use PBKDF2::Tiny 0.003 qw/derive/;
use Try::Tiny;
use Types::Standard qw/Str Num/;

use namespace::clean;

#--------------------------------------------------------------------------#
# public attributes
#--------------------------------------------------------------------------#

#pod =attr username (required)
#pod
#pod Authentication identity.  This will be normalized with the SASLprep algorithm
#pod before being transmitted to the server.
#pod
#pod =cut

has username => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

#pod =attr password (required)
#pod
#pod Authentication password.  This will be normalized with the SASLprep algorithm
#pod before being transmitted to the server.
#pod
#pod =cut

has password => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

#pod =attr authorization_id
#pod
#pod If the authentication identity (C<username>) will act as a different,
#pod authorization identity, this attribute provides the authorization identity.  It
#pod is optional.  If not provided, the authentication identity is considered by the
#pod server to be the same as the authorization identity.
#pod
#pod =cut

has authorization_id => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

#pod =attr minimum_iteration_count
#pod
#pod If the server requests an iteration count less than this value, the client
#pod throws an error.  This protects against downgrade attacks.  The default is
#pod 4096, consistent with recommendations in the RFC.
#pod
#pod =cut

has minimum_iteration_count => (
    is      => 'ro',
    isa     => Num,
    default => 4096,
);

# The derived PBKDF2 password can be reused if the salt and iteration count
# is the same as a previous authentication conversation.
has _cached_credentials => (
    is      => 'rw',
    default => sub { [ "", 0, "" ] }, # salt, iterations, derived password
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

has _prepped_user => (
    is  => 'lazy',
    isa => Str,
);

sub _build__prepped_user {
    my ($self) = @_;
    return $self->_saslprep( $self->username );
}

has _prepped_pass => (
    is  => 'lazy',
    isa => Str,
);

sub _build__prepped_pass {
    my ($self) = @_;
    return $self->_saslprep( $self->password );
}

has _prepped_authz => (
    is  => 'lazy',
    isa => Str,
);

sub _build__prepped_authz {
    my ($self) = @_;
    return $self->_saslprep( $self->authorization_id );
}

has _gs2_header => (
    is  => 'lazy',
    isa => Str,
);

sub _build__gs2_header {
    my ($self) = @_;
    return $self->_construct_gs2( $self->_prepped_authz );
}

#--------------------------------------------------------------------------#
# public methods
#--------------------------------------------------------------------------#

#pod =method first_msg
#pod
#pod     $client_first_msg = $client->first_msg();
#pod
#pod This takes no arguments and returns the C<client-first-message> character
#pod string to be sent to the server to initiate a SCRAM session.  Calling this
#pod again will reset the internal state and initiate a new session.  This will
#pod throw an exception should an error occur.
#pod
#pod =cut

sub first_msg {
    my ($self) = @_;

    $self->_clear_session;
    $self->_set_session(
        n => $self->_prepped_user,
        r => $self->_get_session('_nonce'),
    );
    my $c_1_bare = $self->_join_reply(qw/n r/);
    $self->_set_session( _c1b => $c_1_bare );
    my $msg = $self->_gs2_header . $c_1_bare;
    utf8::upgrade($msg); # ensure UTF-8 encoding internally
    return $msg;
}

#pod =method final_msg
#pod
#pod     $client_final_msg = $client->final_msg( $server_first_msg );
#pod
#pod This takes the C<server-first-message> character string received from the
#pod server and returns the C<client-final-message> character string containing the
#pod authentication proof to be sent to the server.  This will throw an exception
#pod should an error occur.
#pod
#pod =cut

sub final_msg {
    my ( $self, $s_first_msg ) = @_;

    my ( $mext, @params ) = $s_first_msg =~ $self->_server_first_re;

    if ( defined $mext ) {
        croak
          "SCRAM server-first-message required mandatory extension '$mext', but we do not support it";
    }
    if ( !@params ) {
        croak "SCRAM server-first-message could not be parsed";
    }

    my $original_nonce = $self->_get_session("r");
    $self->_parse_to_session(@params);

    my $joint_nonce = $self->_get_session("r");
    unless ( $joint_nonce =~ m{^\Q$original_nonce\E.} ) {
        croak "SCRAM server-first-message nonce invalid";
    }

    # assemble client-final-wo-proof
    $self->_set_session(
        _s1 => $s_first_msg,
        c   => $self->_base64( encode_utf8( $self->_gs2_header ) ),
    );
    $self->_set_session( '_c2wop' => $self->_join_reply(qw/c r/) );

    # assemble proof
    my $salt  = decode_base64( $self->_get_session("s") );
    my $iters = $self->_get_session("i");
    if ( $iters < $self->minimum_iteration_count ) {
        croak sprintf( "SCRAM server requested %d iterations, less than the minimum of %d",
            $iters, $self->minimum_iteration_count );
    }

    my ( $stored_key, $client_key, $server_key ) = $self->computed_keys( $salt, $iters );

    $self->_set_session(
        _stored_key => $stored_key,
        _server_key => $server_key,
    );

    my $client_sig = $self->_client_sig;

    $self->_set_session( p => $self->_base64( $client_key ^ $client_sig ) );

    return $self->_join_reply(qw/c r p/);
}

#pod =method validate
#pod
#pod     $client->validate( $server_final_msg );
#pod
#pod This takes the C<server-final-message> character string received from the
#pod server and verifies that the server actually has a copy of the client
#pod credentials.  It will return true if valid and throw an exception, otherwise.
#pod
#pod =cut

sub validate {
    my ( $self, $s_final_msg ) = @_;

    my (@params) = $s_final_msg =~ $self->_server_final_re;
    $self->_parse_to_session(@params);

    if ( my $err = $self->_get_session("e") ) {
        croak "SCRAM server-final-message was error '$err'";
    }

    my $server_sig =
      $self->_hmac_fcn->( $self->_get_session("_server_key"), $self->_auth_msg );

    if ( $self->_base64($server_sig) ne $self->_get_session("v") ) {
        croak "SCRAM server-final-message failed validation";
    }

    return 1;
}

#pod =method computed_keys
#pod
#pod This method returns the opaque keys used in the SCRAM protocol.  It returns
#pod the 'stored key', the 'client key' and the 'server key'.  The server must
#pod have a copy of the stored key and server key for a given user in order to
#pod authenticate.
#pod
#pod This method caches the computed values -- it generates them fresh only if
#pod the supplied salt and iteration count don't match the cached salt and
#pod iteration count.
#pod
#pod =cut

sub computed_keys {
    my ( $self, $salt, $iters ) = @_;
    my $cache = $self->_cached_credentials;

    if ( $cache->[0] eq $salt && $cache->[1] == $iters ) {
        # return stored key, client key, server key
        return @{$cache}[ 2 .. 4 ];
    }

    my $salted_pw =
      derive( $self->digest, encode_utf8( $self->_prepped_pass ), $salt, $iters );
    my $client_key = $self->_hmac_fcn->( $salted_pw, "Client Key" );
    my $server_key = $self->_hmac_fcn->( $salted_pw, "Server Key" );
    my $stored_key = $self->_digest_fcn->($client_key);

    $self->_cached_credentials(
        [ $salt, $iters, $stored_key, $client_key, $server_key ] );

    return ( $stored_key, $client_key, $server_key );
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Authen::SCRAM::Client - RFC 5802 SCRAM client

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use Authen::SCRAM::Client;
    use Try::Tiny;

    $client = Authen::SCRAM::Client->new(
        username => 'johndoe',
        password => 'trustno1',
    );

    try {
        $client_first = $client->first_msg();

        # send to server and get server-first-message

        $client_final = $client->final_msg( $server_first );

        # send to server and get server-final-message

        $client->validate( $server_final );
    }
    catch {
        die "Authentication failed!"
    };

=head1 DESCRIPTION

This module implements the client-side SCRAM algorithm.

=head1 NAME

Authen::SCRAM::Client - RFC 5802 SCRAM client

=head1 VERSION

version 0.011

=head1 ATTRIBUTES

=head2 username (required)

Authentication identity.  This will be normalized with the SASLprep algorithm
before being transmitted to the server.

=head2 password (required)

Authentication password.  This will be normalized with the SASLprep algorithm
before being transmitted to the server.

=head2 authorization_id

If the authentication identity (C<username>) will act as a different,
authorization identity, this attribute provides the authorization identity.  It
is optional.  If not provided, the authentication identity is considered by the
server to be the same as the authorization identity.

=head2 minimum_iteration_count

If the server requests an iteration count less than this value, the client
throws an error.  This protects against downgrade attacks.  The default is
4096, consistent with recommendations in the RFC.

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

    $client_first_msg = $client->first_msg();

This takes no arguments and returns the C<client-first-message> character
string to be sent to the server to initiate a SCRAM session.  Calling this
again will reset the internal state and initiate a new session.  This will
throw an exception should an error occur.

=head2 final_msg

    $client_final_msg = $client->final_msg( $server_first_msg );

This takes the C<server-first-message> character string received from the
server and returns the C<client-final-message> character string containing the
authentication proof to be sent to the server.  This will throw an exception
should an error occur.

=head2 validate

    $client->validate( $server_final_msg );

This takes the C<server-final-message> character string received from the
server and verifies that the server actually has a copy of the client
credentials.  It will return true if valid and throw an exception, otherwise.

=head2 computed_keys

This method returns the opaque keys used in the SCRAM protocol.  It returns
the 'stored key', the 'client key' and the 'server key'.  The server must
have a copy of the stored key and server key for a given user in order to
authenticate.

This method caches the computed values -- it generates them fresh only if
the supplied salt and iteration count don't match the cached salt and
iteration count.

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
