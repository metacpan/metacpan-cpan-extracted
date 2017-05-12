use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Deep;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

my $dbm_factory = new_dbm(
    locking   => 1,
    autoflush => 1,
);
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    for ( 1 .. 17 ) {
        $db->{ $_ } = $_;
        is( $db->{$_}, $_, "Addition of $_ is still $_" );
    }

    for ( 1 .. 17 ) {
        is( $db->{$_}, $_, "Verification of $_ is still $_" );
    }

    my @keys = keys %$db;
    cmp_ok( scalar(@keys), '==', 17, "Right number of keys returned" );

    ok( !exists $db->{does_not_exist}, "EXISTS works on large hashes for non-existent keys" );
    $db->{does_not_exist}{ling} = undef;
    ok( $db->{does_not_exist}, "autovivification works on large hashes" );
    ok( exists $db->{does_not_exist}, "EXISTS works on large hashes for newly-existent keys" );
    cmp_ok( scalar(keys %$db), '==', 18, "Number of keys after autovivify is correct" );
}

done_testing;
