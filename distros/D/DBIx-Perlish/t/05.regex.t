use warnings;
use strict;
use DBIx::Perlish qw/:all/;
use Test::More;
use t::test_utils;

my $like_none = undef;
test_select_sql {
	my $t : tbl;
	tbl->id =~ $like_none
} "like undef",
"select * from tbl t01",
[];

# simple RE (pg)
test_select_sql {
	tbl->id =~ /^abc/
} "like test in front",
"select * from tbl t01 where t01.id like 'abc%'",
[];

# simple RE (pg)
test_select_sql {
	tbl->id =~ /abc$/
} "like test behind",
"select * from tbl t01 where t01.id like '%abc'",
[];

test_select_sql {
	tbl->id =~ /abc/
} "like test both sides",
"select * from tbl t01 where t01.id like '%abc%'",
[];

my $rx = '^abc';
$rx = qr/$rx/i;
test_select_sql {
	tbl->id =~ /$rx/
} "like test",
"select * from tbl t01 where t01.id like 'abc%'",
[];

test_select_sql {
	tbl->id !~ /^abc/
} "not like test",
"select * from tbl t01 where t01.id not like 'abc%'",
[];
test_select_sql {
	tbl->id =~ /^abc/i
} "ilike test",
"select * from tbl t01 where t01.id ilike 'abc%'",
[];
test_select_sql {
	tbl->id !~ /^abc/i
} "not ilike test",
"select * from tbl t01 where t01.id not ilike 'abc%'",
[];
test_select_sql {
	tbl->id =~ /^abc_/
} "like underscore",
"select * from tbl t01 where t01.id like 'abc!_%' escape '!'",
[];
test_select_sql {
	tbl->id =~ /^abc%/
} "like percent",
"select * from tbl t01 where t01.id like 'abc!%%' escape '!'",
[];
test_select_sql {
	tbl->id =~ /^abc!/
} "like exclamation",
"select * from tbl t01 where t01.id like 'abc!!%' escape '!'",
[];
test_select_sql {
	tbl->id =~ /^abc!_%/
} "like exclamation underscore percent",
"select * from tbl t01 where t01.id like 'abc!!!_!%%' escape '!'",
[];
test_select_sql {
	tbl->id =~ /^abc!!__%%/
} "like exclamation underscore percent doubled",
"select * from tbl t01 where t01.id like 'abc!!!!!_!_!%!%%' escape '!'",
[];

test_select_sql {
	tbl->id =~ /^abc\[-\-\%/
} "like test",
"select * from tbl t01 where t01.id like 'abc[--!%%' escape '!'",
[];

# RE with vars (pg)
my $re = "abc";
test_select_sql {
	tbl->id =~ /^$re/
} "like test, scalar",
"select * from tbl t01 where t01.id like 'abc%'",
[];

$re = { re => "abc" };
test_select_sql {
	tbl->id =~ /^$re->{re}/
} "like test, hashref",
"select * from tbl t01 where t01.id like 'abc%'",
[];


done_testing;
