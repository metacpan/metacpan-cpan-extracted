package Crypt::Bear::AES_CTR::DRBG;
$Crypt::Bear::AES_CTR::DRBG::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: AESCTR-DRBG PRNG in BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::AES_CTR::DRBG - AESCTR-DRBG PRNG in BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $prng = Crypt::Bear::AESCTR_DRBG('0123456789ABCDEF');
 $prng->system_seed;
 say unpack 'H*', $prng->generate(16);

=head1 DESCRIPTION

AESCTR_DRBG is a custom PRNG based on AES-128 in CTR mode. This is meant to be used only in situations where you are desperate for speed, and have an hardware-optimized AES/CTR implementation. Whether this will yield perceptible improvements depends on what you use the pseudorandom bytes for, and how many you want; for instance, RSA key pair generation uses a substantial amount of randomness, and using AESCTR_DRBG instead of HMAC_DRBG yields a 15 to 20% increase in key generation speed on a recent x86 CPU (Intel Core i7-6567U at 3.30 GHz).

Internally, it uses CTR mode with successive counter values, starting at zero (counter value expressed over 128 bits, big-endian convention). The counter is not allowed to reach 32768; thus, every 32768*16 bytes at most, the C<update()> function is run (on an empty seed, if none is provided). The C<update()> function computes the new AES-128 key by applying a custom hash function to the concatenation of a state-dependent word (encryption of an all-one block with the current key) and the new seed. The custom hash function uses Hirose's construction over AES-256.

=head1 METHODS

=head2 new($seed)

Creates a new C<AES_DRBG> pseudo random generator based on the given C<$seed>.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
