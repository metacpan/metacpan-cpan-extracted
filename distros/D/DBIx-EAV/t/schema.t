#!/usr/bin/perl -w
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::DBIx::EAV;


my $dbh = get_test_dbh( no_deploy => 1 );
my $eav = DBIx::EAV->new( dbh => $dbh, tenant_id => 42 );


test_create_tables();
test_register_types();
test_entity_type();
test_load_types();

done_testing;


sub test_create_tables {

    my $schema = $eav->schema;

    isa_ok $schema->translator, 'SQL::Translator';

    like $schema->get_ddl, qr/CREATE TABLE/, 'get_dll()';
    like $schema->get_ddl('JSON'), qr/SQL::Translator::Producer::JSON/, 'get_dll("JSON")';

    is $schema->version_table_is_installed, 0, 'version_table_is_installed';

    $schema->deploy( add_drop_table => $eav->schema->db_driver_name eq 'mysql' );

    is $schema->version_table_is_installed, 1, 'version_table_is_installed';

    is $eav->schema->deploy( add_drop_table => 0 ), undef, 'ignore deploy same version';

    is $schema->installed_version, $schema->version, 'installed_version';

    my $check_sqlt = SQL::Translator->new(
        parser => 'DBI',
        parser_args => {
            dbh => $dbh
        }
    );

    $check_sqlt->translate;
    ok $check_sqlt->schema->get_table($eav->schema->table_prefix.$_), "table '$_' created"
        for (qw/ schema_versions entity_types entities attributes relationships entity_relationships /,
             map { "value_$_" } @{$eav->schema->data_types}
            );


    my $version_table = $schema->version_table;
    is $version_table->select_one({ id => 1 })->{version}, 1, 'version 1 row';

    # deploy version 2
    $DBIx::EAV::Schema::SCHEMA_VERSION = 2;

    is $schema->version, 2;

    $schema->deploy( add_drop_table => 1 );

    is $schema->installed_version, $schema->version, 'installed_version';

    is $version_table->select_one({ id => 2 })->{version}, 2, 'version 2 row';
}


sub test_register_types {

    my $schema = read_yaml_file("$FindBin::Bin/entities.yml");

    is $eav->schema->has_data_type('int'), 1, 'has_data_type';

    $eav->register_types($schema);

    # entity types
    my $artist = $dbh->selectrow_hashref('SELECT * from eav_entity_types WHERE name = "Artist"');
    my $cd = $dbh->selectrow_hashref('SELECT * from eav_entity_types WHERE name = "CD"');
    my $track = $dbh->selectrow_hashref('SELECT * from eav_entity_types WHERE name = "Track"');

    is $artist->{name}, 'Artist', 'Artist type rgistered';
    is $cd->{name}, 'CD', 'CD type rgistered';
    is $track->{name}, 'Track', 'Track type registered';
    is $track->{tenant_id}, $eav->schema->tenant_id, 'type tenant_id';

    # attributes
    my $name_attr = $dbh->selectrow_hashref(sprintf 'SELECT * from eav_attributes WHERE name = "name" AND entity_type_id = %d', $artist->{id});
    is $name_attr->{name}, 'name', 'name attr registered';
    is $name_attr->{data_type}, 'varchar', 'name attr data_type';

    my $description_attr = $dbh->selectrow_hashref(sprintf 'SELECT * from eav_attributes WHERE name = "description" AND entity_type_id = %d', $artist->{id});
    is $description_attr->{name}, 'description', 'description attr registered';
    is $description_attr->{data_type}, 'text', 'description attr data_type';

    ref_ok $eav->_types->{Artist}, 'HASH', 'Artist entity schema';
    ref_ok $eav->_types->{CD}, 'HASH', 'CD entity schema';
    ref_ok $eav->_types->{Track}, 'HASH', 'Track entity schema';

    # has_many
    is $dbh->selectrow_hashref('SELECT is_has_one, is_has_many, is_many_to_many, left_entity_type_id, right_entity_type_id FROM eav_relationships WHERE name = "tracks"'),
        {
            is_has_one => 0,
            is_has_many => 1,
            is_many_to_many => 0,
            left_entity_type_id => $cd->{id},
            right_entity_type_id => $track->{id},
        },
        'CD has_many Tracks';

    # many_to_many
    is $dbh->selectrow_hashref('SELECT is_has_one, is_has_many, is_many_to_many, left_entity_type_id, right_entity_type_id FROM eav_relationships WHERE name = "cds"'),
        {
            is_has_one => 0,
            is_has_many => 0,
            is_many_to_many => 1,
            left_entity_type_id => $artist->{id},
            right_entity_type_id => $cd->{id},
        },
        'Artist many_to_many CDs';
}


sub test_entity_type {

    like dies { $eav->type('Unknown') }, qr/EntityType 'Unknown' does not exist/;
    my $artist = $eav->type('Artist');
    isa_ok $artist, 'DBIx::EAV::EntityType';

    like $artist->id, qr/^\d$/, 'id';
    is $artist->name, 'Artist', 'name';

    is $artist->has_static_attribute('id'), 1, 'has_static_attribute()';
    is $artist->has_attribute('name'), 1, 'has_attribute()';
    is $artist->has_own_attribute('name'), 1, 'has_own_attribute()';
    is $artist->attribute('name')->{name}, 'name', 'attribute()';
    is $artist->attribute('id')->{is_static}, 1, 'attribute() <static attr>';

    ok $artist->has_relationship('cds'), 'has_relationship';
    ok $eav->type('CD')->has_relationship('artists'), 'incoming relationship installed';
}

sub test_load_types {

    $eav = DBIx::EAV->new( dbh => $dbh, tenant_id => 42 );
    test_entity_type();
}
