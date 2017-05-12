use strict;
use warnings;
use Test::More;


BEGIN {
    eval "use DBD::SQLite";
    plan $@
      ? ( skip_all => 'needs DBD::SQLite for testing' )
      : ( tests => 9 );
	$DBD::SQLite::sqlite_version; # get rid of warnings
}

use lib 't/lib';

use_ok('DBIx::Class::OptimisticLocking');

use_ok( 'OLTest' );

use_ok( 'OLTest::Schema' );

my $s = OLTest->init_schema();

my $r1 = $s->resultset('TestDirty')->new({
	col1 => 'a',
	col2 => 'a',
	col3 => 'a',
});
$r1->insert;

my $r2 = $s->resultset('TestDirty')->find($r1->id);
is($r1->id, $r2->id, 'retrieved identical object');
$r1->col1('b');
$r2->col1('c');
$r1->update;

# this will fail because $r2->col1 doesn't match the database anymore
eval { $r2->update };
ok($@,'error expected');

$r2 = $s->resultset('TestDirty')->find($r1->id);
$r2->col1('c');
$r2->update;
is($r2->col1,'c', 'update succeeded');

$r1->col2('b');
$r1->update;
is($r1->col2, 'b', "different column updates don't clash");

$r1->discard_changes;
$r1->col1('d');
$r1->col1('e');
eval { $r1->update };
ok(!$@, 'no error expected on multiple sets before an update');
is($r1->col1, 'e', 'second value stored appropriately');
