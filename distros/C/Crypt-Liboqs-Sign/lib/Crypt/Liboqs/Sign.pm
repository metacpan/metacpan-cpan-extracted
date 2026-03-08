package Crypt::Liboqs::Sign;

use strict;
use warnings;

our $VERSION = '0.01';

use Exporter qw(import);

our @EXPORT_OK;

require XSLoader;
XSLoader::load('Crypt::Liboqs::Sign', $VERSION);

# Backward-compatible mappings: PQClean function prefix => liboqs algorithm name
my %COMPAT_ALGORITHMS = (
    falcon512              => 'Falcon-512',
    falcon1024             => 'Falcon-1024',
    mldsa44                => 'ML-DSA-44',
    mldsa65                => 'ML-DSA-65',
    mldsa87                => 'ML-DSA-87',
    sphincs_shake128f      => 'SPHINCS+-SHAKE-128f-simple',
    sphincs_shake128s      => 'SPHINCS+-SHAKE-128s-simple',
    sphincs_shake192f      => 'SPHINCS+-SHAKE-192f-simple',
    sphincs_shake192s      => 'SPHINCS+-SHAKE-192s-simple',
    sphincs_shake256f      => 'SPHINCS+-SHAKE-256f-simple',
    sphincs_shake256s      => 'SPHINCS+-SHAKE-256s-simple',
);

my %generated;

# Generate backward-compatible functions
for my $prefix (keys %COMPAT_ALGORITHMS) {
    my $alg = $COMPAT_ALGORITHMS{$prefix};
    next unless _oqs_alg_is_enabled($alg);
    _generate_functions($prefix, $alg);
}

# Normalize liboqs algorithm name to Perl function prefix
sub _normalize_name {
    my ($name) = @_;
    $name = lc($name);
    $name =~ s/[^a-z0-9]+/_/g;
    $name =~ s/^_|_$//g;
    return $name;
}

# Generate functions for all enabled algorithms
my %reverse_compat = reverse %COMPAT_ALGORITHMS;
for my $alg (_oqs_alg_list()) {
    next if $reverse_compat{$alg};
    my $prefix = _normalize_name($alg);
    _generate_functions($prefix, $alg);
}

# Also generate canonical names for compat algorithms where normalized name differs
for my $prefix (keys %COMPAT_ALGORITHMS) {
    my $alg = $COMPAT_ALGORITHMS{$prefix};
    next unless _oqs_alg_is_enabled($alg);
    my $canonical = _normalize_name($alg);
    next if $canonical eq $prefix;
    _generate_functions($canonical, $alg);
}

# Add utility functions to exports
push @EXPORT_OK, qw(_oqs_alg_list _oqs_alg_is_enabled _oqs_keypair _oqs_sign _oqs_verify);

sub _generate_functions {
    my ($prefix, $alg) = @_;
    return if $generated{$prefix}++;
    no strict 'refs';
    *{"${prefix}_keypair"} = sub { _oqs_keypair($alg) };
    *{"${prefix}_sign"}    = sub { _oqs_sign($alg, $_[0], $_[1]) };
    *{"${prefix}_verify"}  = sub { _oqs_verify($alg, $_[0], $_[1], $_[2]) };
    push @EXPORT_OK, "${prefix}_keypair", "${prefix}_sign", "${prefix}_verify";
}

1;
__END__

=head1 NAME

Crypt::Liboqs::Sign - Post-Quantum Digital Signatures via liboqs

=head1 SYNOPSIS

  use Crypt::Liboqs::Sign qw(falcon512_keypair falcon512_sign falcon512_verify);

  # generate keypair
  my ($pk, $sk) = falcon512_keypair();

  # sign message
  my $signature = falcon512_sign($message, $sk);

  # verify signature
  my $valid = falcon512_verify($signature, $message, $pk);

=head1 DESCRIPTION

Provides Perl bindings to the liboqs (Open Quantum Safe) library for
post-quantum digital signature schemes. This module is a drop-in replacement
for L<Crypt::PQClean::Sign> with support for all signature algorithms
available in liboqs.

=head2 Supported Algorithm Families

=over

=item * Falcon (Falcon-512, Falcon-1024, padded variants)

=item * ML-DSA / Dilithium (ML-DSA-44, ML-DSA-65, ML-DSA-87)

=item * SPHINCS+ / SLH-DSA (SHA2 and SHAKE variants, 128/192/256 bit security)

=item * MAYO (MAYO-1 through MAYO-5)

=item * CROSS (RSDP and RSDPG variants)

=item * And all other signature algorithms enabled in the installed liboqs

=back

=head2 Function Naming

Each algorithm provides three functions: C<{prefix}_keypair>,
C<{prefix}_sign>, and C<{prefix}_verify>.

For backward compatibility with L<Crypt::PQClean::Sign>, the following
prefixes are supported:

  falcon512, falcon1024, mldsa44, mldsa65, mldsa87,
  sphincs_shake128f, sphincs_shake128s, sphincs_shake192f,
  sphincs_shake192s, sphincs_shake256f, sphincs_shake256s

Additional algorithms use normalized names derived from the liboqs
algorithm identifier (e.g., C<mayo_1_keypair>, C<falcon_padded_512_keypair>).

=head2 Utility Functions

=over

=item B<_oqs_alg_list>

Returns a list of all enabled signature algorithm names.

=item B<_oqs_alg_is_enabled>(I<algorithm_name>)

Returns true if the given algorithm is enabled in the installed liboqs.

=item B<_oqs_keypair>(I<algorithm_name>)

Generic keypair generation for any algorithm by name.

=item B<_oqs_sign>(I<algorithm_name>, I<message>, I<secret_key>)

Generic signing for any algorithm by name.

=item B<_oqs_verify>(I<algorithm_name>, I<signature>, I<message>, I<public_key>)

Generic verification for any algorithm by name.

=back

=head1 REQUIREMENTS

Requires the liboqs C library to be installed on the system.
See L<https://github.com/open-quantum-safe/liboqs> for installation instructions.

=head1 SEE ALSO

L<Crypt::PQClean::Sign>, L<https://openquantumsafe.org/>

=head1 AUTHOR

Pavel Gulchouk E<lt>gul@gul.kiev.uaE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
