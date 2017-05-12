# $Id$
use warnings;
use strict;
use Test::More tests => 25;
use DBIx::Perlish qw/:all/;
use t::test_utils;

$main::flavor = "pg";
test_select_sql {
	return next(hardware_id_seq);
} "Pg: single sequence return",
"select nextval('hardware_id_seq')",
[];
test_select_sql {
	return next hardware_id_seq;
} "Pg: single sequence return, no parens",
"select nextval('hardware_id_seq')",
[];
test_select_sql {
	return next('fun ny seq');
} "Pg: funny single sequence return",
"select nextval('fun ny seq')",
[];
test_bad_select {
	return next("blah'blah");
} "Pg: wrong sequence name", qr/Sequence name looks wrong/;
test_update_sql {
	tab->state eq "new";

	tab->id = next(some_seq)
} "Pg: sequence in update",
"update tab set id = nextval('some_seq') where state = ?",
['new'];
test_update_sql {
	tab->state eq "new";

	tab->id = next some_seq;
} "Pg: sequence in update, no parens",
"update tab set id = nextval('some_seq') where state = ?",
['new'];

$main::flavor = "oracle";
test_select_sql {
	return next(hardware_id_seq);
} "Ora: single sequence return",
"select hardware_id_seq.nextval from dual",
[];
test_select_sql {
	return next hardware_id_seq;
} "Ora: single sequence return, no parens",
"select hardware_id_seq.nextval from dual",
[];
test_bad_select {
	return next('fun ny seq');
} "Ora: wrong sequence name", qr/Sequence name looks wrong/;
test_update_sql {
	tab->state eq "new";

	tab->id = next(some_seq)
} "Ora: sequence in update",
"update tab set id = some_seq.nextval where state = ?",
['new'];
test_update_sql {
	tab->state eq "new";

	tab->id = next some_seq;
} "Ora: sequence in update, no parens",
"update tab set id = some_seq.nextval where state = ?",
['new'];

$main::flavor = "blah";
test_bad_select {
	return next(hardware_id_seq);
} "Sequences are not supported for this driver", qr/Sequences do not seem to be supported for this DBI flavor/;

