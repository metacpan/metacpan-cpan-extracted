use Test::More tests => 257;
use Basset::Object::Persistent;
package Basset::Object::Persistent;
{		Test::More::ok(1, "uses strict");
		Test::More::ok(1, "uses warnings");
};
{#line 74 loaded
my $o = Basset::Object::Persistent->new();
Test::More::ok($o, "Got object");
Test::More::is(scalar(Basset::Object::Persistent->loaded), undef, "could not call object method as class method");
Test::More::is(Basset::Object::Persistent->errcode, "BO-08", "proper error code");
Test::More::is(scalar($o->loaded), 0, 'loaded is 0');
Test::More::is($o->loaded('abc'), 'abc', 'set loaded to abc');
Test::More::is($o->loaded(), 'abc', 'read value of loaded - abc');
my $h = {};
Test::More::ok($h, 'got hashref');
Test::More::is($o->loaded($h), $h, 'set loaded to hashref');
Test::More::is($o->loaded(), $h, 'read value of loaded  - hashref');
my $a = [];
Test::More::ok($a, 'got arrayref');
Test::More::is($o->loaded($a), $a, 'set loaded to arrayref');
Test::More::is($o->loaded(), $a, 'read value of loaded  - arrayref');
};
{#line 110 loading
my $o = Basset::Object::Persistent->new();
Test::More::ok($o, "Got object");
Test::More::is(scalar(Basset::Object::Persistent->loading), undef, "could not call object method as class method");
Test::More::is(Basset::Object::Persistent->errcode, "BO-08", "proper error code");
Test::More::is(scalar($o->loading), 0, 'loading is 0');
Test::More::is($o->loading('abc'), 'abc', 'set loading to abc');
Test::More::is($o->loading(), 'abc', 'read value of loading - abc');
my $h = {};
Test::More::ok($h, 'got hashref');
Test::More::is($o->loading($h), $h, 'set loading to hashref');
Test::More::is($o->loading(), $h, 'read value of loading  - hashref');
my $a = [];
Test::More::ok($a, 'got arrayref');
Test::More::is($o->loading($a), $a, 'set loading to arrayref');
Test::More::is($o->loading(), $a, 'read value of loading  - arrayref');
};
{#line 145 committing
my $o = Basset::Object::Persistent->new();
Test::More::ok($o, "Got object");
Test::More::is(scalar(Basset::Object::Persistent->committing), undef, "could not call object method as class method");
Test::More::is(Basset::Object::Persistent->errcode, "BO-08", "proper error code");
Test::More::is(scalar($o->committing), 0, 'committing is 0');
Test::More::is($o->committing('abc'), 'abc', 'set committing to abc');
Test::More::is($o->committing(), 'abc', 'read value of committing - abc');
my $h = {};
Test::More::ok($h, 'got hashref');
Test::More::is($o->committing($h), $h, 'set committing to hashref');
Test::More::is($o->committing(), $h, 'read value of committing  - hashref');
my $a = [];
Test::More::ok($a, 'got arrayref');
Test::More::is($o->committing($a), $a, 'set committing to arrayref');
Test::More::is($o->committing(), $a, 'read value of committing  - arrayref');
};
{#line 189 committed
my $o = Basset::Object::Persistent->new();
Test::More::ok($o, "Got object");
Test::More::is(scalar(Basset::Object::Persistent->committed), undef, "could not call object method as class method");
Test::More::is(Basset::Object::Persistent->errcode, "BO-08", "proper error code");
Test::More::is(scalar($o->committed), 0, 'committed is 0');
Test::More::is($o->committed('abc'), 'abc', 'set committed to abc');
Test::More::is($o->committed(), 'abc', 'read value of committed - abc');
my $h = {};
Test::More::ok($h, 'got hashref');
Test::More::is($o->committed($h), $h, 'set committed to hashref');
Test::More::is($o->committed(), $h, 'read value of committed  - hashref');
my $a = [];
Test::More::ok($a, 'got arrayref');
Test::More::is($o->committed($a), $a, 'set committed to arrayref');
Test::More::is($o->committed(), $a, 'read value of committed  - arrayref');
};
{#line 224 deleting
my $o = Basset::Object::Persistent->new();
Test::More::ok($o, "Got object");
Test::More::is(scalar(Basset::Object::Persistent->deleting), undef, "could not call object method as class method");
Test::More::is(Basset::Object::Persistent->errcode, "BO-08", "proper error code");
Test::More::is(scalar($o->deleting), 0, 'deleting is 0');
Test::More::is($o->deleting('abc'), 'abc', 'set deleting to abc');
Test::More::is($o->deleting(), 'abc', 'read value of deleting - abc');
my $h = {};
Test::More::ok($h, 'got hashref');
Test::More::is($o->deleting($h), $h, 'set deleting to hashref');
Test::More::is($o->deleting(), $h, 'read value of deleting  - hashref');
my $a = [];
Test::More::ok($a, 'got arrayref');
Test::More::is($o->deleting($a), $a, 'set deleting to arrayref');
Test::More::is($o->deleting(), $a, 'read value of deleting  - arrayref');
};
{#line 269 deleted
my $o = Basset::Object::Persistent->new();
Test::More::ok($o, "Got object");
Test::More::is(scalar(Basset::Object::Persistent->deleted), undef, "could not call object method as class method");
Test::More::is(Basset::Object::Persistent->errcode, "BO-08", "proper error code");
Test::More::is(scalar($o->deleted), 0, 'deleted is 0');
Test::More::is($o->deleted('abc'), 'abc', 'set deleted to abc');
Test::More::is($o->deleted(), 'abc', 'read value of deleted - abc');
my $h = {};
Test::More::ok($h, 'got hashref');
Test::More::is($o->deleted($h), $h, 'set deleted to hashref');
Test::More::is($o->deleted(), $h, 'read value of deleted  - hashref');
my $a = [];
Test::More::ok($a, 'got arrayref');
Test::More::is($o->deleted($a), $a, 'set deleted to arrayref');
Test::More::is($o->deleted(), $a, 'read value of deleted  - arrayref');
};
{#line 346 iterator
my $o = Basset::Object::Persistent->new();
Test::More::ok($o, "Got object");
Test::More::is(scalar($o->iterator), undef, 'iterator is undefined');
Test::More::is($o->iterator('abc'), 'abc', 'set iterator to abc');
Test::More::is($o->iterator(), 'abc', 'read value of iterator - abc');
my $h = {};
Test::More::ok($h, 'got hashref');
Test::More::is($o->iterator($h), $h, 'set iterator to hashref');
Test::More::is($o->iterator(), $h, 'read value of iterator  - hashref');
my $a = [];
Test::More::ok($a, 'got arrayref');
Test::More::is($o->iterator($a), $a, 'set iterator to arrayref');
Test::More::is($o->iterator(), $a, 'read value of iterator  - arrayref');
};
{#line 480 init
my $o = Basset::Object::Persistent->new();
Test::More::ok($o, "got object for init");

Test::More::is($o->loading, 0, "loading is 0");
Test::More::is($o->loaded, 0, "loaded is 0");
Test::More::is($o->committing, 0, "committing is 0");
Test::More::is($o->committed, 0, "committed is 0");
Test::More::is($o->deleting, 0, "deleting is 0");
Test::More::is($o->deleted, 0, "deleted is 0");
Test::More::is(ref($o->instantiated_relationships), 'HASH', 'instantiated_relationships is hashref');
Test::More::is($o->tied_to_parent, 0, 'tied_to_parent is 0');
Test::More::is($o->should_be_committed, 0, 'should_be_committed is 0');
Test::More::is($o->should_be_deleted, 0, 'should_be_committed is 0');
Test::More::is(ref($o->_deleted_relationships), 'ARRAY', '_deleted_relationships is arrayref');
};
{#line 796 should_be_deleted
my $o = Basset::Object::Persistent->new();
Test::More::ok($o, "Got object");
Test::More::is(scalar(Basset::Object::Persistent->should_be_deleted), undef, "could not call object method as class method");
Test::More::is(Basset::Object::Persistent->errcode, "BO-08", "proper error code");
Test::More::is(scalar($o->should_be_deleted), 0, 'should_be_deleted is 0');
Test::More::is($o->should_be_deleted('abc'), 'abc', 'set should_be_deleted to abc');
Test::More::is($o->should_be_deleted(), 'abc', 'read value of should_be_deleted - abc');
my $h = {};
Test::More::ok($h, 'got hashref');
Test::More::is($o->should_be_deleted($h), $h, 'set should_be_deleted to hashref');
Test::More::is($o->should_be_deleted(), $h, 'read value of should_be_deleted  - hashref');
my $a = [];
Test::More::ok($a, 'got arrayref');
Test::More::is($o->should_be_deleted($a), $a, 'set should_be_deleted to arrayref');
Test::More::is($o->should_be_deleted(), $a, 'read value of should_be_deleted  - arrayref');
};
{#line 830 should_be_committed
my $o = Basset::Object::Persistent->new();
Test::More::ok($o, "Got object");
Test::More::is(scalar(Basset::Object::Persistent->should_be_committed), undef, "could not call object method as class method");
Test::More::is(Basset::Object::Persistent->errcode, "BO-08", "proper error code");
Test::More::is(scalar($o->should_be_committed), 0, 'should_be_committed is zero');
Test::More::is($o->should_be_committed('abc'), 'abc', 'set should_be_committed to abc');
Test::More::is($o->should_be_committed(), 'abc', 'read value of should_be_committed - abc');
my $h = {};
Test::More::ok($h, 'got hashref');
Test::More::is($o->should_be_committed($h), $h, 'set should_be_committed to hashref');
Test::More::is($o->should_be_committed(), $h, 'read value of should_be_committed  - hashref');
my $a = [];
Test::More::ok($a, 'got arrayref');
Test::More::is($o->should_be_committed($a), $a, 'set should_be_committed to arrayref');
Test::More::is($o->should_be_committed(), $a, 'read value of should_be_committed  - arrayref');
};
{#line 866 instantiated_relationships
my $o = Basset::Object::Persistent->new();
Test::More::ok($o, "Got object");
Test::More::is(scalar(Basset::Object::Persistent->instantiated_relationships), undef, "could not call object method as class method");
Test::More::is(Basset::Object::Persistent->errcode, "BO-08", "proper error code");
Test::More::is(ref(scalar($o->instantiated_relationships)), 'HASH', 'instantiated_relationships is hashref');
Test::More::is($o->instantiated_relationships('abc'), 'abc', 'set instantiated_relationships to abc');
Test::More::is($o->instantiated_relationships(), 'abc', 'read value of instantiated_relationships - abc');
my $h = {};
Test::More::ok($h, 'got hashref');
Test::More::is($o->instantiated_relationships($h), $h, 'set instantiated_relationships to hashref');
Test::More::is($o->instantiated_relationships(), $h, 'read value of instantiated_relationships  - hashref');
my $a = [];
Test::More::ok($a, 'got arrayref');
Test::More::is($o->instantiated_relationships($a), $a, 'set instantiated_relationships to arrayref');
Test::More::is($o->instantiated_relationships(), $a, 'read value of instantiated_relationships  - arrayref');
};
{#line 917 _deleted_relationships
my $o = Basset::Object::Persistent->new();
Test::More::ok($o, "Got object");
Test::More::is(scalar(Basset::Object::Persistent->_deleted_relationships), undef, "could not call object method as class method");
Test::More::is(Basset::Object::Persistent->errcode, "BO-08", "proper error code");
Test::More::is(ref(scalar($o->_deleted_relationships)), 'ARRAY', '_deleted_relationships is arrayref');
Test::More::is($o->_deleted_relationships('abc'), 'abc', 'set _deleted_relationships to abc');
Test::More::is($o->_deleted_relationships(), 'abc', 'read value of _deleted_relationships - abc');
my $h = {};
Test::More::ok($h, 'got hashref');
Test::More::is($o->_deleted_relationships($h), $h, 'set _deleted_relationships to hashref');
Test::More::is($o->_deleted_relationships(), $h, 'read value of _deleted_relationships  - hashref');
my $a = [];
Test::More::ok($a, 'got arrayref');
Test::More::is($o->_deleted_relationships($a), $a, 'set _deleted_relationships to arrayref');
Test::More::is($o->_deleted_relationships(), $a, 'read value of _deleted_relationships  - arrayref');
};
{#line 2080 writable_method
Test::More::is(scalar(Basset::Object::Persistent->writable_method), undef, "Cannot determine if writable on a class");
Test::More::is(Basset::Object::Persistent->errcode, "BOP-62", "proper error code");

my $subclass = "Basset::Test::Testing::Basset::Object::Persistent::writable_method::Subclass1";

package Basset::Test::Testing::Basset::Object::Persistent::writable_method::Subclass1;
our @ISA = qw(Basset::Object::Persistent);

$subclass->add_attr('one');
$subclass->add_attr('two');
$subclass->add_attr('three');

package Basset::Object::Persistent;

my $o = $subclass->new();
Test::More::ok($o, "Got object");

Test::More::is(scalar($o->writable_method), undef, "Cannot determine if writable w/o method");
Test::More::is($o->errcode, "BOP-63", "proper error code");

Test::More::is(scalar($o->writable_method('one')), undef, "Cannot determine if writable w/o primary table");
Test::More::is($o->errcode, 'BOP-64', "proper error code");

$subclass->add_primarytable(
	'name' => 'test_table',
	'definition' => {
		'one' => 'SQL_INTEGER',
		'two' => 'SQL_INTEGER',
		'three' => 'SQL_INTEGER',
	},
	#'insert_columns' => ['two'],
	#'update_columns' => ['three'],
);

Test::More::is($o->writable_method('one'), 1, "method is writable w/o insert or update columns on insert");
Test::More::is($o->loaded(1), 1, 'loaded is one');
Test::More::is($o->writable_method('one'), 1, "method is writable w/o insert or update columns on update, loaded");
Test::More::is($o->loaded(0), 0, 'loaded is zero');
Test::More::is($o->committed(1), 1, 'committed is 1');
Test::More::is($o->writable_method('one'), 1, "method is writable w/o insert or update columns on update, committed");
Test::More::is($o->loaded(1), 1, 'loaded is 1');
Test::More::is($o->committed(1), 1, 'committed is 1');
Test::More::is($o->writable_method('one'), 1, "method is writable w/o insert or update columns on insert, force_insert");
Test::More::is($o->loaded(0), 0, 'loaded is 0');
Test::More::is($o->committed(0), 0, 'committed is 0');
Test::More::is($o->writable_method('one'), 1, "method is writable w/o insert or update columns on insert, force_insert");

$subclass->add_primarytable(
	'name' => 'test_table',
	'definition' => {
		'one' => 'SQL_INTEGER',
		'two' => 'SQL_INTEGER',
		'three' => 'SQL_INTEGER',
	},
	'insert_columns' => ['two'],
	'update_columns' => ['three'],
);

Test::More::is($o->writable_method('one'), 0, "method one is not writable w/ insert and update columns on insert");
Test::More::is($o->loaded(1), 1, 'loaded is 1');
Test::More::is($o->writable_method('one'), 0, "method one is not writable w/ insert and update columns on update, loaded");
Test::More::is($o->loaded(0), 0, 'loaded is zero');
Test::More::is($o->committed(1), 1, 'committed is 1');
Test::More::is($o->writable_method('one'), 0, "method one is not writable w/ insert and update columns on update, committed");
Test::More::is($o->loaded(1), 1, 'loaded is 1');
Test::More::is($o->committed(1), 1, 'committed is 1');
Test::More::is($o->force_insert(1), 1, 'force_insert is 1');
Test::More::is($o->writable_method('one'), 0, "method one is not writable w/ insert and update columns on insert, force_insert");
Test::More::is($o->loaded(0), 0, 'loaded is 0');
Test::More::is($o->committed(0), 0, 'committed is 0');
Test::More::is($o->writable_method('one'), 0, "method one is not writable w/ insert and update columns on insert, force_insert");
Test::More::is($o->force_insert(0), 0, 'force_insert is 0');

Test::More::is($o->writable_method('two'), 1, "method two is writable w/ insert and update columns on insert");
Test::More::is($o->loaded(1), 1, 'loaded is 1');
Test::More::is($o->writable_method('two'), 0, "method two is not writable w/ insert and update columns on update, loaded");
Test::More::is($o->loaded(0), 0, 'loaded is zero');
Test::More::is($o->committed(1), 1, 'committed is 1');
Test::More::is($o->writable_method('two'), 0, "method two is not writable w/ insert and update columns on update, committed");
Test::More::is($o->loaded(1), 1, 'loaded is 1');
Test::More::is($o->committed(1), 1, 'committed is 1');
Test::More::is($o->force_insert(1), 1, 'force_insert is 1');
Test::More::is($o->writable_method('two'), 1, "method two is writable w/ insert and update columns on insert, force_insert");
Test::More::is($o->loaded(0), 0, 'loaded is 0');
Test::More::is($o->committed(0), 0, 'committed is 0');
Test::More::is($o->writable_method('two'), 1, "method two is writable w/ insert and update columns on insert, force_insert");
Test::More::is($o->force_insert(0), 0, 'force_insert is 0');

Test::More::is($o->writable_method('three'), 0, "method three is not writable w/ insert and update columns on insert");
Test::More::is($o->loaded(1), 1, 'loaded is 1');
Test::More::is($o->writable_method('three'), 1, "method three is writable w/ insert and update columns on update, loaded");
Test::More::is($o->loaded(0), 0, 'loaded is zero');
Test::More::is($o->committed(1), 1, 'committed is 1');
Test::More::is($o->writable_method('three'), 1, "method three is writable w/ insert and update columns on update, committed");
Test::More::is($o->loaded(1), 1, 'loaded is 1');
Test::More::is($o->committed(1), 1, 'committed is 1');
Test::More::is($o->force_insert(1), 1, 'force_insert is 1');
Test::More::is($o->writable_method('three'), 0, "method three is not writable w/ insert and update columns on insert, force_insert");
Test::More::is($o->loaded(0), 0, 'loaded is 0');
Test::More::is($o->committed(0), 0, 'committed is 0');
Test::More::is($o->writable_method('three'), 0, "method three is not writable w/ insert and update columns on insert, force_insert");
Test::More::is($o->force_insert(0), 0, 'force_insert is 0');

$subclass->add_primarytable(
	'name' => 'test_table',
	'definition' => {
		'alpha' => 'SQL_INTEGER',
		'beta' => 'SQL_INTEGER',
		'gamma' => 'SQL_INTEGER',
	},
	'insert_columns' => ['beta'],
	'update_columns' => ['gamma'],
	'column_aliases' => {
		'alpha' => 'one',
		'beta' => 'two',
		'gamma' => 'three',
	},
);

Test::More::is($o->writable_method('one'), 0, "method one (from alpha) is not writable w/ insert and update columns on insert");
Test::More::is($o->loaded(1), 1, 'loaded is 1');
Test::More::is($o->writable_method('one'), 0, "method one (from alpha) is not writable w/ insert and update columns on update, loaded");
Test::More::is($o->loaded(0), 0, 'loaded is zero');
Test::More::is($o->committed(1), 1, 'committed is 1');
Test::More::is($o->writable_method('one'), 0, "method one (from alpha) is not writable w/ insert and update columns on update, committed");
Test::More::is($o->loaded(1), 1, 'loaded is 1');
Test::More::is($o->committed(1), 1, 'committed is 1');
Test::More::is($o->force_insert(1), 1, 'force_insert is 1');
Test::More::is($o->writable_method('one'), 0, "method one (from alpha) is not writable w/ insert and update columns on insert, force_insert");
Test::More::is($o->loaded(0), 0, 'loaded is 0');
Test::More::is($o->committed(0), 0, 'committed is 0');
Test::More::is($o->writable_method('one'), 0, "method one (from alpha) is not writable w/ insert and update columns on insert, force_insert");
Test::More::is($o->force_insert(0), 0, 'force_insert is 0');

Test::More::is($o->writable_method('two'), 1, "method two (from beta) is writable w/ insert and update columns on insert");
Test::More::is($o->loaded(1), 1, 'loaded is 1');
Test::More::is($o->writable_method('two'), 0, "method two (from beta) is not writable w/ insert and update columns on update, loaded");
Test::More::is($o->loaded(0), 0, 'loaded is zero');
Test::More::is($o->committed(1), 1, 'committed is 1');
Test::More::is($o->writable_method('two'), 0, "method two (from beta) is not writable w/ insert and update columns on update, committed");
Test::More::is($o->loaded(1), 1, 'loaded is 1');
Test::More::is($o->committed(1), 1, 'committed is 1');
Test::More::is($o->force_insert(1), 1, 'force_insert is 1');
Test::More::is($o->writable_method('two'), 1, "method two (from beta) is writable w/ insert and update columns on insert, force_insert");
Test::More::is($o->loaded(0), 0, 'loaded is 0');
Test::More::is($o->committed(0), 0, 'committed is 0');
Test::More::is($o->writable_method('two'), 1, "method two (from beta) is writable w/ insert and update columns on insert, force_insert");
Test::More::is($o->force_insert(0), 0, 'force_insert is 0');

Test::More::is($o->writable_method('three'), 0, "method three (from gamma) is not writable w/ insert and update columns on insert");
Test::More::is($o->loaded(1), 1, 'loaded is 1');
Test::More::is($o->writable_method('three'), 1, "method three (from gamma) is writable w/ insert and update columns on update, loaded");
Test::More::is($o->loaded(0), 0, 'loaded is zero');
Test::More::is($o->committed(1), 1, 'committed is 1');
Test::More::is($o->writable_method('three'), 1, "method three (from gamma) is writable w/ insert and update columns on update, committed");
Test::More::is($o->loaded(1), 1, 'loaded is 1');
Test::More::is($o->committed(1), 1, 'committed is 1');
Test::More::is($o->force_insert(1), 1, 'force_insert is 1');
Test::More::is($o->writable_method('three'), 0, "method three (from gamma) is not writable w/ insert and update columns on insert, force_insert");
Test::More::is($o->loaded(0), 0, 'loaded is 0');
Test::More::is($o->committed(0), 0, 'committed is 0');
Test::More::is($o->writable_method('three'), 0, "method three (from gamma) is not writable w/ insert and update columns on insert, force_insert");
Test::More::is($o->force_insert(0), 0, 'force_insert is 0');
};
{#line 3355 fatalerror
my $o = Basset::Object::Persistent->new();
Test::More::ok($o, "got object");

Test::More::is($o->committing(1), 1, "set committing to 1");
Test::More::is($o->deleting(1), 1, "set deleting to 1");

Test::More::is(scalar($o->fatalerror("fatalerror", "some code")), undef, "set fatalerror");
Test::More::is($o->errcode, "some code", "proper error code");
Test::More::is($o->committing, 0, "wiped out committing flag");
Test::More::is($o->deleting, 0, "wiped out deleting flag");

Test::More::is(scalar(Basset::Object::Persistent->fatalerror("pkg error", "pkg error code")), undef, "set pkg error");
Test::More::is(Basset::Object::Persistent->errcode, "pkg error code", "proper package error code");
Test::More::is($o->errcode, "some code", "object retains error code");
};
