#!/usr/local/bin/perl
use Test::More tests=>1;
use Test::Differences;

$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan -gen <examples/renegade-percent.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
fail "malformed pragma or URL scheme: '%ttp://not-actually-used.com/'";
# %ttp://not-actually-used.com/ /\\[mail\\] => 97468175/ Y 
# Possible syntax error in this test spec
EOF
push @expected, "\n";
eq_or_diff(\@output, \@expected, "working output as expected");
