# NOTE: For production deployments, use deps/*.txt with 'make deps'.
# This file exists for development convenience and carton compatibility.
#
# The Fugu library and the FuguVM and FuguWeb tools install from their
# latest GitHub releases through the dist lines of deps/*.txt, not
# from CPAN.

# Crypto dependencies for the HAP protocol
requires 'Crypt::Ed25519';
requires 'Crypt::Curve25519';
requires 'CryptX';

# JSON parsing
requires 'JSON::XS';

# GMP backend for Math::BigInt. SRP does 3072-bit modular exponentiation.
# That operation is impractically slow in the pure-Perl backend.
# Math::BigInt loads this backend automatically when present.
requires 'Math::BigInt::GMP';

# MQTT client for device integration
requires 'Net::MQTT::Simple';

# Test dependencies for testing and CI
on 'test' => sub {
	requires 'Perl::Critic';
	requires 'Perl::Tidy';
};
