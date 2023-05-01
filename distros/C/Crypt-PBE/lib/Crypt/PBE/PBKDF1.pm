package Crypt::PBE::PBKDF1;

use strict;
use warnings;
use utf8;

use Carp;
use MIME::Base64;
use Digest::MD2 qw(md2);
use Digest::MD5 qw(md5);
use Digest::SHA qw(sha1);
use Exporter qw(import);

our $VERSION = '0.103';

our @EXPORT = qw(
    pbkdf1
    pbkdf1_base64
    pbkdf1_hex
);

our @EXPORT_OK = qw(
    pbkdf1_md2
    pbkdf1_md2_base64
    pbkdf1_md2_hex

    pbkdf1_md5
    pbkdf1_md5_base64
    pbkdf1_md5_hex

    pbkdf1_sha1
    pbkdf1_sha1_base64
    pbkdf1_sha1_hex
);

sub new {

    my ( $class, %params ) = @_;

    my $password = delete $params{password} || croak 'Specify password';
    my $salt     = delete $params{salt}     || croak 'Specify salt';
    my $count    = delete $params{count}    || 1_000;
    my $hash     = delete $params{hash}     || 'sha1';
    my $dk_len   = 20;

    $dk_len = 16 if ( $hash eq 'md5' || $hash eq 'md2' );

    my $self = {
        password => $password,
        salt     => $salt,
        count    => $count,
        hash     => $hash,
        dk_len   => $dk_len
    };

    bless $self, $class;

    return $self;

}

sub hash_algorithm     { shift->{hash} }
sub count              { shift->{count} }
sub derived_key_length { shift->{dk_len} }

sub derived_key {
    my ($self) = @_;
    return pbkdf1(
        password => $self->{password},
        salt     => $self->{salt},
        count    => $self->{count},
        hash     => $self->{hash},
        dk_len   => $self->{dk_len}
    );
}

sub derived_key_base64 {
    my ($self) = @_;
    return pbkdf1_base64(
        password => $self->{password},
        salt     => $self->{salt},
        count    => $self->{count},
        hash     => $self->{hash},
        dk_len   => $self->{dk_len}
    );
}

sub derived_key_hex {
    my ($self) = @_;
    return pbkdf1_hex(
        password => $self->{password},
        salt     => $self->{salt},
        count    => $self->{count},
        hash     => $self->{hash},
        dk_len   => $self->{dk_len}
    );
}

# PBKDF1 (P, S, c, dkLen)
#
#   Options:        Hash       underlying hash function
#
#   Input:          P          password, an octet string
#                   S          salt, an octet string
#                   c          iteration count, a positive integer
#                   dkLen      intended length in octets of derived key,
#                              a positive integer, at most 16 for MD2 or
#                              MD5 and 20 for SHA-1
#   Output:         DK         derived key, a dkLen-octet string

sub pbkdf1 {

    my (%params) = @_;

    my $hash  = delete( $params{hash} )     || 'sha1';
    my $P     = delete( $params{password} ) || croak('Specify password');
    my $S     = delete( $params{salt} )     || croak('Specify salt');
    my $c     = delete( $params{count} )    || 1_000;
    my $dkLen = delete( $params{dk_len} );

    if ( $hash ne 'md2' && $hash ne 'md5' && $hash ne 'sha1' ) {
        croak 'unknown hash function';
    }

    if ( !$dkLen ) {
        $dkLen = 16 if ( $hash =~ /md(2|5)/ );
        $dkLen = 20 if ( $hash eq 'sha1' );
    }

    if ( ( $hash eq 'md5' && $dkLen > 16 ) || ( $hash eq 'md2' && $dkLen > 16 ) || ( $hash eq 'sha1' && $dkLen > 20 ) )
    {
        croak 'derived key too long';
    }

    my $T = $P . $S;

    no strict 'refs';    ## no critic

    for ( 1 .. $c ) {
        $T = &{$hash}($T);
    }

    my $DK = substr( $T, 0, $dkLen );

    return $DK;

}

sub pbkdf1_hex {
    return join '', unpack '(H2)*', pbkdf1(@_);
}

sub pbkdf1_base64 {
    return encode_base64 pbkdf1(@_), '';
}

for my $digest (qw/md2 md5 sha1/) {

    my $dk_len = 16;
    $dk_len = 20 if ( $digest eq 'sha1' );

    my $sub_name = 'pbkdf1_' . $digest;

    no strict 'refs';    ## no critic

    *{$sub_name} = sub {
        my (%params) = @_;
        $params{hash}   = $digest;
        $params{dk_len} = $dk_len;
        return pbkdf1(%params);
    };

    *{ $sub_name . '_base64' } = sub {
        my (%params) = @_;
        $params{hash}   = $digest;
        $params{dk_len} = $dk_len;
        return encode_base64 pbkdf1(%params), '';
    };

    *{ $sub_name . '_hex' } = sub {
        my (%params) = @_;
        $params{hash}   = $digest;
        $params{dk_len} = $dk_len;
        return join '', unpack 'H*', pbkdf1(%params);
    };

}

1;
__END__
=head1 NAME

Crypt::PBE::PBKDF1 - Perl extension for PKCS #5 Password-Based Key Derivation Function 1 (PBKDF1)

=head1 SYNOPSIS

    use Crypt::PBE::PBKDF1;

    # OO style

    my $pbkdf1 = Crypt::PBE::PBKDF1->new(
        password   => $password,
        salt       => $salt,
        hash       => 'sha1'
    );

    $pbkdf1->derived_key;           # Byte
    $pbkdf1->derived_key_base64     # Base64 encoded
    $pbkdf1->derived_key_hex        # Hex


    use Crypt::PBE::PBKDF1 qw(pbkdf1_md2 pbkdf1_md5_base64 pbkdf1_sha1_hex);

    # Functional style

    $derived_key = pbkdf1 ( %params );           # Byte
    $derived_key = pbkdf1_base64 ( %params );    # Base64 encoded
    $derived_key = pbkdf1_hex ( %params );       # Hex

    # Functional style helpers
    $derived_key = pbkdf1_md2 ( %params );
    $derived_key = pbkdf1_md2_hex ( %params );
    $derived_key = pbkdf1_md2_base64 ( %params );

    $derived_key = pbkdf1_md5 ( %params );
    $derived_key = pbkdf1_md5_hex ( %params );
    $derived_key = pbkdf1_md5_base64 ( %params );

    $derived_key = pbkdf1_sha1 ( %params );
    $derived_key = pbkdf1_sha1_hex ( %params );
    $derived_key = pbkdf1_sha1_base64 ( %params );


=head1 DESCRIPTION

PBKDF2 applies a pseudorandom function, such as hash-based message authentication
code (HMAC), to the input password or passphrase along with a salt value and
repeats the process many times to produce a derived key, which can then be used
as a cryptographic key in subsequent operations.


=head1 CONSTRUCTOR

=head2 Crypt::PBE::PBKDF1->new ( %params )

Params:

=over 4

=item * C<password> : The password to use for the derivation

=item * C<salt> : The salt to use for the derivation. This value should be generated randomly.

=item * C<hash> : Hash algorithm (default "sha1")

=item * C<count> : The number of internal iteractions to perform for the derivation key (default "1_000")

=back


=head1 METHODS

=head2 $pbkdf1->derived_key

Return the derived key in raw output (byte).

=head2 $pbkdf1->derived_key_base64

Return the derived key in Base64 encoded format.

=head2 $pbkdf1->derived_key_hex

Return the derived key in HEX format.

=head2 $pbkdf2->hash

Return the hash name.

=head2 $pbkdf2->count

Return the iteration count number.

=head2 $pbkdf2->derived_key_length

Return the derived key length.


=head1 FUNCTIONS

=head2 pbkdf1 ( hash => ..., password => ..., salt => ..., [ count => 1_000, dk_len => 0 ] )

Return derived key using PBKDF1 function:

    my $derived_key = pbkdf1 (
        hash     => 'sha1',
        password => 'mypassword',
        salt     => my_random_byte_sub(), 
        count    => 2_000
    );

    print length($derived_key)      # 20


=head2 pbkdf1_base64 ( hash => ..., password => ..., salt => ..., [ count => 1_000, dk_len => 0 ] )

Return derived key in Base64 using PBKDF1 function.

=head2 pbkdf1_hex ( hash => ..., password => ..., salt => ..., [ count => 1_000, dk_len => 0 ] )

Return derived key in HEX using PBKDF1 function.


=head2 EXPORTABLE HELPER FUNCTIONS

Return the derived key using MD2, MD5 and SHA1 digest:

=over 4

=item pbkdf1_md2

=item pbkdf1_md5

=item pbkdf1_sha1

=back

Return the derived key using MD2, MD5 and SHA1 digest in Base64:

=over 4

=item pbkdf1_md2_base64

=item pbkdf1_md5_base64

=item pbkdf1_sha1_base64

=back

Return the derived key using MD2, MD5 and SHA1 digest in HEX:

=over 4

=item pbkdf1_md2_hex

=item pbkdf1_md5_hex

=item pbkdf1_sha1_hex

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

=item L<Crypt::PBE::PBKDF2>

=item [RFC2898] PKCS #5: Password-Based Cryptography Specification Version 2.0 (L<https://tools.ietf.org/html/rfc2898>)

=item [RFC8018] PKCS #5: Password-Based Cryptography Specification Version 2.1 (L<https://tools.ietf.org/html/rfc8018>)

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020-2023 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
