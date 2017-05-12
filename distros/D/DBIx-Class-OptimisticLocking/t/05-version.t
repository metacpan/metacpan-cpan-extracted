use strict;
use warnings;
use Test::More;


BEGIN {
    eval "use DBD::SQLite";
    plan $@
      ? ( skip_all => 'needs DBD::SQLite for testing' )
      : ( tests => 12 );
    $DBD::SQLite::sqlite_version; # get rid of warnings
}

use lib 't/lib';

use_ok('DBIx::Class::OptimisticLocking');

use_ok( 'OLTest' );

use_ok( 'OLTest::Schema' );

my $s = OLTest->init_schema();

my $r1 = $s->resultset('TestVersion')->new({
	col1 => 'a',
	col2 => 'a',
});
$r1->insert;
$r1->discard_changes;
is($r1->version, 0, 'version at 0');

my $r2 = $s->resultset('TestVersion')->find($r1->id);
is($r1->id, $r2->id, 'retrieved identical object');

$r1->col1('b');
$r2->col2('c');
$r1->update;
$r1->discard_changes;

is($r1->version, 1, 'version incremented');

$r1->update;
$r1->discard_changes;
is($r1->version, 1, 'version not incremented when update is not executed');

# fails because $r2's version is behind $r1's version
eval {$r2->update};
ok($@,'error expected, version mismatch');

$r2 = $s->resultset('TestVersion')->find($r1->id);
$r2->col2('d');
$r2->update;
$r2->discard_changes;
is($r2->version, 2, 'version incremented');
is($r2->col2,'d', 'update succeeded after refresh');

$r1->col2('d');
eval { $r1->update; };
ok($@, 'error expected even on identical update because version did not match');
$r1->discard_changes;
is($r1->version, 2, 'version remains on error');
