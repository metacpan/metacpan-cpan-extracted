use strict;
use warnings;
use Algorithm::FeatureSelection;
use Test::More tests => 5;

my $fs = Algorithm::FeatureSelection->new();
isa_ok( $fs, 'Algorithm::FeatureSelection' );

# As for the case same two values, the maximum entropy becomes 1.
my $data = {
    red  => 10,
    blue => 10,
};
is( $fs->entropy($data), 1 );

# argument can be hash-ref data structure.
$data = {
    red    => 35,
    blue   => 20,
    yellow => 20,
    green  => 15,
    whiite => 10,
};
is( sprintf( "%6.4f", $fs->entropy($data) ), 2.2016 );

# argument can be array-ref data structure.
$data = [ 35, 20, 20, 15, 10 ];
is( sprintf("%6.4f", $fs->entropy($data)), 2.2016 );

# argument can be array data structure.
$data = [ 0.35, 0.2, 0.2, 0.15, 0.1 ];
is( sprintf("%6.4f", $fs->entropy($data)), 2.2016 );
