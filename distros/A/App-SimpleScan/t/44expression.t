#!/usr/local/bin/perl
use Test::More tests=>1;
use Test::Differences;

$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan -gen <examples/expression.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://nowhere.com",
          qr/zip/,
          qq(look for 3 [http://nowhere.com] [/zip/ should match]);
EOF
push @expected, "\n";
eq_or_diff(\@output, \@expected, "working output as expected");
