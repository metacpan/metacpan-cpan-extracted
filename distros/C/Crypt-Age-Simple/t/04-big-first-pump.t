#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Crypt::Age::Simple qw< :x25519 >;
use Crypt::Age::Simple::Buffer;
use Crypt::Age::Simple::Decrypt;

# first pump() bigger than max_header_size: the header parser takes a slice
# of the first chunk and must give the excess back to the input buffer
my ($public, $secret) = age_x25519_generate_keypair();
my $cleartext = join '', map { chr(65 + $_ % 26) } 1 .. 200_000;
my $ciphertext = age_x25519_encrypt($public, $cleartext);
cmp_ok length($ciphertext), '>', 64 * 1024, 'ciphertext over 64 KiB';

my $decrypt = Crypt::Age::Simple::Decrypt->new(identity => [$secret]);
$decrypt->pump($ciphertext)->finish;
my $decoded = join '', map { $$_ } $decrypt->get_chunks->@*;
ok $decoded eq $cleartext, 'single big pump() decrypts correctly';

# give_back of multiple parts, partly overlapping the consumed bytes
my $buffer = Crypt::Age::Simple::Buffer->new(
   buffers => \'cdefghijklmnop',
   offset  => 2,
);
$buffer->give_back([\'a', \'bcd']);
is $buffer->get_bytes->$*, 'abcdefghijklmnop', 'multi-part give_back';

done_testing();
