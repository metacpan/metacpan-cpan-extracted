#!/usr/local/bin/perl
use Test::More tests=>2;
use Test::Differences;

$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan <examples/ss_backtick1.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
1..4
ok 1 - perl.org [http://perl.org] [/perl/i should match]
ok 2 - python.org [http://python.org] [/python/i should match]
ok 3 - ruby.org [http://ruby.org] [/ruby/i should match]
ok 4 - erlang.org [http://erlang.org] [/erlang/i should match]
EOF
eq_or_diff(\@output, \@expected, "working output as expected");

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan <examples/ss_quoted.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
1..4
ok 1 - Find "Master Librarian" [http://cpan.org] [/Master Librarian/ should match]
ok 2 - Find "Mailing Lists" [http://cpan.org] [/Mailing Lists/ should match]
ok 3 - Find "Perl modules" [http://cpan.org] [/Perl modules/ should match]
ok 4 - Find "Perl scripts" [http://cpan.org] [/Perl scripts/ should match]
EOF
eq_or_diff(\@output, \@expected, "working output as expected");
