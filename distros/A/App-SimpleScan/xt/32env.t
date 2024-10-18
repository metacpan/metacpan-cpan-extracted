#!/usr/local/bin/perl
use Test::More tests=>2;
use Test::Differences;

delete $ENV{LANGUAGE};
$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

@output = `LANGUAGE=perl $^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan --gen <examples/ss_backtick_env.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://perl.org",
          qr/perl/i,
          qq(perl.org [http://perl.org] [/perl/i should match]);
EOF
push @expected, "\n";
eq_or_diff(\@output, \@expected, "working output as expected");

$ENV{LANGUAGE} = 'perl';
@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan <examples/ss_backtick_env.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
1..1
ok 1 - perl.org [http://perl.org] [/perl/i should match]
EOF
eq_or_diff(\@output, \@expected, "working output as expected");
