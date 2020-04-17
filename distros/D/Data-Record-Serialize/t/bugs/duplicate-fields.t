#! perl

use Test2::V0;
use Data::Record::Serialize;

like(
    dies {
        my $drs = Data::Record::Serialize->new(
            fields => [ 'a', 'b', 'b' ],
            encode => 'null'
                                              );
        $drs->send( { a => 1, b => 2 } );
    },
    qr/duplicate output field/
);

done_testing;
