package Crypt::PK::ECC::Schnorr;
use strict;
use warnings;

our $VERSION = '0.01';

use parent 'Crypt::PK::ECC';
use Math::GMPz qw(:mpz);
use Digest::SHA qw(sha256);

use constant BIP0340_aux              => "BIP0340/aux";
use constant BIP0340_aux_SHA256       => sha256(BIP0340_aux);
use constant BIP0340_nonce            => "BIP0340/nonce";
use constant BIP0340_nonce_SHA256     => sha256(BIP0340_nonce);
use constant BIP0340_challenge        => "BIP0340/challenge";
use constant BIP0340_challenge_SHA256 => sha256(BIP0340_challenge);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return bless $self, $class;
}

sub _bytes {
    my $bin = Rmpz_export(1, 1, 0, 0, ref($_[0]) eq 'ARRAY' ? $_[0]->[0] : $_[0]);
    $bin = ("\x00" x (32 - length($bin))) . $bin if length($bin) < 32;
    return $bin;
}

sub _int {
    my $bn = Rmpz_init2(256);
    Rmpz_import($bn, 32, 1, 1, 0, 0, $_[0]);
    return $bn;
}

sub _tagged_hash {
    my ($str, $tag) = @_;
    return sha256($tag . $tag . $str);
}

my $curve_p;
my $curve_a;

sub point_double {
    my ($P) = @_;
    return $P if $P->[1] == 0;
    my $mp = Rmpz_init2(256);
    Rmpz_invert($mp, 2*$P->[1], $curve_p);
    my $s = ((3*$P->[0]*$P->[0]+$curve_a)*$mp) % $curve_p;
    my $Rx = ( $s*$s - 2*$P->[0] ) % $curve_p;
    return [ $Rx, ( $s*($P->[0] - $Rx) - $P->[1] ) % $curve_p ];
}

sub point_add {
    my ($P, $Q) = @_;
    if ($P->[1] == 0) {
        return $Q;
    }
    elsif ($Q->[1] == 0) {
        return $P;
    }
    elsif ($P->[0] == $Q->[0]) {
        if ($P->[1] == $Q->[1]) {
            return point_double($P);
        }
        else {
           # zero point has X coord as Rmpz_powm($mp, $curve_b, ($curve_p+1)/4, $curve_p) for secp256k1
           # but it does not matter, we do not use it, zero Y is enough
           return [ undef, 0 ];
        }
    }
    else {
        my $mp = Rmpz_init2(256);
        Rmpz_invert($mp, $P->[0] - $Q->[0], $curve_p);
        my $s = (($P->[1] - $Q->[1]) * $mp) % $curve_p;
        my $Rx = ( $s*$s - $P->[0] - $Q->[0] ) % $curve_p;
        return [ $Rx, ( $s*($P->[0] - $Rx) - $P->[1] ) % $curve_p ];
    }
}

sub point_mult {
    my ($P, $n) = @_;
    my $R = [ undef, 0 ];
    while ($n) {
        if (Rmpz_odd_p($n)) {
            $R = point_add($R, $P);
        }
        $P = point_double($P);
        $n >>= 1;
    }
    return $R;
}

sub mp_random {
    my ($limit) = @_;
    # TODO: change to more efficient
    my $pk = Crypt::PK::ECC->new();
    $pk->generate_key('secp160r1');
    # we don't need uniformly distributed random number here, it's enough to have cryptographically unpredictable number
    return _int($pk->export_key_raw('private')) % $limit;
}

sub sign_message {
    my $self = shift;
    my ($message, $aux) = @_; # $aux is optional
    my $curve_params = $self->curve2hash();
    my $n = Math::GMPz->new($curve_params->{order}, 16);
    $curve_p = Math::GMPz->new($curve_params->{prime}, 16);
    $curve_a = hex($curve_params->{A});
    my $dp = _int($self->export_key_raw('private'));
    return undef if $dp == 0 || $dp >= $n;
    my $G = [ Math::GMPz->new($curve_params->{Gx}, 16), Math::GMPz->new($curve_params->{Gy}, 16) ];
    my $P = point_mult($G, $dp);
    my $bytes_P = _bytes($P);
    my $d = Rmpz_even_p($P->[1]) ? $dp : $n-$dp;
    my $kp;
    if ($aux) {
        length($aux) == 32
            or return undef;
        my $t = $d ^ _int(_tagged_hash($aux, BIP0340_aux_SHA256));
        my $rand = _tagged_hash(_bytes($t) . $bytes_P . $message, BIP0340_nonce_SHA256);
        $kp = _int($rand) % $n;
    }
    else {
        $kp = mp_random($n);
    }
    return undef if $kp == 0;
    my $R = point_mult($G, $kp);
    my $k = Rmpz_even_p($R->[1]) ? $kp : $n-$kp;
    my $bytes_R = _bytes($R);
    my $e = _int(_tagged_hash($bytes_R . $bytes_P . $message, BIP0340_challenge_SHA256)) % $n;
    my $sig = $bytes_R . _bytes(($k+$e*$d) % $n);
    $self->verify_message($message, $sig)
        or die "sign fail\n";
    return $sig;
}

sub verify_message {
    my $self = shift;
    my ($message, $sig) = @_;
    my $raw_P = substr($self->export_key_raw('public'), 1, 64);
    my $bytes_P = substr($raw_P, 0, 32);
    my $curve_params = $self->curve2hash();
    my $n = Math::GMPz->new($curve_params->{order}, 16);
    $curve_p = Math::GMPz->new($curve_params->{prime}, 16);
    $curve_a = hex($curve_params->{A});
    my $bytes_r = substr($sig, 0, 32);
    my $r = _int($bytes_r);
    return undef if $r >= $curve_p;
    my $s = _int(substr($sig, 32, 32));
    return undef if $s >= $n;
    my $G = [ Math::GMPz->new($curve_params->{Gx}, 16), Math::GMPz->new($curve_params->{Gy}, 16) ];
    my $e = _int(_tagged_hash($bytes_r . $bytes_P . $message, BIP0340_challenge_SHA256)) % $n;
    my $P = [ _int($bytes_P), _int(substr($raw_P, 32, 32)) ];
    $P->[1] = $curve_p - $P->[1] if Rmpz_even_p($P->[1]);
    my $R = point_add(point_mult($G, $s), point_mult($P, $e)); # G*s - P*e
    Rmpz_even_p($R->[1]) or return undef;
    return $R->[0] == $r;
}

1;
__END__

=head1 NAME

Crypt::PK::ECC::Schnorr - Public key cryptography based on EC with Schnorr signatures

=head1 SYNOPSIS

  use Crypt::PK::ECC::Schnorr;

  # Signature: Alice
  my $priv = Crypt::PK::ECC::Schnorr->new('Alice_priv_ecc1.der');
  my $sig = $priv->sign_message($message);
  #
  # Signature: Bob (received $message + $sig)
  my $pub = Crypt::PK::ECC::Schnorr->new('Alice_pub_ecc1.der');
  $pub->verify_message($sig, $message) or die "ERROR";

=head1 DESCRIPTION

  This module inherits Crypt::PK::ECC and provides methods to create and verify Schnorr signatures for elliptic curves.
  Compatible with Bitcoin "taproot" softfork (BIP-340).

=cut
