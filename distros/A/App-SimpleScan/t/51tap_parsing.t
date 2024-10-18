use strict;
use warnings;

use Test::More;
use Test::Differences;

$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

my $expected = <<EOS;
UNNAMED_TEST: tests=1, ok=1, failed=0, skipped=0, todo=0
EOS

my $got = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_report <t/1successful.tap`;
eq_or_diff $got, $expected, "output as planned, successful test";

$expected = <<EOS;
UNNAMED_TEST: tests=1, ok=0, failed=1, skipped=0, todo=0
EOS

$got = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_report <t/1failed.tap`;
eq_or_diff $got, $expected, "output as planned, faiiled test";

$expected = <<EOS;
UNNAMED_TEST: tests=1, ok=1, failed=0, skipped=1, todo=0
EOS

$got = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_report <t/1skip.tap`;
eq_or_diff $got, $expected, "output as planned, skipped test";

$expected = <<EOS;
UNNAMED_TEST: tests=1, ok=0, failed=0, skipped=0, todo=1
EOS

$got = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_report <t/1failing_TODO.tap`;
eq_or_diff $got, $expected, "output as planned, TODO test";

$expected = <<EOS;
UNNAMED_TEST: tests=1, ok=0, failed=1, skipped=0, todo=1 (1 UNEXPECTEDLY SUCCEEDED)
EOS

$got = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_report <t/1passingTODO.tap`;
eq_or_diff $got, $expected, "output as planned, passing TODO test";

done_testing;
