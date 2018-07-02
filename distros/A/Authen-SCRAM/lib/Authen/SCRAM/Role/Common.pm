use 5.008;
use strict;
use warnings;

package Authen::SCRAM::Role::Common;

our $VERSION = '0.011';

use Moo::Role 1.001000;

use Authen::SASL::SASLprep 1.100 qw/saslprep/;
use Carp qw/croak/;
use Crypt::URandom qw/urandom/;
use Encode qw/encode_utf8/;
use MIME::Base64 qw/encode_base64/;
use PBKDF2::Tiny 0.003 qw/digest_fcn hmac/;
use Try::Tiny;
use Types::Standard qw/Bool Enum Num HashRef CodeRef/;

use namespace::clean;

#--------------------------------------------------------------------------#
# public attributes
#--------------------------------------------------------------------------#

has digest => (
    is      => 'ro',
    isa     => Enum [qw/SHA-1 SHA-224 SHA-256 SHA-384 SHA-512/],
    default => 'SHA-1',
);

has nonce_size => (
    is      => 'ro',
    isa     => Num,
    default => 192,
);

has skip_saslprep => (
    is  => 'ro',
    isa => Bool,
);

#--------------------------------------------------------------------------#
# private attributes
#--------------------------------------------------------------------------#

has _const_eq_fcn => (
    is  => 'lazy',
    isa => CodeRef,
);

# constant time comparison to avoid timing attacks; uses
# String::Compare::ConstantTime if available or a pure-Perl fallback
sub _build__const_eq_fcn {
    my ($self) = @_;
    # XXX disable String::Compare::ConstantTime until a new version
    # is released that fixes warnings on older perls.
    if ( 0 && eval { require String::Compare::ConstantTime; 1 } ) {
        return \&String::Compare::ConstantTime::equals;
    }
    else {
        return sub {
            my ( $dk1, $dk2 ) = @_;
            my $dk1_length = length($dk1);
            return unless $dk1_length == length($dk2);
            my $match = 1;
            for my $offset ( 0 .. $dk1_length ) {
                $match &= ( substr( $dk1, $offset, 1 ) eq substr( $dk2, $offset, 1 ) ) ? 1 : 0;
            }
            return $match;
        };
    }
}

has _digest_fcn => (
    is  => 'lazy',
    isa => CodeRef,
);

sub _build__digest_fcn {
    my ($self) = @_;
    my ($fcn)  = digest_fcn( $self->digest );
    return $fcn;
}

# _hmac_fcn( $key, $data ) -- this matches RFC 5802 parameter order but
# is reversed from Digest::HMAC/PBKDF2::Tiny which uses (data, key)
has _hmac_fcn => (
    is  => 'lazy',
    isa => CodeRef,
);

sub _build__hmac_fcn {
    my ($self) = @_;
    my ( $fcn, $block_size, $digest_length ) = digest_fcn( $self->digest );
    return sub {
        my ( $key, $data ) = @_;
        $key = $fcn->($key) if length($key) > $block_size;
        return hmac( $data, $key, $fcn, $block_size );
    };
}

# helpful for testing
has _nonce_generator => (
    is  => 'lazy',
    isa => CodeRef,
);

sub _build__nonce_generator {
    my ($self) = @_;
    # extract from $self to avoid circular reference
    my $nonce_size = $self->nonce_size;
    return sub { return encode_base64( urandom( $nonce_size / 8 ), "" ) };
}

# _session builds up parameters used during a SCRAM session.  Keys
# starting with "_" are private state not used for exchange.  Single
# letter keys are defined as per RFC5802
#
# _nonce        private nonce part
# _c1b          client-first-message-bare
# _s1           server-first-message
# _c2wop        client-final-message-without-proof
# _stored_key   H(ClientKey)
# _server_key   HMAC(SaltedPassword, "Server Key")
# _auth         AuthMessage

has _session => (
    is      => 'lazy',
    isa     => HashRef,
    clearer => 1,
);

sub _build__session {
    my ($self) = @_;
    return { _nonce => $self->_nonce_generator->() };
}

#--------------------------------------------------------------------------#
# methods
#--------------------------------------------------------------------------#

sub _auth_msg {
    my ($self) = @_;
    return $self->_session->{_auth} ||=
      encode_utf8( join( ",", map { $self->_session->{$_} } qw/_c1b _s1 _c2wop/ ) );
}

sub _base64 {
    my ( $self, $data ) = @_;
    return encode_base64( $data, "" );
}

sub _client_sig {
    my ($self) = @_;
    return $self->_hmac_fcn->( $self->_session->{_stored_key}, $self->_auth_msg );
}

sub _construct_gs2 {
    my ( $self, $authz ) = @_;
    my $maybe =
        ( defined($authz) && length($authz) )
      ? ( "a=" . $self->_encode_name($authz) )
      : "";
    return "n,$maybe,";
}

sub _decode_name {
    my ( $self, $name ) = @_;
    $name =~ s/=2c/,/g;
    $name =~ s/=3d/=/g;
    return $name;
}

sub _encode_name {
    my ( $self, $name ) = @_;
    $name =~ s/=/=3d/g;
    $name =~ s/,/=2c/g;
    return $name;
}

sub _extend_nonce {
    my ($self) = @_;
    $self->_session->{r} .= $self->_session->{_nonce};
}

sub _get_session {
    my ( $self, $key ) = @_;
    return $self->_session->{$key};
}

sub _join_reply {
    my ( $self, @fields ) = @_;
    my @reply;
    for my $k (@fields) {
        my $v = $self->_session->{$k};
        if ( $k eq 'a' || $k eq 'n' ) {
            $v = $self->_encode_name($v);
        }
        push @reply, "$k=$v";
    }
    my $msg = '' . join( ",", @reply );
    utf8::upgrade($msg);
    return $msg;
}

sub _parse_to_session {
    my ( $self, @params ) = @_;
    for my $part (@params) {
        my ( $k, $v ) = split /=/, $part, 2;
        if ( $k eq 'a' || $k eq 'n' ) {
            $v = $self->_saslprep( $self->_decode_name($v) );
        }
        elsif ( $k eq 'i' && $v !~ /^[0-9]+$/ ) {
            croak "SCRAM iteration parameter '$part' invalid";
        }
        $self->_session->{$k} = $v;
    }
    return;
}

sub _saslprep {
    my ( $self, $name ) = @_;

    return $name if $self->skip_saslprep;

    my $prepped = try {
        saslprep( $name, 1 ); # '1' makes it use stored mode
    }
    catch {
        croak "SCRAM username '$name' invalid: $_";
    };
    return $prepped;
}

sub _set_session {
    my ( $self, %args ) = @_;
    while ( my ( $k, $v ) = each %args ) {
        $self->_session->{$k} = $v;
    }
    return;
}

#--------------------------------------------------------------------------#
# regular expressions for parsing
#--------------------------------------------------------------------------#

# tokens
my $VALUE    = qr/[^,]+/;
my $CBNAME   = qr/[a-zA-Z0-9.-]+/;
my $ATTR_VAL = qr/[a-zA-Z]=$VALUE/;

# atoms
my $GS2_CBIND_FLAG = qr/(?:n|y|p=$VALUE)/;
my $AUTHZID        = qr/a=$VALUE/;
my $CHN_BIND       = qr/c=$VALUE/;
my $S_ERROR        = qr/e=$VALUE/;
my $ITER_CNT       = qr/i=$VALUE/;
my $MEXT           = qr/m=$VALUE/;
my $USERNAME       = qr/n=$VALUE/;
my $PROOF          = qr/p=$VALUE/;
my $NONCE          = qr/r=$VALUE/;
my $SALT           = qr/s=$VALUE/;
my $VERIFIER       = qr/v=$VALUE/;
my $EXT            = qr/$ATTR_VAL (?: , $ATTR_VAL)*/;

# constructions
my $C_FRST_BARE   = qr/(?:($MEXT),)? ($USERNAME) , ($NONCE) (?:,$EXT)?/x;
my $GS2_HEADER    = qr/($GS2_CBIND_FLAG) , ($AUTHZID)? , /x;
my $C_FINL_WO_PRF = qr/($CHN_BIND) , ($NONCE) (?:,$EXT)?/x;

# messages
my $C_FRST_MSG = qr/$GS2_HEADER ($C_FRST_BARE)/x;
my $S_FRST_MSG = qr/(?:($MEXT),)? ($NONCE) , ($SALT) , ($ITER_CNT) (?:,$EXT)?/x;
my $C_FINL_MSG = qr/($C_FINL_WO_PRF) , ($PROOF)/x;
my $S_FINL_MSG = qr/($S_ERROR | $VERIFIER)/x;

sub _client_first_re { $C_FRST_MSG } # ($cbind, $authz?, $c_1_bare, $mext?, @params)
sub _server_first_re { $S_FRST_MSG } # ($mext?, @params)
sub _client_final_re { $C_FINL_MSG } # ($c_2_wo_proof, @params)
sub _server_final_re { $S_FINL_MSG } # ($error_or_verification)

1;

=pod

=for Pod::Coverage digest nonce_size skip_saslprep

=cut

# vim: ts=4 sts=4 sw=4 et:
