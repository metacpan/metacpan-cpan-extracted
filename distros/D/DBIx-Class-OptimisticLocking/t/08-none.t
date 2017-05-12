use strict;
use warnings;
use Test::More;


BEGIN {
    eval "use DBD::SQLite";
    plan $@
      ? ( skip_all => 'needs DBD::SQLite for testing' )
      : ( tests => 6 );
    $DBD::SQLite::sqlite_version; # get rid of warnings
}

use lib 't/lib';

use_ok('DBIx::Class::OptimisticLocking');

use_ok( 'OLTest' );

use_ok( 'OLTest::Schema' );

my $s = OLTest->init_schema();

OLTest::Schema::TestDirty->optimistic_locking_strategy('none');
is(OLTest::Schema::TestDirty->optimistic_locking_strategy, 'none', 'strategy set to "none"');

my $r1 = $s->resultset('TestDirty')->new({
	col1 => 'a',
	col2 => 'a',
	col3 => 'a'
});
$r1->insert;
$r1->discard_changes;

my $r2 = $s->resultset('TestDirty')->find($r1->id);

$r1->col1('b');
$r2->col1('c');
$r1->update;
eval {$r2->update};
ok(!$@, 'no error thrown on conflicting update when mode set to "none"');
$r1->discard_changes;

is($r1->col1, 'c', 'second update succeeded');
