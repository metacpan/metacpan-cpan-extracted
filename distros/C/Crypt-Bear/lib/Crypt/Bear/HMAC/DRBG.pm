package Crypt::Bear::HMAC::DRBG;
$Crypt::Bear::HMAC::DRBG::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: HMAC-DRBG PRNG in BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::HMAC::DRBG - HMAC-DRBG PRNG in BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $prng = Crypt::Bear::HMAC_DRBG('sha256', 0123456789ABCDEF');
 $prng->system_seed;
 say unpack 'H*', $prng->generate(16);

=head1 DESCRIPTION

HMAC_DRBG is defined in L<NIST SP 800-90A Revision 1|http://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-90Ar1.pdf>). It uses HMAC repeatedly, over some configurable underlying hash function. 

According to the NIST standard, each request shall produce up to 2¹⁹ bits (i.e. 64 kB of data); moreover, the context shall be reseeded at least once every 2⁴⁸ requests. This implementation does not maintain the reseed counter (the threshold is too high to be reached in practice) and does not object to producing more than 64 kB in a single request; thus, the code cannot fail, which corresponds to the fact that the API has no room for error codes. However, this implies that requesting more than 64 kB in one C<generate()> request, or making more than 2⁴⁸ requests without reseeding, is formally out of NIST specification. There is no currently known security penalty for exceeding the NIST limits, and, in any case, HMAC_DRBG usage in implementing SSL/TLS always stays much below these thresholds.

=head1 METHODS

=head2 new($digest, $seed)

Creates a new C<HMAC_DRBG> pseudo random generator based on the given C<$digest> and C<$seed>.

The C<seed> value is what is called, in NIST terminology, the concatenation of the "seed", "nonce" and "personalization string", in that order.

=head2 digest()

This returns the digest used, e.g. C<'sha256'>.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
