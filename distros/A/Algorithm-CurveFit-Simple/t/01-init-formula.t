#!/bin/env perl
use strict;
use warnings;
use Test::Most;
use JSON::PP;

use lib "./lib";
use Algorithm::CurveFit::Simple qw(%STATS_H);

my $f = eval { Algorithm::CurveFit::Simple::_init_formula(); };
print "# exception: $@\n" if ($@);

ok !$@, "default - no thrown exceptions";
ok defined($f), "default - returned a defined value";
$f //= '';
is ref($f), '', "default - returned string";
ok $f =~ /^k (\+ \w\s?\*\s?x\^?\d*\s*)+$/, "default - formula is well-formed" if($f);

my $formula;
for (my $i = 1; $i < 10; $i++) {
    $f = eval { Algorithm::CurveFit::Simple::_init_formula(terms => $i); };
    $formula = $f if ($i == 3);
    ok !$@, "with $i terms - no thrown exceptions";
    ok defined($f), "with $i terms - returned a defined value";
    $f //= '';
    is ref($f), '', "with $i terms - returned string";
    ok $f =~ /^k (\+ \w\s?\*\s?x\^?\d*\s*){$i}$/, "with $i terms - formula is well-formed" if($f);
}

if ($ARGV[0]) {
    print "formula=$formula\n";
    print JSON::PP::encode_json(\%STATS_H)."\n";
}

done_testing();
exit(0);
