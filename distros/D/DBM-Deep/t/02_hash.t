use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use t::common qw( new_dbm );
use Scalar::Util qw( reftype );

use_ok( 'DBM::Deep' );

my $dbm_factory = new_dbm();
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    ##
    # put/get key
    ##
    $db->{key1} = "value1";
    is( $db->get("key1"), "value1", "get() works with hash assignment" );
    is( $db->fetch("key1"), "value1", "... fetch() works with hash assignment" );
    is( $db->{key1}, "value1", "... and hash-access also works" );

    $db->put("key2", undef);
    is( $db->get("key2"), undef, "get() works with put()" );
    is( $db->fetch("key2"), undef, "... fetch() works with put()" );
    is( $db->{key2}, undef, "... and hash-access also works" );

    $db->store( "0", "value3" );
    is( $db->get("0"), "value3", "get() works with store()" );
    is( $db->fetch("0"), "value3", "... fetch() works with put()" );
    is( $db->{0}, 'value3', "... and hash-access also works" );

    # Verify that the keyval pairs are still correct.
    is( $db->{key1}, "value1", "Key1 is still correct" );
    is( $db->{key2}, undef, "Key2 is still correct" );
    is( $db->{0}, 'value3', "Key3 is still correct" );

    ok( $db->exists("key1"), "exists() function works" );
    ok( exists $db->{key2}, "exists() works against tied hash" );

    ok( !exists $db->{key4}, "exists() function works for keys that aren't there" );
    is( $db->{key4}, undef, "Nonexistent key4 is undef" );
    ok( !exists $db->{key4}, "Simply reading key4 does not autovivify" );

    # Keys will be done via an iterator that keeps a breadcrumb trail of the last
    # key it provided. There will also be an "edit revision number" on the
    # reference so that resetting the iterator can be done.
    #
    # Q: How do we make sure that the iterator is unique? Is it supposed to be?

    ##
    # count keys
    ##
    is( scalar keys %$db, 3, "keys() works against tied hash" );

    ##
    # step through keys
    ##
    my $temphash = {};
    while ( my ($key, $value) = each %$db ) {
        $temphash->{$key} = $value;
    }

    is( $temphash->{key1}, 'value1', "First key copied successfully using tied interface" );
    is( $temphash->{key2}, undef, "Second key copied successfully" );
    is( $temphash->{0}, 'value3', "Third key copied successfully" );

    $temphash = {};
    my $key = $db->first_key();
    while (defined $key) {
        $temphash->{$key} = $db->get($key);
        $key = $db->next_key($key);
    }

    is( $temphash->{key1}, 'value1', "First key copied successfully using OO interface" );
    is( $temphash->{key2}, undef, "Second key copied successfully" );
    is( $temphash->{0}, 'value3', "Third key copied successfully" );

    ##
    # delete keys
    ##
    is( delete $db->{key2}, undef, "delete through tied inteface works" );
    is( $db->delete("key1"), 'value1', "delete through OO inteface works" );
    is( $db->{0}, 'value3', "The other key is still there" );
    ok( !exists $db->{key1}, "key1 doesn't exist" );
    ok( !exists $db->{key2}, "key2 doesn't exist" );

    is( scalar keys %$db, 1, "After deleting two keys, 1 remains" );

    ##
    # delete all keys
    ##
    ok( $db->clear(), "clear() returns true" );

    is( scalar keys %$db, 0, "After clear(), everything is removed" );

    ##
    # replace key
    ##
    $db->put("key1", "value1");
    is( $db->get("key1"), "value1", "Assignment still works" );

    $db->put("key1", "value2");
    is( $db->get("key1"), "value2", "... and replacement works" );

    $db->put("key1", "value222222222222222222222222");
    is( $db->get("key1"), "value222222222222222222222222", "We set a value before closing the file" );

    ##
    # Make sure DB still works after closing / opening
    ##
    undef $db;
    $db = $dbm_maker->();
    is( $db->get("key1"), "value222222222222222222222222", "The value we set is still there after closure" );

    ##
    # Make sure keys are still fetchable after replacing values
    # with smaller ones (bug found by John Cardenas, DBM::Deep 0.93)
    ##
    $db->clear();
    $db->put("key1", "long value here");
    $db->put("key2", "longer value here");

    $db->put("key1", "short value");
    $db->put("key2", "shorter v");

    my $first_key = $db->first_key();
    my $next_key = $db->next_key($first_key);

    ok(
        (($first_key eq "key1") || ($first_key eq "key2")) && 
        (($next_key eq "key1") || ($next_key eq "key2")) && 
        ($first_key ne $next_key)
        ,"keys() still works if you replace long values with shorter ones"
    );

    # Test autovivification
    $db->{unknown}{bar} = 1;
    ok( $db->{unknown}, 'Autovivified hash exists' );
    is( reftype($db->{unknown}), 'HASH', "... and it's a HASH" );
    cmp_ok( $db->{unknown}{bar}, '==', 1, 'And the value stored is there' );

    # Test failures
    throws_ok {
        $db->fetch();
    } qr/Cannot use an undefined hash key/, "FETCH fails on an undefined key";

    throws_ok {
        $db->fetch(undef);
    } qr/Cannot use an undefined hash key/, "FETCH fails on an undefined key";

    throws_ok {
        $db->store();
    } qr/Cannot use an undefined hash key/, "STORE fails on an undefined key";

    throws_ok {
        $db->store(undef, undef);
    } qr/Cannot use an undefined hash key/, "STORE fails on an undefined key";

    throws_ok {
        $db->delete();
    } qr/Cannot use an undefined hash key/, "DELETE fails on an undefined key";

    throws_ok {
        $db->delete(undef);
    } qr/Cannot use an undefined hash key/, "DELETE fails on an undefined key";

    throws_ok {
        $db->exists();
    } qr/Cannot use an undefined hash key/, "EXISTS fails on an undefined key";

    throws_ok {
        $db->exists(undef);
    } qr/Cannot use an undefined hash key/, "EXISTS fails on an undefined key";
}

{
    # RT# 50541 (reported by Peter Scott)
    # clear() leaves one key unless there's only one
    my $dbm_factory = new_dbm();
    while ( my $dbm_maker = $dbm_factory->() ) {
        my $db = $dbm_maker->();

        $db->{block} = { };
        $db->{critical} = { };
        $db->{minor} = { };

        cmp_ok( scalar(keys( %$db )), '==', 3, "Have 3 keys" );

        $db->clear;

        cmp_ok( scalar(keys( %$db )), '==', 0, "clear clears everything" );
    }
}

done_testing;
