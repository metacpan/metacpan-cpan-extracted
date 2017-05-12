#!/usr/bin/perl -w

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::DBIx::EAV;
use DBIx::EAV::Entity;
use My::Entity::Artist;

my $dbh = get_test_dbh;
my $eav = DBIx::EAV->new(
    dbh => $dbh,
    tenant_id => 42,
    entity_namespaces => ['My::Entity'],
    resultset_namespaces => ['My::ResultSet'],
);

$eav->schema->deploy( add_drop_table => $eav->schema->db_driver_name eq 'mysql');



subtest 'is_custom_class' => sub {

    is 'DBIx::EAV::Entity'->is_custom_class, '';
    is 'My::Entity::Artist'->is_custom_class, 1;
};

subtest 'type_definition' => sub {

    is 'My::Entity::Artist'->type_definition, {
        'attributes' => [
            'name',
            { 'name' => 'birth_date', 'type' => 'datetime' },
            'description:text',
            'rating:int'
        ],
        'many_to_many' => ['CD']
    };
};

subtest 'Artist type' => sub {

    my $type = $eav->type('Artist');
    is $type->name, 'Artist';

    ok $type->has_attribute($_) for qw/ name birth_date description rating /;
    ok $type->has_relationship('cds');
};

subtest 'CD type' => sub {

    my $type = $eav->type('CD');
    is $type->name, 'CD';

    ok $type->has_attribute($_) for qw/ name /;
    ok $type->has_relationship('artists');
};

subtest 'subclass' => sub {

    my $type = $eav->type('PopArtist');
    is $type->name, 'PopArtist';
    ok $type->is_type('PopArtist');
    ok $type->is_type('Artist');

    ok $type->has_attribute($_) for qw/ pop_name /;
    ok $type->has_inherited_attribute($_) for qw/ name birth_date description rating /;
    ok $type->has_relationship('cds');
};


subtest 'entity instance class' => sub {


    my $artist = $eav->resultset('Artist')->create({ name => 'Bob' });
    isa_ok $artist, 'My::Entity::Artist';
    is $artist->uc_name, 'BOB';

    isa_ok $eav->resultset('Artist'), 'My::ResultSet::Artist';
};


subtest 'inexistent class' => sub {

    like dies { $eav->type('Unknown') }, qr/^Can't locate/;
};


done_testing;
