use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Deep;
use Test::Exception;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

# Failure cases to make sure that things are caught right.
foreach my $type ( DBM::Deep->TYPE_HASH, DBM::Deep->TYPE_ARRAY ) {
    my $dbm_factory = new_dbm( type => $type );
    while ( my $dbm_maker = $dbm_factory->() ) {
        my $db = $dbm_maker->();

        # Load a scalar
        throws_ok {
            $db->import( 'foo' );
        } qr/Cannot import a scalar/, "Importing a scalar to type '$type' fails";

        # Load a ref of the wrong type
        # Load something with bad stuff in it
        my $x = 3;
        if ( $type eq 'A' ) {
            throws_ok {
                $db->import( { foo => 'bar' } );
            } qr/Cannot import a hash into an array/, "Wrong type fails";

            throws_ok {
                $db->import( [ \$x ] );
            } qr/Storage of references of type 'SCALAR' is not supported/, "Bad stuff fails";
        }
        else {
            throws_ok {
                $db->import( [ 1 .. 3 ] );
            } qr/Cannot import an array into a hash/, "Wrong type fails";

            throws_ok {
                $db->import( { foo => \$x } );
            } qr/Storage of references of type 'SCALAR' is not supported/, "Bad stuff fails";
        }
    }
}

my $dbm_factory = new_dbm( autobless => 1 );
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    ##
    # Create structure in memory
    ##
    my $struct = {
        key1 => "value1",
        key2 => "value2",
        array1 => [ "elem0", "elem1", "elem2" ],
        hash1 => {
            subkey1 => "subvalue1",
            subkey2 => "subvalue2",
            subkey3 => bless( { a => 'b' }, 'Foo' ),
        }
    };

    $db->import( $struct );

    cmp_deeply(
        $db,
        noclass({
            key1 => 'value1',
            key2 => 'value2',
            array1 => [ 'elem0', 'elem1', 'elem2', ],
            hash1 => {
                subkey1 => "subvalue1",
                subkey2 => "subvalue2",
                subkey3 => useclass( bless { a => 'b' }, 'Foo' ),
            },
        }),
        "Everything matches",
    );

    $struct->{foo} = 'bar';
    is( $struct->{foo}, 'bar', "\$struct has foo and it's 'bar'" );
    ok( !exists $db->{foo}, "\$db doesn't have the 'foo' key, so \$struct is not tied" );

    $struct->{hash1}->{foo} = 'bar';
    is( $struct->{hash1}->{foo}, 'bar', "\$struct->{hash1} has foo and it's 'bar'" );
    ok( !exists $db->{hash1}->{foo}, "\$db->{hash1} doesn't have the 'foo' key, so \$struct->{hash1} is not tied" );
}

$dbm_factory = new_dbm( type => DBM::Deep->TYPE_ARRAY );
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    my $struct = [
        1 .. 3,
        [ 2, 4, 6 ],
        bless( [], 'Bar' ),
        { foo => [ 2 .. 4 ] },
    ];

    $db->import( $struct );

    cmp_deeply(
        $db,
        noclass([
            1 .. 3,
            [ 2, 4, 6 ],
            useclass( bless( [], 'Bar' ) ),
            { foo => [ 2 .. 4 ] },
        ]),
        "Everything matches",
    );

    push @$struct, 'bar';
    is( $struct->[-1], 'bar', "\$struct has 'bar' at the end" );
    ok( $db->[-1], "\$db doesn't have the 'bar' value at the end, so \$struct is not tied" );
}

# Failure case to verify that rollback occurs
$dbm_factory = new_dbm( autobless => 1 );
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    $db->{foo} = 'bar';

    my $x;
    my $struct = {
        key1 => [
            2, \$x, 3,
        ],
    };

    eval {
        $db->import( $struct );
    };
    like( $@, qr/Storage of references of type 'SCALAR' is not supported/, 'Error message correct' );

    TODO: {
        local $TODO = "Importing cannot occur within a transaction yet.";
        cmp_deeply(
            $db,
            noclass({
                foo => 'bar',
            }),
            "Everything matches",
        );
    }
}

done_testing;

__END__

Need to add tests for:
    - Failure case (have something tied or a glob or something like that)
    - Where we already have $db->{hash1} to make sure that it's not overwritten
