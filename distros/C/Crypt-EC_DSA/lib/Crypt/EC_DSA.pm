# -*-cperl-*-
#
# Crypt::EC_DSA - Elliptic Curve Digital Signature Algorithm (ECDSA)
# Copyright (c) 2017 Ashish Gulhati <crypt-ecdsa at hash.neo.tc>
#
# $Id: lib/Crypt/EC_DSA.pm v1.008 Thu Jun  8 22:19:29 PDT 2017 $

package Crypt::EC_DSA;

use warnings;
use strict;
use Bytes::Random::Secure;
use Math::EllipticCurve::Prime;
use Digest::SHA qw(sha256_hex);
use vars qw( $VERSION $AUTOLOAD );

our ( $VERSION ) = '$Revision: 1.008 $' =~ /\s+([\d\.]+)/;

sub new {
  my ($class, %arg) = @_;
  bless { debug => $arg{Debug} || 0,
	  curve => Math::EllipticCurve::Prime->from_name($arg{Curve} || 'secp256k1')
	}, $class;
}

sub keygen {
  my $self = shift;
  my $n = $self->curve->n; my $nlen = length($n->as_bin)-2; my $d = 0;
  my $random = Bytes::Random::Secure->new( Bits => 128 );
  $d = Math::BigInt->from_bin($random->string_from('01',$nlen)) until ($d > 1 and $d < $n);
  my $Q = $self->curve->g->multiply($d);
  $self->_diag("keygen(): d: $d, Q: x:" . $Q->x . ', y:' . $Q->y . "\n");
  return ($Q, $d);
}

sub sign {
  my ($self, %arg) = @_;
  my $n = $self->curve->n; my $nlen = length($n->as_bin);
  my $random = Bytes::Random::Secure->new( Bits => 128 );
  my ($k, $r, $s) = (0);
  until ($s) {
    until ($r) {
      $k = Math::BigInt->from_bin($random->string_from('01',$nlen-2)) until $k > 1 and $k < $n;
      $r = $self->curve->g->multiply($k)->x->bmod($n);
    }
    my $z = Math::BigInt->new(substr(Math::BigInt->from_hex(sha256_hex($arg{Message}))->as_bin,0,$nlen));
    $s = (($z + $arg{Key} * $r) * $k->bmodinv($n))->bmod($n);
  }
  $self->_diag("sign(): r: $r, s: $s\n");
  return ( bless { s => $s,
		   r => $r
		 }, 'Crypt::EC_DSA::Signature' );
}

sub verify {
  my ($self, %arg) = @_;
  my $n = $self->curve->n;
  my ($r, $s) = ($arg{Signature}->r, $arg{Signature}->s);
  $self->_diag("s: $s\nr: $r\n");
  return unless $r > 0 and $r < $n and $s > 0 and $s < $n;
  my $z = Math::BigInt->new(substr(Math::BigInt->from_hex(sha256_hex($arg{Message}))->as_bin,0,length($n->as_bin)));
  my $w = $s->copy->bmodinv($n);
  my $u1 = ($w * $z)->bmod($n); my $u2 = ($w * $r)->bmod($n);
  my $x1 = $self->curve->g->multiply($u1)->add($arg{Key}->multiply($u2))->x->bmod($n);
  $self->_diag("verify(): x1: $x1\nr: $r\n");
  $x1 == $r;
}

sub AUTOLOAD {
  my $self = shift; (my $auto = $AUTOLOAD) =~ s/.*:://;
  return if $auto eq 'DESTROY';
  if ($auto =~ /^(curve|debug)$/x) {
    $self->{$auto} = shift if (defined $_[0]);
    return $self->{$auto};
  }
  else {
    die "Could not AUTOLOAD method $auto.";
  }
}

sub _diag {
  my $self = shift;
  print STDERR @_ if $self->debug;
}

1; # End of Crypt::EC_DSA

package Crypt::EC_DSA::Signature;

sub r { shift->{r}; }

sub s { shift->{s}; }

1; # End of Crypt::EC_DSA::Signature;

__END__

=head1 NAME

Crypt::EC_DSA - Elliptic Curve Digital Signature Algorithm (ECDSA)

=head1 VERSION

 $Revision: 1.008 $
 $Date: Thu Jun  8 22:19:29 PDT 2017 $

=head1 SYNOPSIS

Elliptic Curve Digital Signature Algorithm (ECDSA)

    use Crypt::EC_DSA;

    my $ecdsa = new Crypt::EC_DSA;

    my ($pubkey, $seckey) = $ecdsa->keygen;

    my $msg = 'Hello, world!';

    my $signature = $ecdsa->sign( Message => $msg, Key => $seckey );

    print "Verified\n" if $ecdsa->verify( Message => $msg, Key => $pubkey,
                                          Signature => $signature );

=head1 METHODS

=head2 new

Creates and returns a new Crypt::EC_DSA object. The following optional
named parameters can be provided:

=over

Curve - The name of the elliptic curve to use. Defaults to
'secp256k1'. To use an unnamed curve, set the curve using the B<curve>
accessor.

Debug - Set to a true value to have the module emit messages useful
for debugging.

=back

=head2 keygen

Generates and returns an ECDSA key-pair as a two-element list, with
the public key as the first element and the secret key as the second.

=head2 sign

Generates and returns an ECDSA signature. The following named
parameters are required:

=over

Key - The private key of the signer

Message - The message to be signed

=back

=head2 verify

Verify a signature. Returns a true value if the verification succeeds
and false otherwise. The following named parameters are required:

=over

Key - The public key of the signer

Signature - The signature

Message - The message that was signed

=back

=head1 ACCESSORS

Accessors can be called with no arguments to query the value of an
object property, or with a single argument, to set the property to a
specific value (unless it is read-only).

=head2 debug

Set true to emit helpful messages for debugging purposes, false
otherwise. Default is false.

=head2 curve

The elliptic curve to use (a B<Math::EllipticCurve::Prime> object).

=head1 SEE ALSO

=over 4

=item * L<Crypt::Ed25519>

A digital signature scheme with deterministic signatures.

=back

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-ecdsa at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-ecdsa at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-EC_DSA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::EC_DSA

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-EC_DSA>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-EC_DSA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-EC_DSA>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-EC_DSA/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017 Ashish Gulhati.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

See L<http://www.perlfoundation.org/artistic_license_2_0> for the full
license terms.
