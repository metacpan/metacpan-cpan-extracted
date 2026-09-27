#!perl -w

use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec;
use Test::Most tests => 24;
use Test::NoWarnings;

use lib 't/lib';
use Database::numerictest;

pass('Database::numerictest loaded');

my $directory = File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');

# ---------------------------------------------------------------------------
# SN1/SN2: schema() with infer_types reports correct numeric types
# ---------------------------------------------------------------------------
my $db = Database::numerictest->new({ directory => $directory, infer_types => 1 });
isa_ok($db, 'Database::numerictest', 'SN1: object created with infer_types');

my $schema = $db->schema();
is($schema->{'score'}{'type'},  'REAL',    'SN1: score column inferred as REAL');
is($schema->{'id_num'}{'type'}, 'INTEGER', 'SN2: id_num column inferred as INTEGER');

# ---------------------------------------------------------------------------
# SN3: REAL equality via public API (slurp fast-path)
#   CSV value '1.0' must match integer criterion 1.
#   String comparison: '1.0' ne '1' → no match (wrong).
#   Numeric comparison: 1.0 == 1 → match (correct).
# ---------------------------------------------------------------------------
my @rows = $db->selectall_array(score => 1);
cmp_ok(scalar @rows, '==', 1, 'SN3: REAL equality finds row where CSV has 1.0');
is($rows[0]{'entry'}, 'a', 'SN3: correct entry returned');

# fetchrow_hashref fast-track also honours numeric equality
my $frow = $db->fetchrow_hashref(score => 1);
ok(defined $frow, 'SN3: fetchrow_hashref finds row via REAL equality');
is($frow->{'entry'}, 'a', 'SN3: fetchrow_hashref returns correct entry');

# ---------------------------------------------------------------------------
# SN4: INTEGER equality via public API (slurp fast-path)
#   CSV value '001' must match integer criterion 1.
#   String comparison: '001' ne '1' → no match (wrong).
#   Numeric comparison: 001 == 1 → match (correct).
# ---------------------------------------------------------------------------
my @irows = $db->selectall_array(id_num => 1);
cmp_ok(scalar @irows, '==', 1, 'SN4: INTEGER equality finds row where CSV has 001');
is($irows[0]{'entry'}, 'a', 'SN4: correct entry returned');

# count() also uses the same slurp scan
cmp_ok($db->count(id_num => 1), '==', 1, 'SN4: count() with INTEGER equality');

# ---------------------------------------------------------------------------
# SN5: _match_criterion white-box — numeric equality for REAL
#   Tests the hashref-operator branch (unreachable via public API but
#   exercised here to verify the numeric gate is wired correctly).
# ---------------------------------------------------------------------------
my $schema_ref = { score => { type => 'REAL' } };
{
	# Temporarily install a schema to test type-aware path directly
	local $db->{'_schema'} = $schema_ref;

	ok( $db->_match_criterion('1.0', 1,   'score'), 'SN5: REAL == matches 1.0 to 1');
	ok(!$db->_match_criterion('1.0', 2,   'score'), 'SN5: REAL == no-match 1.0 vs 2');
	ok( $db->_match_criterion('1.0', { '-in' => [1, 3] },  'score'), 'SN5: REAL -in numeric');
	ok(!$db->_match_criterion('1.0', { '-in' => [2, 3] },  'score'), 'SN5: REAL -in miss');
	ok(!$db->_match_criterion('1.0', { '-not_in' => [1] }, 'score'), 'SN5: REAL -not_in excludes 1.0');
	ok( $db->_match_criterion('1.0', { '-not_in' => [2] }, 'score'), 'SN5: REAL -not_in keeps 1.0');
	ok(!$db->_match_criterion('2.0', { '!=' => 2 }, 'score'), 'SN5: REAL != excludes 2.0 == 2');
	ok( $db->_match_criterion('1.0', { '!=' => 2 }, 'score'), 'SN5: REAL != keeps 1.0 != 2');
}

# ---------------------------------------------------------------------------
# SN6: without schema() populated, string comparison is used
#   A freshly constructed object (no schema() call) uses string semantics.
# ---------------------------------------------------------------------------
my $db2 = Database::numerictest->new({ directory => $directory, infer_types => 1 });
# Force slurp by running a count, without calling schema()
$db2->count();
ok(!$db2->{'_schema'}, 'SN6: schema not yet populated on fresh object');

my @no_schema = $db2->selectall_array(score => 1);
# '1.0' ne '1' → no match under string comparison
cmp_ok(scalar @no_schema, '==', 0,
	'SN6: without schema cache, string eq finds no match for 1.0==1');

# After populating the schema, the same query finds the row
$db2->schema();
ok($db2->{'_schema'}, 'SN6: schema now cached');
my @with_schema = $db2->selectall_array(score => 1);
cmp_ok(scalar @with_schema, '==', 1,
	'SN6: after schema() call, numeric eq finds the row');
