use strict;
use warnings;
use lib '.';
use Test::More;
use t::SimpleEntity;
use t::TestEntity;
use t::CasualEntity;

for (qw(SimpleEntity TestEntity CasualEntity)) {
    {
        my $entity = "t::$_"->new({});
        ok eq_set([$entity->dirty_fields], [qw()]), 'new entity(1)';

        $entity->key2("2016");
        ok eq_set([$entity->dirty_fields], [qw(key2)]), 'new entity(2)';

        $entity->key1("2015");
        ok eq_set([$entity->dirty_fields], [qw(key1 key2)]), 'new entity(3)';
    }

    {
        my $entity = "t::$_"->new({});
        (undef) = $entity->to_hash;
        ok eq_set([$entity->dirty_fields], [qw()]), 'stored entity(1)';

        $entity->key2("2016");
        ok eq_set([$entity->dirty_fields], [qw(key2)]), 'stored entity(2)';

        $entity->key1("2015");
        ok eq_set([$entity->dirty_fields], [qw(key1 key2)]), 'stored entity(3)';
    }
}

done_testing;
