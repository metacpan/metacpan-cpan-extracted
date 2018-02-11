#!/usr/bin/perl -w
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::DBIx::EAV;

my $dbh = get_test_dbh;
my $eav_schema = read_yaml_file("$FindBin::Bin/entities.yml");


# tenant 1
my $eav = DBIx::EAV->new( dbh => $dbh, tenant_id => 1 );
$eav->schema->deploy( add_drop_table => $eav->schema->db_driver_name eq 'mysql');
$eav->declare_entities($eav_schema);

my $t1artist = $eav->type('Artist');

# tenant 2
diag "tenant 2";
$eav = DBIx::EAV->new( dbh => $dbh, tenant_id => 2 );
$eav->declare_entities($eav_schema);

isnt $t1artist->id, $eav->type('Artist')->id, 'each tenant gets its own types';


# no tenant
$dbh = get_test_dbh();
$eav = DBIx::EAV->new( dbh => $dbh );
$eav->schema->deploy( add_drop_table => $eav->schema->db_driver_name eq 'mysql');
$eav->declare_entities($eav_schema);


my $artist = $eav->type('Artist');
ok $eav->type('Artist'), 'no tenant - type registered';

is $dbh->selectrow_hashref('SELECT * from eav_entity_types WHERE id = '.$artist->id),
    { id => $artist->id, name => 'Artist', signature => $eav->_type_declarations->{Artist}{signature} }, 'no tenant - type row';


done_testing;
