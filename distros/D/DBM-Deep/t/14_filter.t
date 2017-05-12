use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Deep;

use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

sub my_filter_store_key { return 'MYFILTER' . $_[0]; }
sub my_filter_store_value { return 'MYFILTER' . $_[0]; }

sub my_filter_fetch_key { $_[0] =~ s/^MYFILTER//; return $_[0]; }
sub my_filter_fetch_value { $_[0] =~ s/^MYFILTER//; return $_[0]; }

my $dbm_factory = new_dbm();
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    ok( !$db->set_filter( 'floober', sub {} ), "floober isn't a value filter key" );

    ##
    # First try store filters only (values will be unfiltered)
    ##
    ok( $db->set_filter( 'store_key', \&my_filter_store_key ), "set the store_key filter" );
    ok( $db->set_filter( 'store_value', \&my_filter_store_value ), "set the store_value filter" );

    $db->{key1} = "value1";
    $db->{key2} = "value2";

    is($db->{key1}, "MYFILTERvalue1", "The value for key1 was filtered correctly" );
    is($db->{key2}, "MYFILTERvalue2", "The value for key2 was filtered correctly" );

    ##
    # Now try fetch filters as well
    ##
    ok( $db->set_filter( 'fetch_key', \&my_filter_fetch_key ), "Set the fetch_key filter" );
    ok( $db->set_filter( 'fetch_value', \&my_filter_fetch_value), "Set the fetch_value filter" );

    is($db->{key1}, "value1", "Fetchfilters worked right");
    is($db->{key2}, "value2", "Fetchfilters worked right");

    ##
    # Try fetching keys as well as values
    ##
    cmp_bag( [ keys %$db ], [qw( key1 key2 )], "DB keys correct" );

    # Exists and delete tests
    ok( exists $db->{key1}, "Key1 exists" );
    ok( exists $db->{key2}, "Key2 exists" );

    is( delete $db->{key1}, 'value1', "Delete returns the right value" );

    ok( !exists $db->{key1}, "Key1 no longer exists" );
    ok( exists $db->{key2}, "Key2 exists" );

    ##
    # Now clear all filters, and make sure all is unfiltered
    ##
    ok( $db->filter_store_key( undef ), "Unset store_key filter" );
    ok( $db->filter_store_value( undef ), "Unset store_value filter" );
    ok( $db->filter_fetch_key( undef ), "Unset fetch_key filter" );
    ok( $db->filter_fetch_value( undef ), "Unset fetch_value filter" );

    is( $db->{MYFILTERkey2}, "MYFILTERvalue2", "We get the right unfiltered value" );
}

done_testing;
