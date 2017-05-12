# -*- perl -*-

# t/004_basic.t - check basic stuff

use Class::C3;
use strict;
use Test::More;
use warnings;
no warnings qw(once);

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 30 );
}

use lib qw(t/lib);

use_ok( 'VCTest' );

use_ok( 'VCTest::Schema' );

my $schema = VCTest->init_schema();

my $item = $schema->resultset('Test1')->new({
    name    => 'Test.1',
    vcol2   => 'VTest2.1',
    vcol3   => 'VTest3.1',
});

is($item->name,'Test.1');
is($item->vcol2,'VTest2.1');
is($item->vcol3accessor,'VTest3.1');
is($item->vcol1,undef);
$item->insert();

my $newitem = $schema->resultset('Test1')->find($item->id);
is($newitem->name,'Test.1');
is($newitem->vcol2,undef);
ok($newitem->vcol2('VTest2.2'));
is($newitem->vcol2,'VTest2.2');
is($newitem->get_column('vcol2'),'VTest2.2');
ok($newitem->set_column('vcol1','VTest1.2'));
$newitem->update();
is($newitem->get_column('vcol1'),'VTest1.2');
$newitem->update({
    description    => 'Test.3',
    vcol3          => 'VTest3.3',
});
is($newitem->vcol3accessor,'VTest3.3');
is($newitem->vcol2,'VTest2.2');

is($newitem->column_info('vcol1')->{virtual},1);
is($newitem->column_info('name')->{virtual},0);
is($newitem->column_info('name')->{data_type},'varchar');
is($newitem->column_info('vcol3')->{virtual},1);
is($newitem->column_info('vcol3')->{accessor},'vcol3accessor');

my %values = $newitem->get_columns;

is($values{vcol3},'VTest3.3');
is($values{vcol2},'VTest2.2');
is($values{name},'Test.1');

my $brandnewitem = $schema->resultset('Test1')->create({
    name    => 'Test.4',
    vcol2   => 'VTest2.4',
    vcol3   => 'VTest3.4',
});
is($brandnewitem->name,'Test.4');
is($brandnewitem->vcol2,'VTest2.4');

ok($brandnewitem->set_column('description','Test.5'));
ok($brandnewitem->set_column('vcol1','VTest2.5'));

is($brandnewitem->get_column('description'),'Test.5');
is($brandnewitem->get_column('vcol1'),'VTest2.5');
is($brandnewitem->get_column('vcol2'),'VTest2.4');
