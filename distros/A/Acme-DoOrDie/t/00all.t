use strict;
use Test::More
    tests => 5;

BEGIN {
    use_ok("Acme::DoOrDie");
}

ok(
    eval {
	my @result=do_or_die("t/confuse.pl");
	@result == 1 && !defined($result[0])
    },
    "confusing file");

eval {
    do_or_die("t/nonexistent.pl");
};
ok($@ =~ /^Can\'t locate t\/nonexistent\.pl/,
   "nonexistent file");

eval {
    do_or_die("t/syntax.pl");
};
ok($@ =~ /^syntax error/,
   "syntax error");

eval {
    do_or_die("t/runtime.pl");
};
ok($@ =~ /^explicit die/,
   "runtime error");

