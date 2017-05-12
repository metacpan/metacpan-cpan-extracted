#!/usr/local/bin/perl
use Test::More tests=>1;
use Test::Differences;

$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan -status <examples/ss.in 2>&1`;
@expected = map {"$_\n"} split /\n/,<<EOF;
# |Processing 'http://perl.org/ 	/python/ 	N No python on perl.org' (line 1)
# |Processing 'http://python.org/ 	/perl/  	N No perl on python.org' (line 2)
# |Processing 'http://python.org/ 	/python/ 	Y Python on python.org' (line 3)
# |Processing 'http://perl.org/ 	/perl/ 		Y Perl on perl.org' (line 4)
1..4
ok 1 - No python on perl.org [http://perl.org/] [/python/ shouldn't match]
ok 2 - No perl on python.org [http://python.org/] [/perl/ shouldn't match]
ok 3 - Python on python.org [http://python.org/] [/python/ should match]
ok 4 - Perl on perl.org [http://perl.org/] [/perl/ should match]
EOF
eq_or_diff(\@output, \@expected, "working output as expected");
