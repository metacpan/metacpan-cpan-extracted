#!/usr/bin/perl -w
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::DBIx::EAV;
use DBIx::EAV::Table;


my $dbh = get_test_dbh;
my $eav = DBIx::EAV->new( dbh => $dbh, tenant_id => 42 );
$eav->schema->deploy( add_drop_table => $eav->schema->db_driver_name eq 'mysql');

my $table = DBIx::EAV::Table->new(
    dbh => $dbh,
    tenant_id => 42,
    name => 'eav_entity_types',
    columns => [qw/ id tenant_id name signature /]
);



test_insert();
test_select();
test_select_one();
test_update();
test_delete();

done_testing;

sub test_insert {


    my $res = $table->insert({ name => 'Foo', signature => 'foo' });

    is $res, 1, 'insert return value';

    is $dbh->selectrow_hashref('SELECT * from eav_entity_types WHERE id = '.$res),
              { id => $res, name => 'Foo', tenant_id => $table->tenant_id, signature => 'foo' },
              'inserted data is there';

    is $table->insert({ name => 'Bar', signature => 'bar' }), $res + 1, 'insert returns last inserted';
}

sub test_select {


    my $res = $table->select({ name => 'Foo' });
    isa_ok $res, 'DBI::st';
    like $res->fetchrow_hashref, { id => 1, name => 'Foo', tenant_id => $table->tenant_id }, 'selected data';

}

sub test_select_one {


    my $res = $table->select_one({ name => 'Foo' });
    ref_ok $res, 'HASH', 'returns hashref';
    like $res, { id => 1, name => 'Foo', tenant_id => $table->tenant_id }, 'found data';

}

sub test_update {


    my $res = $table->update({ name => 'FooBar' }, { id => 1});

    is $res, 1, 'update() rv';
    like $dbh->selectrow_hashref('SELECT * from eav_entity_types WHERE id = 1'),
              { id => 1, name => 'FooBar', tenant_id => $table->tenant_id },
              'updated   data is there';
}

sub test_delete {


    my $res = $table->delete({ id => 1});

    is $res, 1, 'delete() rv';

    is $dbh->selectrow_hashref('SELECT * from eav_entity_types WHERE id = 1'), undef, 'deleted row is gone';
}
