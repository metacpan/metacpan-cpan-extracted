#!/usr/local/bin/perl
use Test::More tests=>2;
use Test::Differences;

$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan -run <examples/ss_escaped.in 2>&1`;
@expected = map {"$_\n"} split /\n/,<<EOF;
1..1
ok 1 - digits [http://yahoo.com] [/\\d+/ should match]

EOF
eq_or_diff(\@output, \@expected, "working output as expected");

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan -gen <examples/ss_escaped.in 2>&1|$^X`;
@expected = map {"$_\n"} split /\n/,<<EOF;
1..1
ok 1 - digits [http://yahoo.com] [/\\d+/ should match]

EOF
eq_or_diff(\@output, \@expected, "working output as expected");
