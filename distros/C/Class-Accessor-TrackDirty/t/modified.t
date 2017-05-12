use strict;
use warnings;
use Test::More;
use t::SimpleEntity;
use t::TestEntity;
use t::CasualEntity;

for (qw(SimpleEntity TestEntity CasualEntity)) {
    {
        my $entity = "t::$_"->new({key1 => 35});
        ok $entity->is_dirty, "The new entity should be stored";
        $entity->is_dirty(undef);
        ok $entity->is_dirty, "You can't modify is_dirty.";
        ok $entity->is_new, "The new data";

        $entity->revert;
        is $entity->key1, undef, "All fields shoud be removed.";
        ok ! $entity->is_dirty, "An empty entity shouldn't be stored";
        ok $entity->is_new, "The new data";

        (undef) = $entity->to_hash;
        ok ! $entity->is_dirty, "All modified columns are stored";
        ok ! $entity->is_new, "Stored in a storage";
    }

    {
        my $entity = "t::$_"->new({});
        ok ! $entity->is_dirty, "Don't save empty data";
        ok $entity->is_new, "The new data";

        $entity->revert;
        ok ! $entity->is_dirty, "Is reverted. Don't save empty data";
        ok $entity->is_new, "The new data";

        $entity->key1(18);
        is $entity->key1, 18, "Ordinary use after reverting.";
        ok $entity->is_dirty, "The key1 field was modified.";
        ok $entity->is_new, "The new data";

        (undef) = $entity->to_hash;
        ok ! $entity->is_dirty, "All modified columns are stored";
        ok ! $entity->is_new, "Stored in a storage";
    }

    {
        my $entity = "t::$_"->new({
            is_dirty => 1,
        });
        $entity->key1(99);  # Keep _origin field from being defined.

        $entity->revert;
        ok ! $entity->is_dirty, "Is reverted. Don't save empty data";
        ok $entity->is_new, "The new data";
    }

    {
        my $entity = "t::$_"->from_hash({
            key1 => 35,
        });
        ok ! $entity->is_dirty, "need not store the loaded data";
        ok ! $entity->is_new, "Fetched from a storage";
        $entity->is_dirty(1);
        $entity->is_new(1);
        ok ! $entity->is_dirty, "You can't modify is_dirty.";
        ok ! $entity->is_new, "You can't modify is_new.";

        $entity->key1(35);
        $entity->key2(undef);
        ok ! $entity->is_dirty, "I didn't change anything :p";
        ok ! $entity->is_dirty, "I didn't change anything :p";
        ok ! $entity->is_new, "Fetched from a storage";

        $entity->key1(36);
        $entity->key2("something");
        ok $entity->is_dirty, "Changed";
        ok $entity->is_dirty, "Changed";
        ok ! $entity->is_new, "Fetched from a storage";

        $entity->key1(35);
        $entity->key2(undef);
        ok ! $entity->is_dirty, "Finally return to the original value :p";
        ok ! $entity->is_dirty, "Finally return to the original value :p";
        ok ! $entity->is_new, "Fetched from a storage";

        $entity->key1(36);
        $entity->key2("something");
        $entity->revert;
        is $entity->key1, 35, "reverted changes";
        is $entity->key2, undef, "reverted changes";
        ok ! $entity->is_dirty, "reverted all statuses";
        ok ! $entity->is_new, "Fetched from a storage";

        # Freeze all changes
        $entity->key1(36);
        $entity->key2('hiratara');

        my $entity_alias = $entity;
        my $hash = $entity->to_hash;
        is $hash->{key1}, 36;
        is $entity->key1, 36;
        ok ! $entity->is_dirty, "Reset the is_dirty field";
        ok ! $entity->is_new, "Saved into a storage";
        is int($entity), int($entity_alias), "to_hash shouldn't break refs.";
        ok ! $entity_alias->is_dirty, "Aliases is also cleaned.";
        ok ! $entity->is_new, "Saved into a storage";
    }

    {
        my $entity = "t::$_"->from_hash({
            # Sat Feb 16 13:38:31 2013
            key1 => 35, mtime => 1360989511,
        });
        is $entity->mtime, 1360989511, "Can load volatile fields";

        # Fri Feb 15 17:46:42 2013 JST
        $entity->mtime(1360918002);

        is $entity->mtime, 1360918002;
        ok ! $entity->is_dirty, "Don't save the modification of modified";
        ok ! $entity->is_new, "Fetched from a storage";

        $entity->revert;
        is $entity->mtime, 1360918002, "Can't revert volatile fields";

        $entity->key1(36);
        my $hash = $entity->is_dirty ? $entity->to_hash : {};
        is $hash->{key1}, 36;
        is $hash->{mtime}, 1360918002, "Store volatile fields";
    }

    {
        my $entity = "t::$_"->from_hash({
            is_dirty => 1,
            is_new => 1,
        });
        ok ! $entity->is_dirty, "You mustn't set is_dirty.";
        ok ! $entity->is_new, "You mustn't set is_new";
    }

    {
        # To reproduce bugs of to_hash(), call to_hash twice.
        my $entity = "t::$_"->from_hash({key1 => 36, key2 => "hiratara", mtime => 12345});
        $entity->to_hash;
        $entity->to_hash;

        ok ! $entity->is_dirty;
        ok ! $entity->is_new, "Fetched from a storage";
        is $entity->key1, 36;
        is $entity->key2, "hiratara";
        is $entity->mtime, "12345";
    }
}

done_testing;
