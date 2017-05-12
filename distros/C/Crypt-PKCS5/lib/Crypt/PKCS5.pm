package Crypt::PKCS5;

use strict;
use warnings;

use Carp;
use POSIX;
require Exporter;
our @ISA = qw(Exporter);
our $VERSION = '0.02';

our @EXPORT_OK = qw(pbkdf1);


require Digest::MD5;
require Digest::HMAC_SHA1;


# DK = KDF(P, S)

=head1 Key Derivation Functions

=head2 PBKDF1

  PBKDF1($P, $S, $c, $dkLen, [$Hash])

  Input:
         P     password, an octet string
         S     salt, an eight-octet string
         c     iteration count, a positive integer
         dkLen intended length in octets of derived key, a positive integer,
               at most 16 for MD2 or MD5 and 20 for SHA-1
  Options:
         Hash  underlyting Digest::* instance
  Output:
         DK    derived key, a dkLen-octet string

=cut

sub pbkdf1 {
    my $P      = shift; # password, an octet string
    my $S      = shift; # salt, an eight-octet string
    my $c      = shift; # iteration count, a positive integer
    my $dk_len = shift; # intended length in octets of derived key
    my $class  = shift || 'Digest::MD5';

    # Step 1
    if (($class eq 'Digest::MD2' && $dk_len > 16)
        || ($class eq 'Digest::MD5' && $dk_len > 16)
        || ($class eq 'Digest::SHA1' && $dk_len > 20))
    {
        croak 'derived key too long';
    }

    # Step 2
    my $hash = $class->new;
    my $dk = $hash->add($P. $S)->digest();
    for (my $i = 1; $i < $c; $i++) {
        $dk = $hash->add($dk)->digest();
    }
    # Step 3
    return substr $dk, 0, $dk_len;
}


=head2 PBKDF2

  PBKDF2($P, $S, $c, $dkLen, [$PRF])
  
  Input:
         P     password, an octet string
         S     salt, an octet string
         c     iteration count, a positive integer
         dkLen intended length in octets of the derived key, a positive integer,
               at most (2**32 -1) x hLen
  Output:
         DK    derived key, a dkLen-octet string
  Options:
          PRF  underlying pseudorandom function (hLen denotes the length in
               octets of the pseudorandom function output)

=cut

sub _pbkdf2_F {
    my $PRF = shift; # include P
    my $S = shift;
    my $c = shift;
    my $i = shift;
    my $h_len = shift || 20;

    $PRF->reset();
    my $U = $PRF->add($S. pack 'N', $i)->digest();
    my $U_last = $U;
    for (my $j = 1; $j < $c; $j++) {
        $PRF->reset();
        $U_last = $PRF->add($U_last)->digest();
        $U ^= $U_last;
    }
    return $U;
}


sub pbkdf2 {
    my $P      = shift; # password, an octet string
    my $S      = shift; # salt, an octet string
    my $c      = shift; # iteration count, a positive integer
    my $dk_len = shift; # intended length in octets of derived key
    my $class  = shift || 'Digest::HMAC_SHA1';

    my $h_len = 20;
    if ($class eq 'Digest::HMAC_SHA1') {
        $h_len = 20;
    }
    my $prf = $class->new($P);

    # check $dk_len

    my $l = POSIX::ceil($dk_len / $h_len);

    my $T = '';
    for (my $i = 1; $i <= $l; $i++) {
        $T .= _pbkdf2_F($prf, $S, $c, $i);
    }

    # Step 4
    return substr $T, 0, $dk_len;
}


1;
__END__

=head1 NAME

Crypt::PKCS5 - PKCS #5 v2.1: Password-Based Cryptography Standard.

=head1 SYNOPSIS

  use Crypt::PKCS5;

=head1 DESCRIPTION

Blah blah blah.


=head1 SEE ALSO

http://www.rsa.com/rsalabs/node.asp?id=2127

=head1 AUTHOR

Hiroyuki OYAMA, E<lt>oyama@module.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Hiroyuki OYAMA

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
