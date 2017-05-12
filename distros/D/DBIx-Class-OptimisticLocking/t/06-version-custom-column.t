use strict;
use warnings;
use Test::More;


BEGIN {
    eval "use DBD::SQLite";
    plan $@
      ? ( skip_all => 'needs DBD::SQLite for testing' )
      : ( tests => 5 );
    $DBD::SQLite::sqlite_version; # get rid of warnings
}

use lib 't/lib';

use_ok('DBIx::Class::OptimisticLocking');

use_ok( 'OLTest' );

use_ok( 'OLTest::Schema' );

my $s = OLTest->init_schema();

my $r1 = $s->resultset('TestVersionAlt')->new({
	col1 => 'a',
	col2 => 'a',
});
$r1->insert;
$r1->discard_changes;
is($r1->myversion, 0, 'myversion at 0');

$r1->col1('b');
$r1->update;
$r1->discard_changes;

is($r1->myversion, 1, 'myversion incremented');
