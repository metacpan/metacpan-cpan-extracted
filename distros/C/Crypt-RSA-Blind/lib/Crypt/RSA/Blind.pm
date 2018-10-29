# -*-cperl-*-
#
# Crypt::RSA::Blind - Blind RSA signatures
# Copyright (c) Ashish Gulhati <crypt-rsab at hash.neo.tc>
#
# $Id: lib/Crypt/RSA/Blind.pm v1.010 Sat Oct 27 21:19:50 PDT 2018 $

package Crypt::RSA::Blind;

use warnings;
use strict;
use Crypt::FDH;
use Crypt::RSA;
use Crypt::RSA::Primitives;
use Crypt::Random qw(makerandom_itv makerandom);
use Math::Pari qw (Mod component);
use vars qw( $VERSION $AUTOLOAD );

our ( $VERSION ) = '$Revision: 1.010 $' =~ /\s+([\d\.]+)/;

sub new {
  bless { HASHSIZE  => 768,
	  INITSIZE  => 128,
	  BLINDSIZE => 512,
	  _RSA      => new Crypt::RSA,
	  _RSAP     => new Crypt::RSA::Primitives}, shift;
}

sub keygen {
  my $self = shift;
  $self->_rsa->keygen(@_);
}

sub init {
  my $self = shift;
  makerandom( Size => $self->initsize, Strength => 0 );
}

sub request {
  my $self = shift;
  my %arg = @_;
  my ($invertible, $blinding);
  while (!$invertible) {
    $blinding = makerandom_itv( Size => $self->blindsize, Upper => $arg{Key}->n-1, Strength => 0 );
    # Check that blinding is invertible mod n
    $invertible = Math::Pari::gcd($blinding, $arg{Key}->n);
    $invertible = 0 unless $invertible == 1;
  }
  $self->_request($arg{Init} => $blinding);

  my $be = $self->_rsap->core_encrypt(Key => $arg{Key}, Plaintext => $blinding);
  my $fdh = Math::Pari::_hex_cvt ('0x'.Crypt::FDH::hash(Size => $self->hashsize, Message => $arg{Message}));
  component((Mod($fdh,$arg{Key}->n)) * (Mod($be,$arg{Key}->n)), 2);
}

sub sign {
  my $self = shift;
  $self->_rsap->core_sign(@_);
}

sub unblind {
  my $self = shift;
  my %arg = @_;
  my $blinding = $self->_request($arg{Init});
  component((Mod($arg{Signature},$arg{Key}->n)) / (Mod($blinding,$arg{Key}->n)), 2);
}

sub verify {
  my $self = shift;
  my %arg = @_;
  my $pt = $self->_rsap->core_verify(Key => $arg{Key}, Signature => $arg{Signature});
  $pt == Math::Pari::_hex_cvt ('0x'.Crypt::FDH::hash(Size => $self->hashsize, Message => $arg{Message}));
}

sub errstr {
  my $self = shift;
  $self->_rsa->errstr(@_);
}

sub _request {
  my $self = shift;
  my $init = $_[0]; my $ret;
  if ($_[1]) {
    $self->{Requests}->{$init} = $_[1];
  }
  else {
    $ret = $self->{Requests}->{$init};
    delete $self->{Requests}->{$init};
  }
  return $ret;
}

sub AUTOLOAD {
  my $self = shift; (my $auto = $AUTOLOAD) =~ s/.*:://;
  return if $auto eq 'DESTROY';
  if ($auto =~ /^(_rsa|_rsap|hashsize|blindsize|initsize)$/x) {
    $self->{"\U$auto"} = shift if (defined $_[0]);
    return $self->{"\U$auto"};
  }
  else {
    die "Could not AUTOLOAD method $auto.";
  }
}

1; # End of Crypt::RSA::Blind

package Crypt::RSA::Blind::PubKey;

use Compress::Zlib;

sub from_hex {
  Crypt::RSA::Key::Public->new->deserialize(String => [ uncompress(pack('H*',shift)) ]);
}

1; # End of Crypt::RSA::Blind::PubKey

package Crypt::RSA::Blind::SecKey;

use Compress::Zlib;

sub from_hex {
  Crypt::RSA::Key::Private->new->deserialize(String => [ uncompress(pack('H*',shift)) ]);
}

1; # End of Crypt::RSA::Blind::SecKey

__END__

=head1 NAME

Crypt::RSA::Blind - Blind RSA signatures

=head1 VERSION

 $Revision: 1.010 $
 $Date: Sat Oct 27 21:19:50 PDT 2018 $

=cut

=head1 SYNOPSIS

    use Crypt::RSA::Blind;

    my $rsab = new Crypt::RSA::Blind;

    my ($pubkey, $seckey) = $rsab->keygen(Size => 1024);

    my $msg = "Hello, world!";

    my $init = $rsab->init;

    my $req = $rsab->request( Key => $pubkey, Init => $init,
                              Message => $msg );

    my $blindsig = $rsab->sign( Key => $seckey, Plaintext => $req );

    my $sig = $rsab->unblind( Key => $pubkey, Init => $init,
                              Signature => $blindsig );

    print "OK\n" if $rsab->verify( Key => $pubkey, Message => $msg,
                                   Signature => $sig );

=head1 METHODS

=head2 new

Creates and returns a new Crypt::RSA::Blind object.

=head2 keygen

Generates and returns an RSA key-pair of specified bitsize. This is a
synonym for Crypt::RSA::Key::generate(). Parameters and return values
are described in the Crypt::RSA::Key(3) manpage.

=head2 init

Generates and returns an initialization vector for the blind
signing. The initialization vector should be passed in to the req(),
and unblind() methods in the Init named parameter.

The RSA blind signature protocol doesn't actually require the use of
initialization vectors, and this module can be used just fine with the
Init parameter set to 1 or any number. However, this module uses the
initialization vector to keep track of the blinding factor for
different requests, so it is necessary to use initialization vectors
when creating multiple interlaved signing requests.

=head2 request

Generates and returns a blind-signing request. The following named
parameters are required:

=over

Init - The initialization vector from init()

Key - The public key of the signer

Message - The message to be blind signed

=back

=head2 sign

Generates and returns a blind signature. The following named
parameters are required:

=over

Key - The private key of the signer

Plaintext - The blind-signing request

=back

=head2 unblind

Unblinds a blind signature and returns a verifiable signature. The
following named parameters are required:

=over

Init - The initialization vector from init()

Key - The public key of the signer

Signature - The blind signature

=back

=head2 verify

Verify a signature. The following named parameters are required:

=over

Key - The public key of the signer

Signature - The blind signature

Message - The message that was signed

=back

=head2 errstr

Crypt::RSA::Blind relies on Crypt::RSA, which uses an error handling
method implemented in Crypt::RSA::Errorhandler. When a method fails
it returns undef and saves the error message. This error message is
available to the caller through the errstr() method. For more details
see the Crypt::RSA::Errorhandler(3) manpage.

=head1 ACCESSORS

Accessors can be called with no arguments to query the value of an
object property, or with a single argument, to set the property to a
specific value (unless it is read-only).

=head2 hashsize

The bitsize of the full-domain hash that will be generated from the
message to be blind-signed.

=head2 initsize

The bitsize of the init vector.

=head2 blindsize

The bitsize of the blinding factor.

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-rsab at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-rsa-blind at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-RSA-Blind>. 
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::RSA::Blind

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-RSA-Blind>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-RSA-Blind>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-RSA-Blind>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-RSA-Blind/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) Ashish Gulhati.

This software package is Open Software; you can use, redistribute,
and/or modify it under the terms of the Open Artistic License 2.0.

Please see L<http://www.opensoftwr.org/oal20.txt> for the full license
terms, and ensure that the license grant applies to you before using
or modifying this software. By using or modifying this software, you
indicate your agreement with the license terms.
