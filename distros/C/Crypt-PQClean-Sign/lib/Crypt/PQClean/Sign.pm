package Crypt::PQClean::Sign;

use strict;
use warnings;

our $VERSION = '0.01';

use Exporter qw(import);
our @EXPORT_OK = qw(
    falcon512_keypair
    falcon512_sign
    falcon512_verify
    falcon1024_keypair
    falcon1024_sign
    falcon1024_verify
    mldsa44_keypair
    mldsa44_sign
    mldsa44_verify
    mldsa65_keypair
    mldsa65_sign
    mldsa65_verify
    mldsa87_keypair
    mldsa87_sign
    mldsa87_verify
    sphincs_shake128f_keypair
    sphincs_shake128f_sign
    sphincs_shake128f_verify
    sphincs_shake128s_keypair
    sphincs_shake128s_sign
    sphincs_shake128s_verify
    sphincs_shake192f_keypair
    sphincs_shake192f_sign
    sphincs_shake192f_verify
    sphincs_shake192s_keypair
    sphincs_shake192s_sign
    sphincs_shake192s_verify
    sphincs_shake256f_keypair
    sphincs_shake256f_sign
    sphincs_shake256f_verify
    sphincs_shake256s_keypair
    sphincs_shake256s_sign
    sphincs_shake256s_verify
);

require XSLoader;
XSLoader::load('Crypt::PQClean::Sign', $VERSION);

1;
__END__

=head1 NAME

Crypt::PQCrypt::Sign - Post-Quantum Cryptography with keypair

=head1 SYNOPSIS

  use Crypt::PQCrypt::Sign qw(falcon512_keypair falcon512_sign falcon512_verify);

  # generate keypair
  ($pk, $sk) = falcon512_keypair();

  # sign message
  my $signature = falcon512_sign($message, $sk);

  # check signature
  my $valid = falcon512_verify($signature, $message, $pk);

=head1 DESCRIPTION

  Provides an interface to the PQClean signatures implementation.

=head1 FUNCTIONS

=over

=item B<falcon512_keypair>

=item B<falcon512_sign>

=item B<falcon512_verify>

=item B<falcon1024_keypair>

=item B<falcon1024_sign>

=item B<falcon1024_verify>

=item B<mldsa44_keypair>

=item B<mldsa44_sign>

=item B<mldsa44_verify>

=item B<mldsa65_keypair>

=item B<mldsa65_sign>

=item B<mldsa65_verify>

=item B<mldsa87_keypair>

=item B<mldsa87_sign>

=item B<mldsa87_verify>

=item B<sphincs_shake128f_keypair>

=item B<sphincs_shake128f_sign>

=item B<sphincs_shake128f_verify>

=item B<sphincs_shake128s_keypair>

=item B<sphincs_shake128s_sign>

=item B<sphincs_shake128s_verify>

=item B<sphincs_shake192f_keypair>

=item B<sphincs_shake192f_sign>

=item B<sphincs_shake192f_verify>

=item B<sphincs_shake192s_keypair>

=item B<sphincs_shake192s_sign>

=item B<sphincs_shake192s_verify>

=item B<sphincs_shake256f_keypair>

=item B<sphincs_shake256f_sign>

=item B<sphincs_shake256f_verify>

=item B<sphincs_shake256s_keypair>

=item B<sphincs_shake256s_sign>

=item B<sphincs_shake256s_verify>

=back

=cut
