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

my $r1 = $s->resultset('TestVersionIgnored')->new({
	col1 => 'a',
	col2 => 'a',
});
$r1->insert;
$r1->discard_changes;
is($r1->version, 0, 'myversion at 0');

$r1->col1('b');
$r1->update;
$r1->discard_changes;

is($r1->version, 1, 'version incremented');

$r1->col2('c');
$r1->update;

$r1->discard_changes;

is($r1->version, 1, 'version not incremented when only ignored column is updated');

$r1->update({col1=>'d', col2=>'e'});

$r1->discard_changes;
is($r1->version, 2, 'version incremented when columns updated are mixed between ignored and non-ignored');
