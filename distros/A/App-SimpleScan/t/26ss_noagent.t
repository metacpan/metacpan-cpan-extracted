#!/usr/local/bin/perl
use Test::More tests=>1;
use Test::Differences;

$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan --no_agent <examples/ss_user_agent.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
1..3
ok 1 - Perl should be there (WWW::Mechanize::Pluggable) [http://perl.org/] [/perl/ should match]
ok 2 - Perl should be there (Mac Safari) [http://perl.org/] [/perl/ should match]
ok 3 - Perl should be there (Linux Konqueror) [http://perl.org/] [/perl/ should match]
EOF
eq_or_diff(\@output, \@expected, "working output as expected");
