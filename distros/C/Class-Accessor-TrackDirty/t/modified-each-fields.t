use strict;
use warnings;
use lib '.';
use Test::More;
use t::SimpleEntity;
use t::TestEntity;
use t::CasualEntity;

for (qw(SimpleEntity TestEntity CasualEntity)) {
    {
        my $entity = "t::$_"->new({key1 => "ABC", mtime => time});
        ok $entity->is_dirty('key1'), "The field hasn't been stored";
        ok ! $entity->is_dirty('key2'), "An empty field is clean";
        ok ! $entity->is_dirty('mtime'), "Isn't managed by TrackDirty";
        ok eq_set([$entity->dirty_fields], [qw(key1)]);
    }

    {
        my $entity = "t::$_"->from_hash({key1 => "ABC", key2 => "abc"});
        ok ! $entity->is_dirty('key1');
        ok ! $entity->is_dirty('key2');
        ok eq_set([$entity->dirty_fields], [qw()]);

        $entity->key1("XYZ");
        $entity->key2("abc");
        ok $entity->is_dirty('key1');
        ok ! $entity->is_dirty('key2');
        ok eq_set([$entity->dirty_fields], [qw(key1)]);

        $entity->key1("ABC");
        $entity->key2("xyz");
        ok ! $entity->is_dirty('key1');
        ok $entity->is_dirty('key2');
        ok eq_set([$entity->dirty_fields], [qw(key2)]);

        $entity->key1("XYZ");
        ok $entity->is_dirty('key1');
        ok $entity->is_dirty('key2');
        ok eq_set([$entity->dirty_fields], [qw(key1 key2)]);

        $entity->to_hash; # Will be stored into any places
        ok ! $entity->is_dirty('key1');
        ok ! $entity->is_dirty('key2');
        ok eq_set([$entity->dirty_fields], [qw()]);
    }
}

done_testing;
