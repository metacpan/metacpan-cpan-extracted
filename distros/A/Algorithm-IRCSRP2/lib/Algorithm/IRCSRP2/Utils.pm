package Algorithm::IRCSRP2::Utils;

BEGIN {
    $Algorithm::IRCSRP2::Utils::VERSION = '0.501';
}

# ABSTRACT: Algorithm utility functions

use strict;
use warnings;

# core
use Digest::SHA;
use Math::BigInt only => 'GMP,Pari';

# CPAN
use Crypt::URandom qw();
use Sub::Exporter;

Sub::Exporter::setup_exporter(
    {'exports' => [qw(urandom randint gen_a int2bytes bytes2int xorstring padto hmac_sha256_128 N g H)]});

# -------- constants --------
sub H { return Digest::SHA::sha256(@_) }

sub g { return 2 }

sub N {
    my @modp14 = qw(
      FFFFFFFF FFFFFFFF C90FDAA2 2168C234 C4C6628B 80DC1CD1
      29024E08 8A67CC74 020BBEA6 3B139B22 514A0879 8E3404DD
      EF9519B3 CD3A431B 302B0A6D F25F1437 4FE1356D 6D51C245
      E485B576 625E7EC6 F44C42E9 A637ED6B 0BFF5CB6 F406B7ED
      EE386BFB 5A899FA5 AE9F2411 7C4B1FE6 49286651 ECE45B3D
      C2007CB8 A163BF05 98DA4836 1C55D39A 69163FA8 FD24CF5F
      83655D23 DCA3AD96 1C62F356 208552BB 9ED52907 7096966D
      670C354E 4ABC9804 F1746C08 CA18217C 32905E46 2E36CE3B
      E39E772C 180E8603 9B2783A2 EC07A28F B5C55DF0 6F4C52C9
      DE2BCBF6 95581718 3995497C EA956AE5 15D22618 98FA0510
      15728E5A 8AACAA68 FFFFFFFF FFFFFFFF);

    my $s = join('', @modp14);

    $s =~ s/\s*//g;
    $s =~ s/\n//g;

    return Math::BigInt->new('0x' . $s)->bstr;
}

sub urandom {
    my ($amount) = @_;

    return Crypt::URandom::urandom($amount);
}

sub randint {
    my ($a, $b) = @_;
    my $c    = $b->copy;
    my $bits = (int($c->blog(2)) + 1) / 8;

    my $candidate = 0;

    while (1) {
        $candidate = bytes2int(urandom($bits));
        if ($a <= $candidate && $candidate <= $b) {
            last;
        }
    }
    die 'a <= candidate <= b' unless ($a <= $candidate && $candidate <= $b);

    return $candidate->bstr;
}

sub gen_a {
    my $n = Math::BigInt::->new(N());
    $n->bsub(1);
    return randint(2, $n);
}

sub int2bytes {
    my ($n) = @_;

    $n = $n->copy;

    if ($n == 0) { return 0x00 }

    my $x = '';

    while ($n) {
        $x = chr($n->copy->bmod(256)->bstr) . $x;
        $n->bdiv(256);
    }

    return $x;
}

sub bytes2int {
    my ($bytes) = @_;

    my @bs = split('', $bytes);

    my $n = Math::BigInt->new(0);

    foreach my $b (@bs) {
        $n->bmul(256);
        $n->badd(ord($b));
    }

    return $n;
}

sub xorstring {
    my ($a, $b, $blocksize) = @_;

    my $xored = '';

    my @as = split('', $a);
    my @bs = split('', $b);

    foreach my $i (@{[ 0 .. $blocksize - 1 ]}) {
        $xored .= chr(ord($as[$i]) ^ ord($bs[$i]));
    }

    return $xored;
}

sub padto {
    my ($msg, $length) = @_;

    my $L = length($msg);

    if ($L % $length) {
        $msg .= (chr(0) x ($length - $L % $length));
    }

    die('lenth($msg) % $length != 0') unless ((length($msg) % $length) == 0);

    return $msg;
}

sub hmac_sha256_128 {
    my ($key, $data) = @_;

    my $str = Digest::SHA::hmac_sha256($data, $key);
    $str = substr($str, 0, 16);

    return $str;
}

1;

__END__

=pod

=head1 NAME

Algorithm::IRCSRP2::Utils - Algorithm utility functions

=head1 VERSION

version 0.501

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
