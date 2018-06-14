#!/usr/bin/env perl

use strict;
use warnings;
use Data::Validate::DNS::SSHFP ':all';
use Test::More;
use Test::Warnings;

for my $alg (1..4) {
    ok is_sshfp_algorithm($alg), "$alg is a valid SSHFP algorithm";
}
ok !is_sshfp_algorithm(5);

for my $fptype (1..2) {
    ok is_sshfp_fptype($fptype), "$fptype is a valid SSHFP fingerprint type";
}
ok !is_sshfp_fptype(3);

my %fingerprints = (
    1 => '4833d83726d8f66c5a2747e5f4a177c506e8f01f',
    2 => '0ebe201b8f0dc7d4f297980543fbd0c94248bbbbcf98615d69dc5bee9f97406a');

while (my ($fptype, $digest) = each %fingerprints) {
    ok is_sshfp_fingerprint($fptype, $digest), "Valid fingerprint for fptype $fptype";
    ok !is_sshfp_fingerprint($fptype, substr $digest, 1);
}

done_testing;
