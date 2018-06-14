#!/usr/bin/env perl -T

use strict;
use warnings;
use Data::Validate::DNS::SSHFP;
use Scalar::Util qw(tainted);
use Taint::Util qw(taint);
use Test::More;
use Test::Warnings;

my %tests = (
    is_sshfp_algorithm   => [1],
    is_sshfp_fptype      => [1],
    is_sshfp_fingerprint => [1 => '4833d83726d8f66c5a2747e5f4a177c506e8f01f']);

my $v = new_ok 'Data::Validate::DNS::SSHFP';

while (my ($test, $value) = each %tests) {
    note "Taint test for $test";

    taint(my @args = @$value);

    ok tainted($args[-1]);

    my $rv = $v->$test(@args);

    ok !tainted($rv), 'return value is not tainted';

    is $rv, $args[-1];
}

done_testing;
