#!/usr/bin/env perl
use v5.36;
use Test::More;

BEGIN {
    eval {
        require Math::BigInt;
        require Digest::SHA;
    };
    if ($@) {
        plan skip_all => 'Math::BigInt or Digest::SHA not available';
    }
}

use_ok('Protocol::HAP::SRP');

# Test _bigint_to_bytes helper function
{
    # Test basic conversion without padding
    my $n = Math::BigInt->new(5);
    my $bytes = Protocol::HAP::SRP::_bigint_to_bytes($n);
    is(unpack('H*', $bytes), '05', '_bigint_to_bytes converts 5 correctly');

    # Test that the function removes the 0x prefix
    my $n2 = Math::BigInt->new(255);
    my $bytes2 = Protocol::HAP::SRP::_bigint_to_bytes($n2);
    is(unpack('H*', $bytes2), 'ff', '_bigint_to_bytes strips 0x prefix');

    # Test padding to specific length
    my $n3 = Math::BigInt->new(5);
    my $bytes3 = Protocol::HAP::SRP::_bigint_to_bytes($n3, 4);
    is(unpack('H*', $bytes3), '00000005', '_bigint_to_bytes pads to 4 bytes');
    is(length($bytes3), 4, 'Padded output is 4 bytes');

    # Test that the function pads odd-length hex with a leading zero
    my $n4 = Math::BigInt->new(4095);  # 0xFFF has 3 hex digits
    my $bytes4 = Protocol::HAP::SRP::_bigint_to_bytes($n4);
    is(unpack('H*', $bytes4), '0fff', '_bigint_to_bytes pads odd-length hex');

    # Test large number (3072-bit)
    my $large = Math::BigInt->from_hex('0x' . ('FF' x 384));
    my $bytes5 = Protocol::HAP::SRP::_bigint_to_bytes($large);
    is(length($bytes5), 384, '_bigint_to_bytes handles 3072-bit numbers');
    is(unpack('H*', $bytes5), 'ff' x 384, 'Large number converted correctly');
}

# Test SRP object creation
{
    my $srp = Protocol::HAP::SRP->new(
        username => 'Pair-Setup',
        password => '123-45-678',
    );

    ok(defined $srp, 'SRP object created');
    isa_ok($srp, 'Protocol::HAP::SRP');
    is($srp->{username}, 'Pair-Setup', 'Username set');
    is($srp->{password}, '12345678', 'Password normalized (dashes stripped)');
}

# Test default username
{
    my $srp = Protocol::HAP::SRP->new(password => 'test');
    is($srp->{username}, 'Pair-Setup', 'Default username is Pair-Setup');
}

# Test SRP parameters
{
    my $srp = Protocol::HAP::SRP->new(password => 'test');

    ok(defined $srp->{N}, 'N parameter set');
    ok(defined $srp->{g}, 'g parameter set');
    isa_ok($srp->{N}, 'Math::BigInt', 'N is BigInt');
    isa_ok($srp->{g}, 'Math::BigInt', 'g is BigInt');

    # The g parameter must be 5
    is($srp->{g}->numify(), 5, 'g parameter is 5');
}

# Test salt generation
{
    my $srp = Protocol::HAP::SRP->new(password => 'test');

    my $salt = $srp->generate_salt();
    ok(defined $salt, 'Salt generated');
    is(length($salt), 16, 'Salt is 16 bytes');

    my $salt2 = $srp->generate_salt();
    isnt($salt, $salt2, 'Different salts generated');
}

# Test verifier computation
{
    my $srp = Protocol::HAP::SRP->new(password => '123-45-678');

    my $salt = $srp->generate_salt();
    my $v = $srp->compute_verifier($salt);

    ok(defined $v, 'Verifier computed');
    isa_ok($v, 'Math::BigInt', 'Verifier is BigInt');
    ok($v > 0, 'Verifier is positive');
}

# Test server public key generation
{
    my $srp = Protocol::HAP::SRP->new(password => '123-45-678');

    my $salt = $srp->generate_salt();
    $srp->compute_verifier($salt);

    my $B = $srp->generate_server_public();

    ok(defined $B, 'Server public key generated');
    isa_ok($B, 'Math::BigInt', 'B is BigInt');
    ok($B > 0, 'B is positive');
}

# Test session key computation
{
    my $srp = Protocol::HAP::SRP->new(password => '123-45-678');

    my $salt = $srp->generate_salt();
    $srp->compute_verifier($salt);
    $srp->generate_server_public();

    # Create a dummy client public key (32 bytes)
    my $A = 'A' x 32;

    my $K = $srp->compute_session_key($A);
    ok(defined $K, 'Session key computed');
    is(length($K), 64, 'Session key is 64 bytes (SHA-512)');
}

# Test SRP A mod N == 0 validation
{
    my $srp = Protocol::HAP::SRP->new(password => '123-45-678');

    my $salt = $srp->generate_salt();
    $srp->compute_verifier($salt);
    $srp->generate_server_public();

    # Test with A = 0. The module must reject it.
    my $A_zero = "\x00" x 384;  # 3072 bits = 384 bytes
    my $K = $srp->compute_session_key($A_zero);
    ok(!defined $K, '[HAP-Pairing §2.6] session key rejected when A is zero');

    # Test with A = N. The module must reject it because A mod N == 0.
    # Get N as bytes
    my $N_hex = $srp->{N}->as_hex();
    $N_hex =~ s/^0x//;
    my $A_equals_N = pack('H*', $N_hex);
    $K = $srp->compute_session_key($A_equals_N);
    ok(!defined $K,
        '[HAP-Pairing §2.6] session key rejected when A mod N == 0');
}

# Test session_key
{
    my $srp = Protocol::HAP::SRP->new(password => '123-45-678');

    my $salt = $srp->generate_salt();
    $srp->compute_verifier($salt);
    $srp->generate_server_public();

    my $A = 'A' x 32;
    $srp->compute_session_key($A);

    my $K = $srp->session_key;
    ok(defined $K, 'Session key retrieved');
    is(length($K), 64, 'Retrieved session key is 64 bytes');
}

done_testing();
