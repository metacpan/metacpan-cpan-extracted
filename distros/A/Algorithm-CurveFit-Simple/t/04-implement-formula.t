#!/bin/env perl
use strict;
use warnings;
use Test::Most;
use JSON::PP;

use lib "./lib";
use Algorithm::CurveFit::Simple;

my $parar = [["k", 10, 1], ["a", 2, 1], ["b", 3, 1], ["c", 4, 1]];
my $xdata = [8, 3, 5, 11, 9, 7, 4];

my $s = eval { Algorithm::CurveFit::Simple::_implement_formula($parar, "", "x2y", $xdata, {}); };
ok defined($s), "implementation default throws no exceptions";
ok $s =~ /^sub x2y /, "implementation default is perl";

$s = eval { Algorithm::CurveFit::Simple::_implement_formula($parar, "coderef", "x2y", $xdata, {}); };
ok defined($s), "implementation coderef throws no exceptions";
is ref($s), "CODE", "implementation coderef is coderef";

# perl implementation:

$s = eval { Algorithm::CurveFit::Simple::_implement_formula($parar, "perl", "x2y", $xdata, {}); };
ok defined($s), "implementation perl throws no exceptions";
ok $s =~ /^sub x2y /, "implementation perl is perl";
ok $s !~ /x out of bounds/, "implementation perl without bounds check is permissive";
ok $s !~ /y = int/, "implementation perl without rounding check returns precision result";

$s = eval { Algorithm::CurveFit::Simple::_implement_formula($parar, "perl", "x2y", $xdata, {bounds_check => 1}); };
ok $s =~ /x out of bounds/, "implementation perl with bounds check is limited";
ok $s !~ /y = int/, "implementation perl with bounds check without round result returns precision result";

$s = eval { Algorithm::CurveFit::Simple::_implement_formula($parar, "perl", "x2y", $xdata, {round_result => 1}); };
ok $s !~ /x out of bounds/, "implementation perl without bounds check with round result is permissive";
ok $s =~ /y = int/, "implementation perl without bounds check with round result returns rounded result";

# C implementation:

$s = eval { Algorithm::CurveFit::Simple::_implement_formula($parar, "c", "x2y", $xdata, {}); };
ok defined($s), "implementation C throws no exceptions";
ok $s =~ /double x2y\(double x\) \{/, "implementation C is C";
ok $s !~ /return -1.0/, "implementation C without bounds check is permissive";
ok $s !~ /y = round/, "implementation C without rounding check returns precision result";
print $Algorithm::CurveFit::Simple::STATS_H{impl_source} . "\n" if ($ARGV[0]);

$s = eval { Algorithm::CurveFit::Simple::_implement_formula($parar, "c", "x2y", $xdata, {bounds_check => 1}); };
ok $s =~ /return -1.0/, "implementation C with bounds check is limited";
ok $s !~ /y = round/, "implementation C with bounds check without round result returns precision result";
print $Algorithm::CurveFit::Simple::STATS_H{impl_source} . "\n" if ($ARGV[0]);

$s = eval { Algorithm::CurveFit::Simple::_implement_formula($parar, "c", "x2y", $xdata, {round_result => 1}); };
ok $s !~ /return -1.0/, "implementation C without bounds check with round result is permissive";
ok $s =~ /y = round/, "implementation C without bounds check with round result returns rounded result";
print $Algorithm::CurveFit::Simple::STATS_H{impl_source} . "\n" if ($ARGV[0]);

if ($ARGV[0]) {
    print JSON::PP::encode_json(\%Algorithm::CurveFit::Simple::STATS_H) . "\n";
}

done_testing();
exit(0);
