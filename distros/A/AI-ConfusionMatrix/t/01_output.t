use Test::More tests => 4;

require_ok( 'AI::ConfusionMatrix' );
use AI::ConfusionMatrix;
use Tie::File;
use File::Temp 'tempfile';

my $hash = {
    1978 => {
        1978 => 5,
        1974 => 1,
    },
    2005 => {
        1978 => 1,
        2005 => 3,
        2002 => 1
    },
    2003 => {
        2005 => 2,
        2003 => 7,
    }
};

my $fh = tempfile();
makeConfusionMatrix($hash, $fh);

tie my @array, 'Tie::File', $fh or die "$!";

is($array[0], ',1974,1978,2002,2003,2005,TOTAL,TP,FP,FN,ACC', 'Column Headers');
is($array[3], '2005,,1,1,,3,5,3,2,2,60.00%', 'Sample result');
is($array[4], 'TOTAL,1,6,1,7,5,20,15,3,5,75.00%', 'Total line');

untie @array;
close $fh;

