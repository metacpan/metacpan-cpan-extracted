use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Deep;

use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

my $dbm_factory = new_dbm();
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    # Add a self-referencing connection to test export
    my %struct = (
        key1 => "value1",
        key2 => "value2",
        array1 => [ "elem0", "elem1", "elem2", { foo => 'bar' }, [ 5 ], bless( [], 'Apple' ) ],
        hash1 => {
            subkey1 => "subvalue1",
            subkey2 => "subvalue2",
            subkey3 => bless( {
                sub_obj => bless([
                    bless([], 'Foo'),
                ], 'Foo'),
                sub_obj3 => bless([],'Foo'),
            }, 'Foo' ),
        },
    );

    $db->{foo} = \%struct;

    my $x = delete $db->{foo};

    cmp_deeply(
        $x,
        {
            key1 => "value1",
            key2 => "value2",
            array1 => [ "elem0", "elem1", "elem2", { foo => 'bar' }, [ 5 ], bless( [], 'Apple' ) ],
            hash1 => {
                subkey1 => "subvalue1",
                subkey2 => "subvalue2",
                subkey3 => bless( {
                    sub_obj => bless([
                        bless([], 'Foo'),
                    ], 'Foo'),
                    sub_obj3 => bless([],'Foo'),
                }, 'Foo' ),
            },
        },
        "Everything matches",
    );
}

done_testing;
