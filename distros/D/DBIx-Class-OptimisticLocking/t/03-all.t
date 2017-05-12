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

my $r1 = $s->resultset('TestAll')->new({
	col1 => 'a',
	col2 => 'a',
	col3 => 'a',
});
$r1->insert;

my $r2 = $s->resultset('TestAll')->find($r1->id);
is($r1->id, $r2->id, 'retrieved identical object');
$r1->col2('b');
$r2->col3('c');
$r1->update;

# fails because $r2 doesn't have $r1's new col2 value
eval {$r2->update};
ok($@,'error expected');

$r2 = $s->resultset('TestAll')->find($r1->id);
$r2->col2('d');
$r2->update;
is($r2->col2,'d', 'update succeeded');

$r1->col2('d');
eval { $r1->update; };
ok($@, 'error expected even on identical update ');
