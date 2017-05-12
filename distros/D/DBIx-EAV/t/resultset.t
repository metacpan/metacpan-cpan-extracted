#!/usr/bin/perl -w
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::DBIx::EAV;


my $eav = DBIx::EAV->new( dbh => get_test_dbh(), tenant_id => 42 );
$eav->schema->deploy( add_drop_table => $eav->schema->db_driver_name eq 'mysql');
$eav->register_types(read_yaml_file("$FindBin::Bin/entities.yml"));


test_common();
test_insert();
test_pupulate();
test_search();
test_retrieval();
test_count();
SKIP: {
    skip 'rs->delete() not supported on SQLite', 2
        if $eav->schema->db_driver_name eq 'SQLite';
    test_delete();
};
test_delete_all();
test_related();
test_distinct();
test_having();

done_testing;

sub test_common {
    my $rs = $eav->resultset('Artist');

    isa_ok $rs, 'DBIx::EAV::ResultSet';
    is $rs->type->name, 'Artist', 'resultset type';
}


sub test_insert {
    my $rs  = $eav->resultset('Artist');
    my $bob = $rs->insert({ name => 'Bob Marley' });

    isa_ok $bob, 'DBIx::EAV::Entity';
    is $bob->in_storage, 1, 'entity is in_storage';
}


sub test_pupulate {
    my $rs = $eav->resultset('Artist');

    my @artists = $rs->populate([{ name => 'A1' }, { name => 'A2' }]);
    is [map { $_->get('name') } @artists], [qw/ A1 A2 /], 'populate - list context';

    my $artists = $rs->populate([{ name => 'A3' }, { name => 'A4' }]);
    is [map { $_->get('name') } @$artists], [qw/ A3 A4 /], 'populate - scalar context';
}


sub test_search {

    empty_database($eav);

    my $rs = $eav->resultset('Artist');
    $rs->populate([{ name => 'A1' }, { name => 'A2' }]);

    cmp_ok $rs, 'ne', $rs->search({ name => 'A1' }), 'search in scalar context';
    is [map { $_->get('name') } $rs->search ], [qw/ A1 A2 /], 'search in list context';

    my $cursor = $rs->cursor;

    isa_ok $cursor, 'DBIx::EAV::Cursor';

    my $chained_rs = $rs->search({ name => 'foo' }, { limit => 10, group_by => ['g1', 'g2'], having => { g1 => 1 } })
                        ->search({ rating => 5 }, { limit => 20, group_by => ['g3'], having => { g3 => 1 } });

    is $chained_rs->cursor->query,
              [{ name => 'foo' }, { rating => 5 }], 'chained rs - merged query';

    is $chained_rs->cursor->options,
              {
                  limit => 20,
                  group_by => [qw/ g1 g2 g3 /],
                  having => [{ g1 => 1 }, { g3 => 1 }]
              }, 'chained rs - merged options';

    # find()
    my $a1 = $rs->find({ name => 'A1' });
    is $a1->get('name'), 'A1', 'find by query';
    is $rs->find($a1->id)->get('name'), 'A1', 'find by id';
    like dies { $rs->find({ name => [qw/ A1 A2 /] }) }, qr/returned more than one entity/;
}


sub test_retrieval {

    empty_database($eav);

    my $rs = $eav->resultset('Artist');
    $rs->populate([{ name => 'A1' }, { name => 'A2' }]);

    # next()
    is $rs->next->get('name'), 'A1', 'next (1)';
    is $rs->next->get('name'), 'A2', 'next (2)';
    is $rs->next, undef, 'next (undef)';

    # reset()
    is $rs->reset->next->get('name'), 'A1', 'reset';

    # all()
    is [map { $_->get('name') } $rs->all ], [qw/ A1 A2 /], 'all in list context';
    my $all = $rs->all;
    is [map { $_->get('name') } @$all ], [qw/ A1 A2 /], 'all in scalar context';

    # first()
    is $rs->first->get('name'), 'A1', 'first';
    is $rs->first->get('name'), $rs->first->get('name'), 'first resets';
}


sub test_delete {

    empty_database($eav);

    my $rs = $eav->resultset('CD');
    $rs->populate([
        { title => 'CD1' },
        { title => 'CD2', tracks => [{ title => 'T1' }, { title => 'T2' }, { title => 'T3' }] }
    ]);

    $rs->delete;

    is $rs->count, 0, 'delete';
    is $eav->resultset("Track")->count, 3, 'delete leaves related entities';
}


sub test_delete_all {

    empty_database($eav);

    my $rs = $eav->resultset('CD');
    $rs->populate([
        { title => 'CD1' },
        { title => 'CD2', tracks => [{ title => 'T1' }, { title => 'T2' }, { title => 'T3' }] }
    ]);

    $rs->delete_all;

    is $rs->count, 0, 'delete_all';
    is $eav->resultset("Track")->count, 0, 'delete_all cascade delete';
}


sub test_count {
    my $rs = $eav->resultset('Artist');
    empty_database($eav);

    $rs->populate([ map { +{ name => 'A'.$_ }} 1..6 ]);
    $rs->populate([ map { +{ name => 'A'.$_ }} 1..6 ]);

    is $rs->count, 12, 'count()';
    ok $rs == 12, 'count() called in number context';
    is $rs->count({ name => [qw/ A2 A3 /]}), 4, 'count(\%where)';
    is $rs->count(undef, { select => ['name'], group_by => ['name'] }), 6, 'count() group_by';
    is $rs->count(undef, { select => ['name'], distinct => 1 }), 6, 'count() distinct';

    is $rs->search(undef, { limit => 5 })->count, 5, 'count() with limit';
    is $rs->search(undef, { limit => 5, offset => 10 })->count, 2, 'count() with limit + offset';
    is $rs->search(undef, { limit => 5, offset => 20 })->count, 0, 'count() with outbound offset';
}


sub test_related {

    my $a1 = $eav->resultset('Artist')->insert({
        name => 'Artist1',
        cds  => [
            {title => 'CD1', rating => 3, tracks => [{ title => 'Track1' }]},
            {title => 'CD2', rating => 6},
            {title => 'CD3', rating => 9}
        ]});

    my $a2 = $eav->resultset('Artist')->insert({
        name => 'Artist2',
        cds  => [{title => 'CD4'}, {title => 'CD5'}] });

    # CDs by artist
    my $cds = $eav->resultset('CD')->search({ artists => $a1 }, { order_by => { -desc => 'title' }});
    is [map { $_->get('title') } $cds->all], [qw/ CD3 CD2 CD1 /], 'fetch cds by artist';

    # CDs by multiple (or'ed) artists
    $cds = $eav->resultset('CD')->search({ artists => [$a1, $a2] }, { order_by => 'title, rating' });
    is [map { $_->get('title') } $cds->all], [qw/ CD1 CD2 CD3 CD4 CD5 /], "fetch cds by multiple (or'ed) artist";

    # cds via artists 'cds' rel
    is [map { $_->get('title') } $a1->get('cds')->all], [qw/ CD1 CD2 CD3 /], 'cds via artists rel';

    # find by related attr
    my $cd4 = $eav->resultset('CD')->find({ title => 'CD4' });
    is $eav->resultset('Artist')->find({ 'cds.id' => $cd4->id })->get('name'), 'Artist2', 'find by related static attr';

    # find by related attr
    is $eav->resultset('Artist')->find({ 'cds.title' => 'CD1' })->get('name'), 'Artist1', 'find by related attr';

    # artist by track name
    is $eav->resultset('Artist')->find({ 'cds.tracks.title' => 'Track1' })->get('name'), 'Artist1', 'find by deep related attr';
}


sub test_distinct {

    empty_database($eav);

    my $artists = $eav->resultset('Artist');

    $artists->populate([
        { name => 'Bob' },
        { name => 'Bob' },
        { name => 'Peter' },
    ]);

    is [map { $_->get('name') } $artists->search(undef, { select => [qw/ name id /], distinct => 1 })->all],
              [qw/ Bob Peter /], 'find distinct';

    is $artists->search(undef, { select => [qw/ name id /], distinct => 1 })->count, 2, 'count distinct';
}


sub test_having {

    empty_database($eav);
    my $rs = $eav->resultset('Artist');

    $rs->populate([
        { name => 'Bob', cds => [map { +{ title => 'CD'.$_ } } 1..3] },
        { name => 'Peter', cds => [map { +{ title => 'CD'.$_ } } 4..8] },
    ]);

    my @result = $rs->search(undef, {
        select => ['id', 'name', { count => 'cds' }],
        group_by => 'id',
        having => { count_cds => { '>' => 3 }},
    });

    is [map { $_->get('name') } @result],
              [qw/ Peter /], 'having';

}
