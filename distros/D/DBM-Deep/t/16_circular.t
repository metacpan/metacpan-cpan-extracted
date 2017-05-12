use strict;
use warnings FATAL => 'all';

use Test::More;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

my $dbm_factory = new_dbm();
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    ##
    # put/get simple keys
    ##
    $db->{key1} = "value1";
    $db->{key2} = "value2";

    my @keys_1 = sort keys %$db;

    $db->{key3} = $db->{key1};

    my @keys_2 = sort keys %$db;
    is( @keys_2 + 0, @keys_1 + 1, "Correct number of keys" );
    is_deeply(
        [ @keys_1, 'key3' ],
        [ @keys_2 ],
        "Keys still match after circular reference is added",
    );

    $db->{key4} = { 'foo' => 'bar' };
    $db->{key5} = $db->{key4};
    $db->{key6} = $db->{key5};

    my @keys_3 = sort keys %$db;

    is( @keys_3 + 0, @keys_2 + 3, "Correct number of keys" );
    is_deeply(
        [ @keys_2, 'key4', 'key5', 'key6', ],
        [ @keys_3 ],
        "Keys still match after circular reference is added (@keys_3)",
    );

    ##
    # Insert circular reference
    ##
    $db->{circle} = $db;

    my @keys_4 = sort keys %$db;

    is( @keys_4 + 0, @keys_3 + 1, "Correct number of keys" );
    is_deeply(
        [ 'circle', @keys_3 ],
        [ @keys_4 ],
        "Keys still match after circular reference is added",
    );

    ##
    # Make sure keys exist in both places
    ##
    is( $db->{key1}, 'value1', "The value is there directly" );
    is( $db->{circle}{key1}, 'value1', "The value is there in one loop of the circle" );
    is( $db->{circle}{circle}{key1}, 'value1', "The value is there in two loops of the circle" );
    is( $db->{circle}{circle}{circle}{key1}, 'value1', "The value is there in three loops of the circle" );

    ##
    # Make sure changes are reflected in both places
    ##
    $db->{key1} = "another value";

    isnt( $db->{key3}, 'another value', "Simple scalars are copied by value" );

    is( $db->{key1}, 'another value', "The value is there directly" );
    is( $db->{circle}{key1}, 'another value', "The value is there in one loop of the circle" );
    is( $db->{circle}{circle}{key1}, 'another value', "The value is there in two loops of the circle" );
    is( $db->{circle}{circle}{circle}{key1}, 'another value', "The value is there in three loops of the circle" );

    $db->{circle}{circle}{circle}{circle}{key1} = "circles";

    is( $db->{key1}, 'circles', "The value is there directly" );
    is( $db->{circle}{key1}, 'circles', "The value is there in one loop of the circle" );
    is( $db->{circle}{circle}{key1}, 'circles', "The value is there in two loops of the circle" );
    is( $db->{circle}{circle}{circle}{key1}, 'circles', "The value is there in three loops of the circle" );

    is( $db->{key4}{foo}, 'bar' );
    is( $db->{key5}{foo}, 'bar' );
    is( $db->{key6}{foo}, 'bar' );

    $db->{key4}{foo2} = 'bar2';
    is( $db->{key4}{foo2}, 'bar2' );
    is( $db->{key5}{foo2}, 'bar2' );
    is( $db->{key6}{foo2}, 'bar2' );

    $db->{key4}{foo3} = 'bar3';
    is( $db->{key4}{foo3}, 'bar3' );
    is( $db->{key5}{foo3}, 'bar3' );
    is( $db->{key6}{foo3}, 'bar3' );

    $db->{key4}{foo4} = 'bar4';
    is( $db->{key4}{foo4}, 'bar4' );
    is( $db->{key5}{foo4}, 'bar4' );
    is( $db->{key6}{foo4}, 'bar4' );
}
done_testing;
