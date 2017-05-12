use strict;
use warnings;

use Test::More tests => 5;

use Chart::OFC::Dataset;


{
    eval { Chart::OFC::Dataset->new() };
    like( $@, qr/\Q(values) is required/, 'values is required for constructor' );

    eval { Chart::OFC::Dataset->new( values => [] ) };
    like( $@, qr/\Qpass the type constraint\E.+\Qcannot be empty/, 'values cannot be empty' );

    eval { Chart::OFC::Dataset->new( values => [ 1, 2, 'a' ] ) };
    like( $@, qr/\Qpass the type constraint\E.+\Qcontain only numbers/, 'values must all be numbers' );
}

{
    my $ds = Chart::OFC::Dataset->new( values => [ 1, 2 ] );
    is_deeply( [ $ds->values() ], [ 1, 2 ], 'check values() attribute' );
}

{
    my $ds = Chart::OFC::Dataset->new( values => [ 1, 2, 3.5, 99.9 ] );
    is_deeply( [ $ds->values() ], [ 1, 2, 3.5, 99.9 ],
               'check values() attribute, mixed ints and floats are ok' );
}

