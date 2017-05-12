#!/usr/local/bin/perl
use Test::More tests=>1;
use Test::Differences;

$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan<examples/ss.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
1..4
ok 1 - No python on perl.org [http://perl.org/] [/python/ shouldn't match]
ok 2 - No perl on python.org [http://python.org/] [/perl/ shouldn't match]
ok 3 - Python on python.org [http://python.org/] [/python/ should match]
ok 4 - Perl on perl.org [http://perl.org/] [/perl/ should match]
EOF
eq_or_diff(\@output, \@expected, "working output as expected");
