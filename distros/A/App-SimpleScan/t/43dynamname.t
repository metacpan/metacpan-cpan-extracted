#!/usr/local/bin/perl
use Test::More tests=>1;
use Test::Differences;

$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan -gen <examples/ss_dynamvar.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
use Test::More tests=>3;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://ca.staging.search.yahoo.com",
          qr/Yahoo!/,
          qq(brand on ca.staging.search.yahoo.com [http://ca.staging.search.yahoo.com] [/Yahoo!/ should match]);
page_like "http://uk.staging.search.yahoo.com",
          qr/Yahoo!/,
          qq(brand on uk.staging.search.yahoo.com [http://uk.staging.search.yahoo.com] [/Yahoo!/ should match]);
page_like "http://au.staging.search.yahoo.com",
          qr/Yahoo!/,
          qq(brand on au.staging.search.yahoo.com [http://au.staging.search.yahoo.com] [/Yahoo!/ should match]);
EOF
push @expected, "\n";
eq_or_diff(\@output, \@expected, "working output as expected");
