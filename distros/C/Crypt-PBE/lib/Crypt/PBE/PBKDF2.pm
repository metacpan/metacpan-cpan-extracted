package Crypt::PBE::PBKDF2;

use strict;
use warnings;
use utf8;

use Carp;
use POSIX;
use MIME::Base64;
use Digest::SHA qw(hmac_sha1 hmac_sha224 hmac_sha256 hmac_sha384 hmac_sha512);
use Exporter qw(import);

our $VERSION = '0.102';

our @EXPORT = qw(
    pbkdf2
    pbkdf2_base64
    pbkdf2_hex
    pbkdf2_ldap
);

our @EXPORT_OK = qw(
    pbkdf2_hmac_sha1
    pbkdf2_hmac_sha1_base64
    pbkdf2_hmac_sha1_hex
    pbkdf2_hmac_sha1_ldap

    pbkdf2_hmac_sha224
    pbkdf2_hmac_sha224_base64
    pbkdf2_hmac_sha224_hex

    pbkdf2_hmac_sha256
    pbkdf2_hmac_sha256_base64
    pbkdf2_hmac_sha256_hex
    pbkdf2_hmac_sha256_ldap

    pbkdf2_hmac_sha384
    pbkdf2_hmac_sha384_base64
    pbkdf2_hmac_sha384_hex

    pbkdf2_hmac_sha512
    pbkdf2_hmac_sha512_base64
    pbkdf2_hmac_sha512_hex
    pbkdf2_hmac_sha512_ldap

    PBKDF2WithHmacSHA1
    PBKDF2WithHmacSHA224
    PBKDF2WithHmacSHA256
    PBKDF2WithHmacSHA384
    PBKDF2WithHmacSHA512
);

sub new {

    my ( $class, %params ) = @_;

    my $password = delete $params{password} || croak('Specify password');
    my $salt     = delete $params{salt}     || croak('Specify salt');
    my $count    = delete $params{count}    || 1_000;
    my $prf      = delete $params{prf}      || 'hmac-sha1';
    my $dk_len   = delete $params{dk_len};

    $prf =~ s/-/_/;

    my $self = {
        password => $password,
        salt     => $salt,
        count    => $count,
        prf      => $prf,
        dk_len   => $dk_len
    };

    bless $self, $class;

    return $self;

}

sub prf                { shift->{prf} }
sub count              { shift->{count} }
sub derived_key_length { shift->{dk_len} }

sub validate {
    my ( $self, $derived_key, $password ) = @_;
    my $check = pbkdf2( $self->{prf}, $password, $self->{salt}, $self->{count}, $self->{dk_len} );
    return ( $derived_key eq $check );
}

sub derived_key {
    my ($self) = @_;
    return pbkdf2(
        prf      => $self->{prf},
        password => $self->{password},
        salt     => $self->{salt},
        count    => $self->{count},
        dk_len   => $self->{dk_len}
    );
}

sub derived_key_base64 {
    my ($self) = @_;
    return pbkdf2_base64(
        prf      => $self->{prf},
        password => $self->{password},
        salt     => $self->{salt},
        count    => $self->{count},
        dk_len   => $self->{dk_len}
    );
}

sub derived_key_hex {
    my ($self) = @_;
    return pbkdf2_hex(
        prf      => $self->{prf},
        password => $self->{password},
        salt     => $self->{salt},
        count    => $self->{count},
        dk_len   => $self->{dk_len}
    );
}

# PBKDF2 (P, S, c, dkLen)
#
#    Options:        PRF        underlying pseudorandom function (hLen
#                               denotes the length in octets of the
#                               pseudorandom function output)
#
#    Input:          P          password, an octet string
#                    S          salt, an octet string
#                    c          iteration count, a positive integer
#                    dkLen      intended length in octets of the derived
#                               key, a positive integer, at most
#                               (2^32 - 1) * hLen
#
#    Output:         DK         derived key, a dkLen-octet string

sub pbkdf2 {

    my (%params) = @_;

    my $P     = delete( $params{password} ) || croak 'Specify password';
    my $S     = delete( $params{salt} )     || croak 'Specify salt';
    my $c     = delete( $params{count} )    || 1_000;
    my $dkLen = delete( $params{dk_len} )   || 0;
    my $PRF   = delete( $params{prf} )      || 'hmac-sha1';

    $PRF =~ s/-/_/;

    my $hLen = 20;
    $dkLen ||= 0;
    $c     ||= 1_000;

    my %hmac_length = (
        'hmac_sha1'   => ( 160 / 8 ),
        'hmac_sha224' => ( 224 / 8 ),
        'hmac_sha256' => ( 256 / 8 ),
        'hmac_sha384' => ( 384 / 8 ),
        'hmac_sha512' => ( 512 / 8 ),
    );

    if ( !defined( $hmac_length{$PRF} ) ) {
        croak 'unknown PRF';
    }

    $hLen = $hmac_length{$PRF};

    if ( $dkLen > ( 2**32 - 1 ) * $hLen ) {
        croak 'derived key too long';
    }

    my $l = ( $dkLen > 0 ) ? POSIX::ceil( $dkLen / $hLen ) : 1;

    my $r = $dkLen - ( $l - 1 ) * $hLen;
    my $T = undef;

    for ( my $i = 1; $i <= $l; $i++ ) {
        $T .= _pbkdf2_F( $PRF, $P, $S, $c, $i );
    }

    my $DK = $T;

    if ( $dkLen > 0 ) {
        return substr( $DK, 0, $dkLen );
    }

    return $DK;

}

sub _pbkdf2_F {

    my ( $PRF, $P, $S, $c, $i ) = @_;

    no strict 'refs';    ## no critic

    my $U = &{$PRF}( $S . pack( 'N', $i ), $P );

    my $U_x = $U;

    for ( my $x = 1; $x < $c; $x++ ) {
        $U_x = &{$PRF}( $U_x, $P );
        $U ^= $U_x;
    }

    return $U;

}

# PBKDF2 aliases

for my $variant (qw(1 224 256 384 512)) {

    no strict 'refs';    ## no critic

    my $prf = "hmac_sha${variant}";

    *{"PBKDF2WithHmacSHA${variant}"} = sub {
        my (%params) = @_;
        $params{prf} = $prf;
        return pbkdf2(%params);
    };

    *{"pbkdf2_hmac_sha${variant}"} = sub {
        my (%params) = @_;
        $params{prf} = $prf;
        return pbkdf2(%params);
    };

    *{"pbkdf2_hmac_sha${variant}_base64"} = sub {
        my (%params) = @_;
        $params{prf} = $prf;
        return encode_base64 pbkdf2(%params), '';
    };

    *{"pbkdf2_hmac_sha${variant}_hex"} = sub {
        my (%params) = @_;
        $params{prf} = $prf;
        return join '', unpack '(H2)*', pbkdf2(%params);
    };

    if ( $variant != 224 && $variant != 384 ) {
        *{"pbkdf2_hmac_sha${variant}_ldap"} = sub {
            my (%params) = @_;
            $params{prf} = $prf;
            return pbkdf2_ldap(%params);
        };
    }

}

sub pbkdf2_hex {
    return join '', unpack '(H2)*', pbkdf2(@_);
}

sub pbkdf2_base64 {
    return encode_base64 pbkdf2(@_), '';
}

sub pbkdf2_ldap {

    my (%params) = @_;

    $params{prf} =~ s/-/_/;

    if ( $params{prf} eq 'hmac-sha224' || $params{prf} eq 'hmac-sha384' ) {
        croak "$params{prf} not supported LDAP scheme";
    }

    my $derived_key = pbkdf2(%params);
    my $count       = $params{count} || 1_000;

    my $scheme          = 'PBKDF2';
    my $b64_salt        = b64_to_ab64( encode_base64( $params{salt}, '' ) );
    my $b64_derived_key = b64_to_ab64( encode_base64( $derived_key, '' ) );

    $scheme = 'PBKDF2-SHA256' if ( $params{prf} eq 'hmac-sha256' );
    $scheme = 'PBKDF2-SHA512' if ( $params{prf} eq 'hmac-sha512' );

    return "{$scheme}$count\$$b64_salt\$$b64_derived_key";

}

sub b64_to_ab64 {

    my ($string) = @_;

    $string =~ s/\+/./g;
    $string =~ s/=//g;
    $string =~ s/\s//g;

    return $string;

}

1;
__END__
=head1 NAME

Crypt::PBE::PBKDF2 - Perl extension for PKCS #5 Password-Based Key Derivation Function 2 (PBKDF2)

=head1 SYNOPSIS

    use Crypt::PBE::PBKDF2;

    # OO style

    my $pbkdf2 = Crypt::PBE::PBKDF2->new(
        password   => $password,
        salt       => $salt,
        prf        => 'hmac-sha256'
    );

    $pbkdf2->derived_key;           # Byte
    $pbkdf2->derived_key_base64     # Base64 encoded
    $pbkdf2->derived_key_hex        # Hex


    use Crypt::PBE::PBKDF2 qw(pbkdf2_hmac_sha1 pbkdf2_hmac_sha1_hex pbkdf2_base64 ...);

    # Functional style

    $derived_key = pbkdf2 ( %params );           # Byte
    $derived_key = pbkdf2_base64 ( %params );    # Base64 encoded
    $derived_key = pbkdf2_hex ( %params );       # Hex

    # Functional style helpers
    $derived_key = pbkdf2_hmac_sha1 ( %params );
    $derived_key = pbkdf2_hmac_sha1_hex ( %params );
    $derived_key = pbkdf2_hmac_sha1_base64 ( %params );

    $derived_key = pbkdf2_hmac_sha224_hex ( %params );
    $derived_key = pbkdf2_hmac_sha256_base64 ( %params );
    $derived_key = pbkdf2_hmac_sha384_hex ( %params );
    $derived_key = pbkdf2_hmac_sha512_base64 ( %params );

=head1 DESCRIPTION

PBKDF2 applies a pseudorandom function, such as hash-based message authentication
code (HMAC), to the input password or passphrase along with a salt value and
repeats the process many times to produce a derived key, which can then be used
as a cryptographic key in subsequent operations.


=head1 CONSTRUCTOR

=head2 Crypt::PBE::PBKDF2->new ( %params )

Params:

=over 4

=item * C<password> : The password to use for the derivation

=item * C<salt> : The salt to use for the derivation. This value should be generated randomly.

=item * C<prf> : HMAC PRF (pseudo-random function) name (default "hmac-sha1")

=item * C<count> : The number of internal iteractions to perform for the derivation key (default "1_000")

=item * C<dk_len> : The length of derived key (default "0" -- PRF default length)

=back


=head1 METHODS

=head2 $pbkdf2->derived_key

Return the derived key in raw output (byte).

=head2 $pbkdf2->derived_key_base64

Return the derived key in Base64 encoded format.

=head2 $pbkdf2->derived_key_hex

Return the derived key in HEX format.

=head2 $pbkdf2->validate ( $derived_key, $password )

Return the validation test for provided password and derived key.

    if ($pbkdf2->validate( $my_derived_key, $params->{password} )) {
        say "Valid password";
    } else {
        say "Invalid password";
    }

=head2 $pbkdf2->prf

Return the PRF (Pseudo-Random function) name.

=head2 $pbkdf2->count

Return the iteration count number.

=head2 $pbkdf2->derived_key_length

Return the derived key length.


=head1 FUNCTIONS

=head2 pbkdf2 ( prf => ..., password => ..., salt => ..., [ count => 1_000, dk_len => 0 ] )

Return derived key using PBKDF2 function:

    my $derived_key = pbkdf2 (
        prf      => 'hmac-sha1',
        password => 'mypassword',
        salt     => my_random_byte_sub(), 
        count    => 2_000
    );

    print length($derived_key)      # 20


=head2 pbkdf2_base64 ( prf => ..., password => ..., salt => ..., [ count => 1_000, dk_len => 0 ] )

Return derived key in Base64 using PBKDF2 function.

=head2 pbkdf2_hex ( prf => ..., password => ..., salt => ..., [ count => 1_000, dk_len => 0 ] )

Return derived key in HEX using PBKDF2 function.

=head2 pbkdf2_ldap ( prf => ..., password => ..., salt => ..., [ count => 1_000 ] )

Return derived key in LDAP C<{PBKDF2}> schema using PBKDF2 function.


=head2 EXPORTABLE HELPER FUNCTIONS

Return the derived key using SHA1/224/256/384/512 HMAC digest (Java-style):

=over 4

=item PBKDF2WithHmacSHA1

=item PBKDF2WithHmacSHA224

=item PBKDF2WithHmacSHA256

=item PBKDF2WithHmacSHA384

=item PBKDF2WithHmacSHA512

=back

Return the derived key using SHA1/224/256/384/512 HMAC digest:

=over 4

=item pbkdf2_hmac_sha1

=item pbkdf2_hmac_sha224

=item pbkdf2_hmac_sha256

=item pbkdf2_hmac_sha384

=item pbkdf2_hmac_sha512

=back

Return the derived key using SHA1/224/256/384/512 HMAC digest in Base64:

=over 4

=item pbkdf2_hmac_sha1_base64

=item pbkdf2_hmac_sha224_base64

=item pbkdf2_hmac_sha256_base64

=item pbkdf2_hmac_sha384_base64

=item pbkdf2_hmac_sha512_base64

=back

Return the derived key using SHA1/224/256/384/512 HMAC digest in HEX:

=over 4

=item pbkdf2_hmac_sha1_hex

=item pbkdf2_hmac_sha224_hex

=item pbkdf2_hmac_sha256_hex

=item pbkdf2_hmac_sha384_hex

=item pbkdf2_hmac_sha512_hex

=back

Return the derived key using SHA1/224/256/384/512 HMAC digest in {PBKDF2} LDAP schema:

=over 4

=item pbkdf2_hmac_sha1_ldap

=item pbkdf2_hmac_sha256_ldap

=item pbkdf2_hmac_sha512_ldap

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Crypt-PBE/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Crypt-PBE>

    git clone https://github.com/giterlizzi/perl-Crypt-PBE.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 SEE ALSO

=over 4

=item L<Crypt::PBE::PBKDF1>

=item [RFC2898] PKCS #5: Password-Based Cryptography Specification Version 2.0 (L<https://tools.ietf.org/html/rfc2898>)

=item [RFC8018] PKCS #5: Password-Based Cryptography Specification Version 2.1 (L<https://tools.ietf.org/html/rfc8018>)

=item [RFC6070] PKCS #5: Password-Based Key Derivation Function 2 (PBKDF2) - Test Vectors (L<https://tools.ietf.org/html/rfc6070>)

=item [RFC2307] An Approach for Using LDAP as a Network Information Service (L<https://tools.ietf.org/html/rfc2307>)

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020-2021 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
