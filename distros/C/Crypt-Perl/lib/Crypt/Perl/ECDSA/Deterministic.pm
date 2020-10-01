package Crypt::Perl::ECDSA::Deterministic;

=encoding utf-8

=head1 NAME

Crypt::Perl::ECDSA::Deterministic

=head1 DISCUSSION

This module implements L<RFC 6979|https://tools.ietf.org/html/rfc6979>’s
algorithm for deterministic ECDSA signatures.

=cut

use strict;
use warnings;

use Digest::SHA ();

use Crypt::Perl::BigInt ();
use Crypt::Perl::Math ();

our $q;
our $qlen;
our $qlen_bytelen;

sub generate_k {

    # $h1 = the message’s hash, as per $hashfunc
    my ($order, $key, $h1, $hashfn) = @_;

    my $hmac_cr = Digest::SHA->can("hmac_$hashfn") or do {
        die "Unknown deterministic ECDSA hashing algorithm: $hashfn";
    };

    local $q = $order;
    local $qlen = length $order->to_bin();
    local $qlen_bytelen = Crypt::Perl::Math::ceil( $qlen / 8 );

    my $privkey_bytes = $key->as_bytes();
    substr( $privkey_bytes, 0, 0, "\0" x ($qlen_bytelen - length $privkey_bytes) );

    # printf "h1: %v.02x\n", $h1;
    # printf "x: %v.02x\n", $privkey_bytes;

    # printf "bits2octets(h1): %v.02x\n", bits2octets($h1);

    my $hashlen = length $h1;

    my $V = "\x01" x $hashlen;

    my $K = "\x00" x $hashlen;

    $K = $hmac_cr->(
        $V . "\0" . $privkey_bytes . bits2octets($h1),
        $K,
    );
    # printf "K after step d: %v.02x\n", $K;

    $V = $hmac_cr->( $V, $K );
    # printf "V after step E: %v.02x\n", $V;

    $K = $hmac_cr->(
        $V . "\1" . $privkey_bytes . bits2octets($h1),
        $K,
    );
    # printf "K after step F: %v.02x\n", $K;

    $V = $hmac_cr->( $V, $K );
    # printf "V after step G: %v.02x\n", $V;

    my $k;

    while (1) {
        my $T = q<>;

        while (1) {
            $V = $hmac_cr->( $V, $K );
            $T .= $V;

            last if length(_bytes_to_bitstxt($T)) >= $qlen;
        }
        # printf "new T: %v.02x\n", $T;
        # print Crypt::Perl::BigInt->from_bytes($T)->to_bin() . $/;

        $k = bits2int($T, $qlen);

        if ($k->bge(1) && $k->blt($order)) {
            # print "got good k\n";
            # TODO: determine $r’s suitability
            last;
        }

        # printf "bad k: %v.02x\n", $k->to_bytes();

        $K = $hmac_cr->( $V . "\0", $K );
        # printf "new K: %v.02x\n", $K;
        $V = $hmac_cr->( $V, $K );
        # printf "new V: %v.02x\n", $V;
    }

    return $k;
}

sub _bytes_to_bitstxt {
    unpack 'B*', $_[0];
}

sub bits2int {
    my ($bits, $qlen) = @_;

    my $blen = 8 * length $bits;
    $bits = _bytes_to_bitstxt($bits);

    if ($qlen < $blen) {
        substr($bits, -($blen - $qlen)) = q<>;
    }

    return Crypt::Perl::BigInt->from_bin($bits);
}

sub int2octets {
    my $octets = shift()->as_bytes();

    if (length($octets) > $qlen_bytelen) {
        substr( $octets, 0, -$qlen_bytelen ) = q<>;
    }
    elsif (length($octets) < $qlen_bytelen) {
        substr( $octets, 0, 0, "\0" x ($qlen_bytelen - length $octets) );
    }

    return $octets;
}

sub bits2octets {
    my ($bits) = @_;
    my $z1 = bits2int($bits, $qlen);

    my $z2 = $z1->copy()->bmod($q);

    return int2octets($z2, $qlen);
}

1;
