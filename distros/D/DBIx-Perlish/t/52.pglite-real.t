use warnings;
use strict;
use Test::More;
use DBIx::Perlish qw/:all/;
use t::test_utils;

eval "use DBD::SQLite;";
plan skip_all => "DBD::SQLite cannot be loaded" if $@;
eval "use DBD::PgLite 0.11;";
plan skip_all => "The right version of DBD::PgLite cannot be loaded" if $@;

eval "use PadWalker;";
plan skip_all => "PadWalker cannot be loaded" if $@;

plan tests => 97;

my $dbh = DBI->connect("dbi:PgLite:");
ok($dbh, "db connection");
ok($dbh->do("create table names (id integer, name text)"), "table create");
is(DBIx::Perlish::_get_flavor($dbh), "pglite", "correct flavor");

my $o = DBIx::Perlish->new(dbh => $dbh);

ok((db_insert 'names', { id => 1, name => "hello" }), "insert one");
ok((db_insert 'names', { id => 33, name => "smth/xx" }), "insert one more");
ok($o->insert('names', { id => 3, name => "ehlo" }), "obj: insert one");
is(scalar db_fetch { my $t : names; $t->id == 1; return $t->name; }, "hello", "fetch inserted");
is(scalar db_fetch { my $t : names; $t->name =~ /^h/; return $t->name; }, "hello", "fetch anchored regex");
is(scalar db_fetch { my $t : names; $t->name =~ /\//; return $t->name; }, "smth/xx", "fetch regex with /");
ok((db_delete { names->id == 33 }), "delete one now");

my $h = db_fetch { my $t : names; $t->id == 1; return -k $t->id, $t; };
ok($h, "fetch all hashref");
is($h->{1}{id},   1, "fetch all hashref key id");
is($h->{1}{name}, "hello", "fetch all hashref key name");
ok(!exists $h->{1}{'$kf-1'}, "fetch all hashref key kf not present");

my %h = db_fetch { my $t : names; $t->id == 1; return -k $t->id, $t; };
ok(%h, "fetch all hash");
ok($h{1},   "fetch all hash 1 present");
ok(!$h{3},  "fetch all hash 3 not present");
is($h{1}{id},   1, "fetch all hash key id");
is($h{1}{name}, "hello", "fetch all hash key name");
ok(!exists $h{1}{'$kf-1'}, "fetch all hash key kf not present");

%h = db_fetch { my $t : names; return -k $t->id, $t; };
ok(%h, "fetch all hash unfiltered");
ok($h{1},   "fetch all hash 1 present");
ok($h{3},   "fetch all hash 3 present");
ok(!$h{2},  "fetch all hash 2 not present");
is($h{1}{id},   1, "fetch all hash unfiltered 1 key id");
is($h{1}{name}, "hello", "fetch all hash unfiltered 1 key name");
is($h{3}{id},   3, "fetch all hash unfiltered 3 key id");
is($h{3}{name}, "ehlo", "fetch all hash unfiltered 3 key name");
ok(!exists $h{1}{'$kf-1'}, "fetch all hash unfiltered 1 kf not present");
ok(!exists $h{3}{'$kf-1'}, "fetch all hash unfiltered 1 kf not present");

%h = db_fetch { my $t : names; return -k $t->id, -k $t->name, $t; };
ok(%h, "fetch multi-key");
ok($h{1},   "multi-key 1 present");
ok($h{3},   "multi-key 3 present");
ok(!$h{2},  "multi-key 2 not present");
ok(!$h{hello},  "multi-key hello not present");
ok(!$h{ehlo},  "multi-key ehlo not present");
ok($h{1}{hello},   "multi-key 1/hello present");
ok($h{3}{ehlo},   "multi-key 3/ehlo present");
ok(!$h{1}{ehlo},   "multi-key 1/ehlo not present");
ok(!$h{3}{hello},   "multi-key 3/hello not present");
is($h{1}{hello}{id},   1, "multi-key 1/hello key id");
is($h{1}{hello}{name}, "hello", "multi-key 1/hello key name");
is($h{3}{ehlo}{id},   3, "multi-key 3/ehlo key id");
is($h{3}{ehlo}{name}, "ehlo", "multi-key 3/ehlo key name");
ok(!exists $h{1}{'$kf-1'}, "multi-key no key field");
ok(!exists $h{1}{'$kf-2'}, "multi-key no key field");
ok(!exists $h{3}{'$kf-1'}, "multi-key no key field");
ok(!exists $h{3}{'$kf-2'}, "multi-key no key field");
ok(!exists $h{1}{hello}{'$kf-1'}, "multi-key no key field");
ok(!exists $h{1}{hello}{'$kf-2'}, "multi-key no key field");
ok(!exists $h{3}{ehlo}{'$kf-1'}, "multi-key no key field");
ok(!exists $h{3}{ehlo}{'$kf-2'}, "multi-key no key field");

%h = db_fetch { my $t : names; return -k $t->id, $t->name; };
ok(%h, "fetch key flatten");
is($h{1}, "hello",  "key flatten 1 value");
is($h{3}, "ehlo",  "key flatten 3 value");

%h = db_fetch { my $t : names; return -k $t->id, -k $t->name, $t->name; };
ok(%h, "fetch multi-key flatten");
is($h{1}{hello}, "hello",  "key flatten 1/hello value");
is($h{3}{ehlo}, "ehlo",  "key flatten 3/ehlo value");

%h = db_fetch { my $t : names; return -k $t->id, $t->name, $t->id; };
ok(%h, "fetch key noflatten");
ok($h{1}, "key noflatten 1 present");
ok($h{3}, "key noflatten 3 present");
is($h{1}{id},   1, "key noflatten 1 key id");
is($h{1}{name}, "hello", "key noflatten 1 key name");
is($h{3}{id},   3, "key noflatten 3 key id");
is($h{3}{name}, "ehlo", "key noflatten 3 key name");

my $r = db_fetch { my $t : names; $t->id == 1 };
ok($r, "fetch hashref");
is($r->{id}, 1, "fetch hashref key 1");
is($r->{name}, "hello", "fetch hashref key 2");

my @n = db_fetch { my $t : names; return $t->name };
is(scalar(@n), 2, "fetch array one column");
is($n[0], "hello", "fetch array val 1");
is($n[1], "ehlo", "fetch array val 2");

@n = db_fetch { my $t : names };
is(scalar(@n), 2, "fetch array all");
is($n[0]->{id},   1, "fetch array all val 1/1");
is($n[0]->{name}, "hello", "fetch array all val 1/2");
is($n[1]->{id},   3, "fetch array all val 2/1");
is($n[1]->{name}, "ehlo", "fetch array all val 2/2");
@n = $o->fetch( sub { my $t : names });
is($o->sql, "select * from names t01", "obj: sql()");
is(scalar $o->bind_values, 0, "obj: bind_values()");

is(scalar $o->fetch(sub { my $t : names; $t->id == 1; return $t->name; }), "hello", "obj: fetch inserted");
is(scalar db_fetch { my $t : names; $t->id == 2; return $t->name; }, undef, "fetch non-existent");
ok((db_update { names->name = "aha"; exec }), "update all");
ok($o->update(sub { names->name = "behe"; exec }), "obj: update all");
@n = $o->bind_values;
is(scalar(@n), 1, "obj: update all bind_values count");
is($n[0], "behe", "obj: update all bind_values value");
is(scalar db_fetch { my $t : names; $t->id == 1; return $t->name; }, "behe", "fetch updated");
is(scalar db_select { my $t : names; $t->id == 1; return $t->name; }, "behe", "select updated");
ok((db_delete { names->id == 3 }), "delete one");
ok($o->delete(sub { names->id == 1 }), "obj: delete one");
is(scalar db_fetch { my $t : names; $t->id == 1; return $t->name; }, undef, "fetch deleted");

ok((db_insert 'names', { id => sql 5, name => "five" }), "insert with verbatim");

my $two = 2;
is(scalar db_fetch { return $two**12 }, 4096, "exponentiation");

# pglite sequences
is(scalar db_fetch { return next names_id_seq }, 6, "next works");

# just to bump up coverage - those red things annoy me
union     {}; pass("coverage: union");
intersect {}; pass("coverage: intersect");
except    {}; pass("coverage: except");
sql "haha"  ; pass("coverage: sql");

DBIx::Perlish::init($dbh);
is(scalar db_fetch { my $t : names; $t->id == 1; return $t->name; }, undef, "one more fetch deleted");
