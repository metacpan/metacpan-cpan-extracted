#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Crypt::Age::Header;
use Crypt::Age::Keys;
use Crypt::Age::Primitives;

# Test header creation
{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    my $header = Crypt::Age::Header->create($file_key, [$public]);

    ok(defined $header, 'header created');
    is(scalar @{$header->stanzas}, 1, 'one stanza');
    ok(defined $header->mac, 'MAC computed');
}

# Test header to_string format
{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    my $header = Crypt::Age::Header->create($file_key, [$public]);
    my $str = $header->to_string;

    like($str, qr/^age-encryption\.org\/v1\n/, 'starts with version');
    like($str, qr/\n-> X25519 /, 'contains X25519 stanza');
    like($str, qr/\n--- [A-Za-z0-9+\/]+\n$/, 'ends with MAC line');
}

# Test header parse and roundtrip
{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    my $header = Crypt::Age::Header->create($file_key, [$public]);
    my $str = $header->to_string;

    my $offset = 0;
    my $parsed = Crypt::Age::Header->parse(\$str, \$offset);

    is(scalar @{$parsed->stanzas}, 1, 'parsed one stanza');
    is($parsed->stanzas->[0]->type, 'X25519', 'stanza type is X25519');
    is($parsed->mac, $header->mac, 'MAC matches');
    is($offset, length($str), 'offset at end of header');
}

# Test MAC verification
{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    my $header = Crypt::Age::Header->create($file_key, [$public]);

    ok($header->verify_mac($file_key), 'MAC verifies with correct key');

    my $wrong_key = Crypt::Age::Primitives->generate_file_key;
    ok(!$header->verify_mac($wrong_key), 'MAC fails with wrong key');
}

# Test file key unwrapping
{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    my $header = Crypt::Age::Header->create($file_key, [$public]);
    my $unwrapped = $header->unwrap_file_key([$secret]);

    is($unwrapped, $file_key, 'unwrapped file key matches');
}

# Test multiple recipients
{
    my ($public1, $secret1) = Crypt::Age::Keys->generate_keypair;
    my ($public2, $secret2) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    my $header = Crypt::Age::Header->create($file_key, [$public1, $public2]);

    is(scalar @{$header->stanzas}, 2, 'two stanzas for two recipients');

    my $unwrapped1 = $header->unwrap_file_key([$secret1]);
    is($unwrapped1, $file_key, 'first recipient can unwrap');

    my $unwrapped2 = $header->unwrap_file_key([$secret2]);
    is($unwrapped2, $file_key, 'second recipient can unwrap');
}

done_testing;
