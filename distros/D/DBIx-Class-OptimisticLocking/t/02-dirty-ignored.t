use strict;
use warnings;
use Test::More;


BEGIN {
    eval "use DBD::SQLite";
    plan $@
      ? ( skip_all => 'needs DBD::SQLite for testing' )
      : ( tests => 7 );
	  $DBD::SQLite::sqlite_version; # get rid of warnings
}

use lib 't/lib';

use_ok('DBIx::Class::OptimisticLocking');

use_ok( 'OLTest' );

use_ok( 'OLTest::Schema' );

my $s = OLTest->init_schema();

my $r1 = $s->resultset('TestDirtyIgnored')->new({
	col1 => 'a',
	col2 => 'a',
	col3 => 'a',
});
$r1->insert;

my $r2 = $s->resultset('TestDirtyIgnored')->find($r1->id);
is($r1->id, $r2->id, 'retrieved identical object');
$r1->col3('b');
$r2->col3('c');
$r1->update;

# won't fail because col3 is marked "ignored"
eval {$r2->update};
ok(!$@,'no error expected');

$r2 = $s->resultset('TestDirtyIgnored')->find($r1->id);
$r2->col1('c');
$r2->update;
is($r2->col1,'c', 'update succeeded');

$r1->col1('d');
eval { $r1->update; };
ok($@, 'error expected on critical dirty column update');
