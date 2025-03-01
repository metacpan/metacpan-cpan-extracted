use strict;
use warnings;
use 5.010_001;

package    # hide from PAUSE
    DBIx::Squirrel::Crypt::Fernet;

=head1 NAME

DBIx::Squirrel::Crypt::Fernet - Fernet symmetric encryption

=head1 SYNOPSIS

    #############################
    # Object-oriented Interface #
    #############################

    # Import the helper
    use DBIx::Squirrel::Crypt::Fernet 'Fernet';

    # Generate random key
    $fernet = Fernet();

    # Use pre-defined Base64-encoded key
    $fernet = Fernet($key);

    # Import nothing
    use DBIx::Squirrel::Crypt::Fernet;

    # Generate random key
    $fernet = DBIx::Squirrel::Crypt::Fernet->new();

    # Use pre-defined Base64-encoded key
    $fernet = DBIx::Squirrel::Crypt::Fernet->new($key);

    # Encrypt message
    $token = $fernet->encrypt($message);

    # Decrypt token
    $message = $fernet->decrypt($token);

    # Verify token
    $bool = $fernet->verify($token);

    # Decrypt token, check time-to-live (secs) has not expired
    $message = $fernet->decrypt($token, $ttl);

    # Verify token, check time-to-live (secs) has not expired
    $bool = $fernet->verify($token, $ttl);

    # Retrieve Base64-encoded key
    $key = $fernet->to_string();
    $key = "$fernet";

    ######################
    # Exported functions #
    ######################

    # Import functions
    use DBIx::Squirrel::Crypt::Fernet qw(
        generatekey
        encrypt
        decrypt
        verify
    );

    # Import Crypt::Fernet-like interface
    use DBIx::Squirrel::Crypt::Fernet qw(
        fernet_genkey
        fernet_encrypt
        fernet_decrypt
        fernet_verify
    );

    # Generate a Base64-encoded random key
    $key = generatekey();
    $key = fernet_genkey();

    # Encrypt message
    $token = encrypt($key, $message);
    $token = fernet_encrypt($key, $message);

    # Decrypt token
    $message = decrypt($key, $token);
    $message = fernet_decrypt($key, $token);

    # Verify token
    $bool = verify($key, $token);
    $bool = fernet_verify($key, $token);

    # Decrypt token, check time-to-live (secs) has not expired
    $message = decrypt($key, $token, $ttl);
    $message = fernet_decrypt($key, $token, $ttl);

    # Verify token, check time-to-live (secs) has not expired
    $bool = verify($key, $token, $ttl);
    $bool = fernet_verify($key, $token, $ttl);

=head1 DESCRIPTION

Fernet takes a user-provided message (an arbitrary sequence of bytes), a
256-bit key, and the current time, and it produces a token containing the
message in a form that can't be read or altered without the key.

See L<https://github.com/fernet/spec/blob/master/Spec.md> for more detail.

=cut

our @ISA = qw(Exporter);
our @EXPORT;
our %EXPORT_TAGS = ( all => [
    our @EXPORT_OK = qw(
        fernet_decrypt
        fernet_encrypt
        fernet_genkey
        fernet_verify
        decrypt
        encrypt
        generatekey
        verify
        Fernet
    )
] );
our $VERSION = '1.0.0';

require Crypt::CBC;
require Crypt::Rijndael;
require Exporter;

use Const::Fast 'const';
use Digest::SHA 'hmac_sha256';
use MIME::Base64::URLSafe qw(
    urlsafe_b64decode
    urlsafe_b64encode
);
use namespace::clean;
use overload '""' => \&to_string;    # overload after namespace::clean for stringification to work

const my $TOKEN_VERSION  => pack( "H*", '80' );
const my $LEN_HDR        => 25;
const my $LEN_DIGEST     => 32;
const my $LEN_HDR_DIGEST => $LEN_HDR + $LEN_DIGEST;

# Calculate the age (seconds) of a token from its timestamp field.
sub _age_sec {
    use bytes;
    my($token) = @_;
    return time - unpack( 'V', reverse( substr( $token, 1, 8 ) ) );
}


# Generate a timestamp field that can be embedded in a token.
sub _timestamp {
    use bytes;
    local $_;
    my $t = time();
    my @p = map( substr( pack( 'I', ( $t >> $_ * 8 ) & 0xFF ), 0, 1 ), 0 .. 7 );
    return join( '', reverse(@p) );
}


# Generate a random 32-byte Fernet key.
sub _rand_key {
    return Crypt::CBC->random_bytes(32);
}


# Encode a binary string as Base64 with padding.
sub _pad_b64encode {
    my $b64 = urlsafe_b64encode(shift);
    return $b64 . '=' x ( 4 - length($b64) % 4 );
}


=head2 METHODS

=head3 C<new>

    $obj = DBIx::Squirrel::Crypt::Fernet->new();
    $obj = DBIx::Squirrel::Crypt::Fernet->new($key);

A constructor (also see L<Fernet>).

If no arguments are passed then a random 32-byte Fernet key is generated. If
a Base64-encoded key is passed then it will be decoded and its signing and
encryption key fields extracted.

Take care never to display the binary signing and extraction keys, but to use
the C<to_string> method (or stringification) to recombine them into a Base64-
encoded Fernet key.

=cut

sub new {
    my( $class, $b64key ) = @_;
    my $fernet_key = $b64key ? urlsafe_b64decode($b64key) : _rand_key();
    my $self       = {
        signing_key => substr( $fernet_key, 0,  16 ),
        encrypt_key => substr( $fernet_key, 16, 16 ),
    };
    return bless $self, ref($class) || $class;
}


=head3 C<generatekey>

    $key = $obj->generatekey();
    $key = DBIx::Squirrel::Crypt::Fernet->generatekey();

Returns a Base64-encoded randomly-generated key.

=cut

sub generatekey {
    return _pad_b64encode( _rand_key() );
}


=head3 C<encrypt>

    $token = $obj->encrypt($message);

Encrypts a message, returning a Base64-encode token.

=cut

sub encrypt {
    my( $self_or_b64key, $data )        = @_;
    my( $signing_key,    $encrypt_key ) = do {
        if ( UNIVERSAL::isa( $self_or_b64key, __PACKAGE__ ) ) {
            @{$self_or_b64key}{qw(signing_key encrypt_key)};
        }
        else {
            my $key = urlsafe_b64decode($self_or_b64key);
            substr( $key, 0, 16 ), substr( $key, 16, 16 );
        }
    };
    my $iv = Crypt::CBC->random_bytes(16);
    my $t  = $TOKEN_VERSION . _timestamp() . $iv . Crypt::CBC->new(
        -cipher      => 'Rijndael',
        -header      => 'none',
        -iv          => $iv,
        -key         => $encrypt_key,
        -keysize     => 16,
        -literal_key => 1,
    )->encrypt($data);
    return _pad_b64encode( $t . hmac_sha256( $t, $signing_key ) );
}


=head3 C<decrypt>

    $message = $obj->decrypt($token);
    $message = $obj->decrypt($token, $ttl);

Returns the decrypted message, or C<undef> if the token could not be
decrypted. If a time-to-live (seconds) is specified (C<$ttl>) then a
further check is made to ensure that the token has not expired.

=cut

sub decrypt {
    my( $self_or_b64key, $b64token, $ttl ) = @_;
    return unless verify( $self_or_b64key, $b64token, $ttl );
    my $encrypt_key = do {
        if ( UNIVERSAL::isa( $self_or_b64key, __PACKAGE__ ) ) {
            $self_or_b64key->{encrypt_key};
        }
        else {
            substr( urlsafe_b64decode($self_or_b64key), 16, 16 );
        }
    };
    my $t = urlsafe_b64decode($b64token);
    return Crypt::CBC->new(
        -cipher      => 'Rijndael',
        -header      => 'none',
        -iv          => substr( $t, 9, 16 ),
        -key         => $encrypt_key,
        -keysize     => 16,
        -literal_key => 1,
    )->decrypt( substr( $t, $LEN_HDR, length($t) - $LEN_HDR_DIGEST ) );
}


=head3 C<verify>

    $bool = $obj->verify($token);
    $bool = $obj->verify($token, $ttl);

Returns true if the token was signed using the same signing key as that
embedded in the Fernet key. If a time-to-live (seconds) is specified (C<$ttl>)
then a further check is made to ensure that the token has not expired.

=cut

sub verify {
    my( $self_or_b64key, $b64token, $ttl ) = @_;
    my $signing_key = do {
        if ( UNIVERSAL::isa( $self_or_b64key, __PACKAGE__ ) ) {
            $self_or_b64key->{signing_key};
        }
        else {
            substr( urlsafe_b64decode($self_or_b64key), 0, 16 );
        }
    };
    my $t = urlsafe_b64decode($b64token);
    return !!0
        if $TOKEN_VERSION ne substr( $t, 0, 1 ) || $ttl && _age_sec($t) > $ttl;
    my $digest = substr( $t, length($t) - $LEN_DIGEST, $LEN_DIGEST, '' );    # 4-arg substr removes $digest from $token
    return $digest eq hmac_sha256( $t, $signing_key );
}


=head3 C<to_string>

    $key = $obj->to_string();
    $key = "$obj";

Returns the Base64-encoded key.

=cut

sub to_string {
    my($self) = @_;
    return _pad_b64encode( join( '', @{$self}{qw(signing_key encrypt_key)} ) );
}


=head2 EXPORTS

This package exports nothing by default.

=head3 C<Fernet>

    $obj = Fernet();
    $obj = Fernet($key);

Alternative constructor (also see L<new>).

Returns a new C<DBIx::Squirrel::Crypt::Fernet> object.

If no arguments are passed then a random 32-byte Fernet key is generated. If
a Base64-encoded key is passed then it will be decoded and its signing and
encryption key fields extracted.

Take care never to display the binary signing and extraction keys, but to use
the C<to_string> method (or stringification) to recombine them into a Base64-
encoded Fernet key.

=cut

sub Fernet {
    return __PACKAGE__->new(@_);
}


=head3 C<generatekey>

    $key = generatekey();

Returns a Base64-encoded randomly-generated key.

=head3 C<encrypt>

    $token = encrypt($key, $message);

Encrypts a message, returning a Base64-encode token.

While a Base64-encoded key may be passed as the first argument, it would be
more efficient to call the "two-faced" C<encrypt> as a method on a Fernet
object to avoid the repeated overhead of decoding and parsing-out the signing
and encryption keys.

=head3 C<decrypt>

    $message = decrypt($key, $token);
    $message = decrypt($key, $token, $ttl);

Returns the decrypted message, or C<undef> if the token could not be
decrypted. If a time-to-live (seconds) is specified (C<$ttl>) then a
further check is made to ensure that the token has not expired.

While a Base64-encoded key may be passed as the first argument, it would be
more efficient to call the "two-faced" C<decrypt> as a method on a Fernet
object to avoid the repeated overhead of decoding and parsing-out the signing
and encryption keys.

=head3 C<verify>

    $bool = verify($key, $token);
    $bool = verify($key, $token, $ttl);

Returns true if the token was signed using the same signing key as that
embedded in the Fernet key. If a time-to-live (seconds) is specified (C<$ttl>)
then a further check is made to ensure that the token has not expired.

While a Base64-encoded key may be passed as the first argument, it would be
more efficient to call the "two-faced" C<verify> as a method on a Fernet
object to avoid the repeated overhead of decoding and parsing-out the signing
and encryption keys.

=cut


=head2 LEGACY C<Crypt::Fernet> INTERFACE

At the time I wanted to use Wan Leung Wong's C<Crypt::Fernet> package, it had
a few testing failures and would not build. I'm pretty sure the C<Crypt::CBC>
dependency introduced a breaking change. I did submit a fix, but deployment
and communication have been problematic. It has probably been fixed by now,
but I have decided to rework the original package, extend the interface,
and have kept this namespace active. Nevertheless, the lion's share of the
credit should go to the author of the original work.

The original C<Crypt::Fernet> package exported four functions as its primary
public interface, and this package does the same on request:

=over

=item * C<fernet_decrypt>

=item * C<fernet_genkey>

=item * C<fernet_encrypt>

=item * C<fernet_verify>

=back

=head3 C<fernet_genkey>

    $key = fernet_genkey();

Returns a Base64-encoded randomly-generated key.

=cut

sub fernet_genkey {
    goto &generatekey;
}


=head3 C<fernet_encrypt>

    $token = fernet_encrypt($key, $message);

Encrypts a message, returning a Base64-encode token.

=cut

sub fernet_encrypt {
    goto &encrypt;
}


=head3 C<fernet_decrypt>

    $message = fernet_decrypt($key, $token);
    $message = fernet_decrypt($key, $token, $ttl);

Returns the decrypted message, or C<undef> if the token could not be
decrypted. If a time-to-live (seconds) is specified (C<$ttl>) then a
further check is made to ensure that the token has not expired.

=cut

sub fernet_decrypt {
    goto &decrypt;
}


=head3 C<fernet_verify>

    $bool = fernet_verify($key, $token);
    $bool = fernet_verify($key, $token, $ttl);

Returns true if the token was signed using the same signing key as that
embedded in the Fernet key. If a time-to-live (seconds) is specified (C<$ttl>)
then a further check is made to ensure that the token has not expired.

=cut

sub fernet_verify {
    goto &verify;
}

=head1 AUTHORS

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

This is a rewrite of C<Crypt::Fernet>, so credit for that original work belongs
to Wan Leung Wong E<lt>wanleung@linkomnia.comE<gt>.

=head1 COPYRIGHT AND LICENSE

The DBIx::Squirrel module is Copyright (c) 2020-2025 Iain Campbell.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl 5.10.0 README file.

=head1 SUPPORT / WARRANTY

DBIx::Squirrel is free Open Source software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=cut

1;
