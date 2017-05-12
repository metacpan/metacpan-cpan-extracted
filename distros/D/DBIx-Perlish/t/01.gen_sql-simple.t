use warnings;
use strict;
use Test::More tests => 5;
use DBIx::Perlish;
use t::test_utils;

test_select_sql {
	my $x : table;
} "select * from table",
"select * from table t01",
[];
	
test_select_sql {
	users->type eq "su",
	users->id == superusers->user_id;
} "simple join",
"select * from users t01, superusers t02 where t01.type = ? and t01.id = t02.user_id",
["su"];
