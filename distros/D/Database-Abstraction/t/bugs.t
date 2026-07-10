#!perl -w

# Regression tests for bugs fixed during the July 2026 critique pass.
# Each subtest is tied to a specific defect so that future regressions
# are immediately traceable to the root cause.

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Test::Most;
use Test::NoWarnings;

eval { require DBI; require DBD::SQLite };
if($@) {
	plan skip_all => 'DBD::SQLite not available';
} else {
	plan tests => 29;
}

use lib 't/lib';

my $data_dir = File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');

# -------------------------------------------------------------------------
# BUG 1: Data::Reuse::fixate() parenthesis error
#   ref($self->{'data'} eq 'HASH') was always false, so fixate was never
#   called. After fix the outer AND inner hashes are locked. All in-memory
#   accesses must use exists() before dereferencing a locked key.
# -------------------------------------------------------------------------

use_ok('Database::test1');
my $t1 = new_ok('Database::test1' => [$data_dir]);

# Slurped data should be accessible without throwing on any key access
my $row = $t1->fetchrow_hashref(entry => 'one');
ok(defined($row), 'BUG1: fetchrow_hashref returns data from locked slurp hash');
is($row->{'number'}, 1, 'BUG1: locked hash value readable');

# Accessing a key that doesn't exist in the outer locked hash should return undef, not throw
my $missing = $t1->fetchrow_hashref(entry => 'nonexistent');
ok(!defined($missing), 'BUG1: missing outer key returns undef, not throw');

# AUTOLOAD on a missing entry should also return undef, not throw
my $n = $t1->number('nonexistent');
ok(!defined($n), 'BUG1: AUTOLOAD missing entry returns undef not exception');

# -------------------------------------------------------------------------
# BUG 2: execute() passed arrayref instead of list to DBI->execute()
#   $sth->execute($args->{args}) should be $sth->execute(@{$args->{'args'}})
#   Also: args => (30) (scalar) must be normalised to a list.
# -------------------------------------------------------------------------

{
	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'bugtest.sql');
	my $dsn  = "dbi:SQLite:dbname=$file";

	my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup->do(q{CREATE TABLE bugtest (id INTEGER PRIMARY KEY, score INTEGER)});
	$setup->do(q{INSERT INTO bugtest VALUES (1, 10)});
	$setup->do(q{INSERT INTO bugtest VALUES (2, 30)});
	$setup->do(q{INSERT INTO bugtest VALUES (3, 50)});
	$setup->disconnect();

	{
		package Database::bugtest;
		use base 'Database::Abstraction';
	}

	my $db = Database::bugtest->new(dsn => $dsn, no_entry => 1);

	# Arrayref form
	my @rows = $db->execute(query => 'SELECT * FROM bugtest WHERE score >= ?', args => [30]);
	is(scalar @rows, 2, 'BUG2: execute() with arrayref args works');

	# Scalar form (args => (30) flattens to scalar)
	@rows = $db->execute(query => 'SELECT * FROM bugtest WHERE score >= ?', args => 30);
	is(scalar @rows, 2, 'BUG2: execute() with scalar args works');

	# Multiple bind values (arrayref)
	@rows = $db->execute(query => 'SELECT * FROM bugtest WHERE score >= ? AND score <= ?', args => [10, 30]);
	is(scalar @rows, 2, 'BUG2: execute() with multiple bind values works');
}

# -------------------------------------------------------------------------
# BUG 3: AUTOLOAD scalar-context cache returned cache->set() result
#   cache->set() return value is undefined per CHI contract; must explicitly
#   return $rc after storing.
# -------------------------------------------------------------------------

SKIP: {
	eval { require CHI };
	skip 'CHI not available', 3 if $@;

	my $cache = CHI->new(driver => 'RawMemory', global => 0);
	my $t1c = Database::test1->new({ directory => $data_dir, cache => $cache, max_slurp_size => 0 });

	# First call (cache miss) must return the actual value, not undef
	my $val = $t1c->number('one');
	is($val, 1, 'BUG3: AUTOLOAD scalar first call returns value (not cache->set result)');

	# Second call (cache hit) must also return the value
	$val = $t1c->number('one');
	is($val, 1, 'BUG3: AUTOLOAD scalar cache hit returns value');

	# Confirm the key was actually cached
	is(scalar $cache->get_keys(), 1, 'BUG3: AUTOLOAD scalar cached exactly one key');
}

# -------------------------------------------------------------------------
# BUG 4: AUTOLOAD disabled check used boolean()->isFalse()
#   Now just uses !$self->{'auto_load'}.  Test that auto_load => 0 works.
# -------------------------------------------------------------------------

{
	package Database::noauto;
	use base 'Database::Abstraction';
}

my $noa = Database::noauto->new(directory => $data_dir, auto_load => 0);
throws_ok { $noa->number('one') } qr/AUTOLOAD disabled/i, 'BUG4: auto_load => 0 croaks with right message';

# -------------------------------------------------------------------------
# BUG 5: die in XML slurp path — should be croak, and should mention the
#   right structure type.
# -------------------------------------------------------------------------

# We can't easily trigger the XML die paths without crafting XML files,
# so we test that the XML success path still works (regression guard).
use_ok('Database::test3');
my $t3 = Database::test3->new(directory => $data_dir);
ok(defined($t3), 'BUG5: XML load still works after die->croak fix');

# -------------------------------------------------------------------------
# BUG 6: AUTOLOAD list-context query used hardcoded 'entry' instead of id
#   When the key column is overridden with 'id', the CSV guard must use
#   that column name, not the string literal 'entry'.
# -------------------------------------------------------------------------

use_ok('Database::test5');
my $t5 = Database::test5->new(directory => $data_dir);

# In list context AUTOLOAD builds a SELECT with the correct id column guard
my @names = $t5->name();
is(scalar @names, 5, 'BUG6: AUTOLOAD list context with custom id column returns 5 rows');

# -------------------------------------------------------------------------
# BUG 7: In-memory scan in selectall_arrayref / selectall_array
#   When data is slurped, simple (non-entry) criteria used to fall through
#   to SQL. Now they are matched in-memory via _match_criterion.
# -------------------------------------------------------------------------

# Filter by a non-key column in slurped data
my $matches = $t1->selectall_arrayref(number => 2);
ok(defined($matches) && ref($matches) eq 'ARRAY', 'BUG7: selectall_arrayref in-memory scan returns arrayref');
is(scalar @{$matches}, 1, 'BUG7: in-memory scan finds exactly 1 match');
is($matches->[0]{'entry'}, 'two', 'BUG7: in-memory scan returns the right row');

# Make sure no-match returns empty arrayref (not undef)
my $none = $t1->selectall_arrayref(number => 999);
ok(defined($none) && ref($none) eq 'ARRAY', 'BUG7: in-memory scan no-match returns arrayref');
is(scalar @{$none}, 0, 'BUG7: in-memory scan no-match returns empty arrayref');

# selectall_array in-memory scan
my @arr = $t1->selectall_array(number => 1);
is(scalar @arr, 1, 'BUG7: selectall_array in-memory scan returns 1 row');
is($arr[0]{'entry'}, 'one', 'BUG7: selectall_array in-memory scan correct row');

# -------------------------------------------------------------------------
# BUG 8: logger validation in new() rejected valid code-ref loggers
#   Now non-object loggers are normalised through Log::Abstraction.
# -------------------------------------------------------------------------

my @log_messages;
my $logger_sub = sub { push @log_messages, join('', @_) };

# This must not throw — before the fix it would croak because the coderef
# is not a blessed object with info()/error() methods.
my $logged_db;
lives_ok {
	$logged_db = Database::test1->new({ directory => $data_dir, logger => $logger_sub });
} 'BUG8: code-ref logger accepted in new()';
ok(defined($logged_db), 'BUG8: object created with code-ref logger');

# -------------------------------------------------------------------------
# BUG 9: Column name SQL injection guard in _build_where_conditions
# -------------------------------------------------------------------------

{
	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'injtest.sql');
	my $dsn  = "dbi:SQLite:dbname=$file";

	my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup->do(q{CREATE TABLE injtest (id INTEGER PRIMARY KEY, val TEXT)});
	$setup->do(q{INSERT INTO injtest VALUES (1, 'a')});
	$setup->disconnect();

	{
		package Database::injtest;
		use base 'Database::Abstraction';
	}

	my $db = Database::injtest->new(dsn => $dsn, no_entry => 1);

	# A valid column name works normally
	lives_ok { $db->selectall_arrayref(val => 'a') } 'BUG9: valid column name is accepted';

	# An unsafe column name (SQL injection attempt) must croak
	throws_ok {
		$db->selectall_arrayref('val; DROP TABLE injtest--' => 'x')
	} qr/unsafe column name/i, 'BUG9: SQL injection in column name is rejected';
}
