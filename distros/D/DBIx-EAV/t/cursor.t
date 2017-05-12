#!/usr/bin/perl -w
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::DBIx::EAV;


my $eav = DBIx::EAV->new(
    dbh => get_test_dbh,
    tenant_id => 42,
    static_attributes => [qw/ is_deleted:bool::0 is_active:bool::1 is_published:bool::1 /]
);

$eav->schema->deploy( add_drop_table => $eav->schema->db_driver_name eq 'mysql');
$eav->register_types(read_yaml_file("$FindBin::Bin/entities.yml"));


test_query();
test_next();
test_reset();
test_first();

done_testing;

sub test_query {

    my $artists = $eav->resultset('Artist');
    my $name_attr = $artists->type->attribute('name');
    my $rating_attr = $artists->type->attribute('rating');

    my $cursor = $artists->search_rs({
        name => 'Bob',
        rating => { '>' => 5 },
        is_deleted => 1
    },
    {
        limit => 10,
        offset => 5,
        order_by => { -asc => 'name' },
        group_by => ['id', 'name']
    })->cursor;

    my $as_query = $cursor->as_query;

    ref_ok $$as_query, 'ARRAY';

    my ($sql_query, $bind) = @{$$as_query};

    isa_ok $cursor->_sth, 'DBI::st';
    ref_ok $bind, 'ARRAY';
    # diag $sql_query;
    ok index($sql_query, 'SELECT me.id, me.entity_type_id, me.is_deleted, me.is_active, me.is_published FROM eav_entities') != -1,
        'sql query: SELECT part';

    ok index($sql_query, "LEFT JOIN eav_value_int AS rating ON (rating.entity_id = me.id AND rating.attribute_id = $rating_attr->{id})") >= 0,
        'sql query: JOIN rating part';

    ok index($sql_query, "LEFT JOIN eav_value_varchar AS name ON (name.entity_id = me.id AND name.attribute_id = $name_attr->{id})") >= 0,
        'sql query: JOIN name part';

    ok index($sql_query, "entity_type_id = ?") >= 0,
        'sql query: WHERE entity_type_id part';

    ok index($sql_query, "name.value = ?") >= 0,
        'sql query: WHERE name part';

    ok index($sql_query, "rating.value > ?") >= 0,
        'sql query: WHERE rating part';

    ok index($sql_query, "me.is_deleted = ?") >= 0,
        'sql query: WHERE is_deleted part';

    ok index($sql_query, "ORDER BY name.value ASC LIMIT 10 OFFSET 5") >= 0,
        'sql query: ORDER BY, LIMIT, OFFSET parts';

    like $sql_query, qr(GROUP BY me.id, name.value),
        'sql query: GROUP BY part';

    # arrayref query
    $as_query = $artists->search([{ name => 'Bob' }, { rating => { '>' => 5 } }])->cursor->as_query;
    ($sql_query, $bind) = @{$$as_query};

    like $sql_query, qr/me\.entity_type_id = \? AND \( name\.value = \? OR rating\.value > \? \)/,
        'arrayref query format';

    # select function + having + order
    $as_query = $artists->search(undef, {
        select => ['id', { count => 'cds' }],
        having => { count_cds => { '>' => 3 } },
        order_by => { -asc => 'count_cds' }
    })->as_query;
    ($sql_query, $bind) = @{$$as_query};

    # diag $sql_query;

    ok index($sql_query, "SELECT me.id, COUNT( cds_link.right_entity_id ) AS count_cds") >= 0,
        'sql query: select function';

    ok index($sql_query, "HAVING ( count_cds > ? )") >= 0,
        'sql query: having';

    ok index($sql_query, "ORDER BY count_cds ASC") >= 0,
        'sql query: order by alias';
}


sub test_next {
    my $artists = $eav->resultset('Artist');
    my $name_attr = $artists->type->attribute('name');
    my $rating_attr = $artists->type->attribute('rating');

    my $bob = $artists->insert({ name => 'Bob', rating => 10 });
    my $peter = $artists->insert({ name => 'Peter', rating => 9 });
    $artists->insert({ name => 'Edson', rating => 7 });

    my $cursor = $artists->search({ rating => { '>' => 8 } }, { order_by => { -asc => 'rating' }})->cursor;

    is $cursor->next->{id}, $peter->id, '1st next()';
    is $cursor->next->{id}, $bob->id, '2nd next()';
    is $cursor->next, undef, '3rd next()';
}


sub test_reset {

    empty_database($eav);

    my $artists = $eav->resultset('Artist');
    $artists->populate([ map { +{ name => 'A'.$_ }} 1..2 ]);

    my $c = $artists->search->cursor;

    cmp_ok  $c->next->{id}, 'eq', $c->reset->next->{id}, 'reset';
}


sub test_first {

    empty_database($eav);
    my $artists = $eav->resultset('Artist');
    $artists->populate([ map { +{ name => 'A'.$_ }} 1..2 ]);

    my $c = $artists->search->cursor;
    cmp_ok $c->first->{id}, 'eq', $c->first->{id}, 'first resets cursor';
}
