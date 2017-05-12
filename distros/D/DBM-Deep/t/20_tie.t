use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use t::common qw( new_fh );

use_ok( 'DBM::Deep' );

# testing the various modes of opening a file
{
    my ($fh, $filename) = new_fh();
    my %hash;
    my $db = tie %hash, 'DBM::Deep', $filename;

    ok(1, "Tied an hash with an array for params" );
}

{
    my ($fh, $filename) = new_fh();
    my %hash;
    my $db = tie %hash, 'DBM::Deep', {
        file => $filename,
    };

    ok(1, "Tied a hash with a hashref for params" );
}

{
    my ($fh, $filename) = new_fh();
    my @array;
    my $db = tie @array, 'DBM::Deep', $filename;

    ok(1, "Tied an array with an array for params" );

    is( $db->{type}, DBM::Deep->TYPE_ARRAY, "TIE_ARRAY sets the correct type" );
}

{
    my ($fh, $filename) = new_fh();
    my @array;
    my $db = tie @array, 'DBM::Deep', {
        file => $filename,
    };

    ok(1, "Tied an array with a hashref for params" );

    is( $db->{type}, DBM::Deep->TYPE_ARRAY, "TIE_ARRAY sets the correct type" );
}

my ($fh, $filename) = new_fh();
throws_ok {
    tie my %hash, 'DBM::Deep', [ file => $filename ];
} qr/Not a hashref/, "Passing an arrayref to TIEHASH fails";

throws_ok {
    tie my @array, 'DBM::Deep', [ file => $filename ];
} qr/Not a hashref/, "Passing an arrayref to TIEARRAY fails";

throws_ok {
    tie my %hash, 'DBM::Deep', undef, file => $filename;
} qr/Odd number of parameters/, "Odd number of params to TIEHASH fails";

throws_ok {
    tie my @array, 'DBM::Deep', undef, file => $filename;
} qr/Odd number of parameters/, "Odd number of params to TIEARRAY fails";

done_testing;
