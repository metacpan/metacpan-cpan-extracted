use strict;
use warnings FATAL => 'all';

use Test::More;
use t::common qw( new_fh );

use_ok( 'DBM::Deep' );

use Scalar::Util qw( reftype );

{
    my ($fh, $filename) = new_fh();

    my %hash;
    my $obj = tie %hash, 'DBM::Deep', $filename;
    isa_ok( $obj, 'DBM::Deep' );
    is( reftype( $obj ), 'HASH', "... and its underlying representation is an HASH" );
}

{
    my ($fh, $filename) = new_fh();

    my @array;
    my $obj = tie @array, 'DBM::Deep', $filename;
    isa_ok( $obj, 'DBM::Deep' );
    is( reftype( $obj ), 'HASH', "... and its underlying representation is an HASH" );
}

done_testing;
