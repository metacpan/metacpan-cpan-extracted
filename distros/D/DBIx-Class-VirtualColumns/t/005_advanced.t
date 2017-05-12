# -*- perl -*-

# t/005_advanced.t - check advanced stuff

use Class::C3;
use strict;
use Test::More;
use warnings;
no warnings qw(once);

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 17 );
}

use lib qw(t/lib);

use_ok( 'VCTest' );

use_ok( 'VCTest::Schema' );

my $schema = VCTest->init_schema();

my $source = $schema->resultset('Test1');


VCTest::Schema::Test2->add_virtual_columns('test1');
VCTest::Schema::Test2->add_virtual_columns('test3');
VCTest::Schema::Test2->add_virtual_columns('test4');
eval {
    VCTest::Schema::Test2->add_virtual_columns('test1');
};
like($@,qr/Cannot override existing column/);

eval {
    VCTest::Schema::Test2->add_virtual_column('description');
};
like($@,qr/Cannot override existing column/);

VCTest::Schema::Test2->add_virtual_columns('test2' => { accessor => 'hase', other => 'stuff'});

is(VCTest::Schema::Test2->has_virtual_column('test2'),1);
is(VCTest::Schema::Test2->has_virtual_column('test3'),1);
is(VCTest::Schema::Test2->has_virtual_column('test4'),1);
VCTest::Schema::Test2->remove_virtual_columns('test3');
VCTest::Schema::Test2->remove_virtual_column('test4');
is(VCTest::Schema::Test2->has_virtual_column('test3'),0);
is(VCTest::Schema::Test2->has_virtual_column('test4'),0);
is(VCTest::Schema::Test2->has_virtual_column('test5'),0);
is(VCTest::Schema::Test2->has_any_column('test5'),0);
is(VCTest::Schema::Test2->has_any_column('test5'),0);
is(VCTest::Schema::Test2->has_any_column('description'),1);

my $info = VCTest::Schema::Test2->column_info('description');

is($info->{is_nullable},1);
is($info->{virtual},0);

$info = VCTest::Schema::Test2->column_info('test2');

is($info->{virtual},1);
is($info->{other},'stuff');