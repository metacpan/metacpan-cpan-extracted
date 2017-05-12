use strict;
use warnings FATAL => 'all';

use Test::More;

plan skip_all => "You must set \$ENV{LONG_TESTS} to run the long tests"
    unless $ENV{LONG_TESTS};

use Test::Deep;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

diag "This test can take up to several minutes to run. Please be patient.";

my $dbm_factory = new_dbm( type => DBM::Deep->TYPE_HASH );
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    $db->{foo} = {};
    my $foo = $db->{foo};

    ##
    # put/get many keys
    ##
    my $max_keys = 4000;

    for ( 0 .. $max_keys ) {
        $foo->put( "hello $_" => "there " . $_ * 2 );
    }

    my $count = -1;
    for ( 0 .. $max_keys ) {
        $count = $_;
        unless ( $foo->get( "hello $_" ) eq "there " . $_ * 2 ) {
            last;
        };
    }
    is( $count, $max_keys, "We read $count keys" );

    my @keys = sort keys %$foo;
    cmp_ok( scalar(@keys), '==', $max_keys + 1, "Number of keys is correct" );
    my @control =  sort map { "hello $_" } 0 .. $max_keys;
    cmp_deeply( \@keys, \@control, "Correct keys are there" );

    ok( !exists $foo->{does_not_exist}, "EXISTS works on large hashes for non-existent keys" );
    $foo->{does_not_exist}{ling} = undef;
    ok( $foo->{does_not_exist}, "autovivification works on large hashes" );
    ok( exists $foo->{does_not_exist}, "EXISTS works on large hashes for newly-existent keys" );
    cmp_ok( scalar(keys %$foo), '==', $max_keys + 2, "Number of keys after autovivify is correct" );

    $db->clear;
    cmp_ok( scalar(keys %$db), '==', 0, "Number of keys after clear() is correct" );
}

done_testing;
