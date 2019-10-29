use Test::More tests => 13;

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

is($array[0], ',1974,1978,2002,2003,2005,TOTAL,TP,FP,FN,SENS,ACC', 'Column Headers');
is($array[3], '2005,,1,1,,3,5,3,2,2,60.00%,60.00%', 'Sample result');
is($array[4], 'TOTAL,1,6,1,7,5,20,15,3,5,83.33%,75.00%', 'Total line');

untie @array;

close $fh;

my $fh2 = tempfile();

makeConfusionMatrix($hash, $fh2, ';');

tie my @array2, 'Tie::File', $fh2 or die "$!";

is($array2[0], ';1974;1978;2002;2003;2005;TOTAL;TP;FP;FN;SENS;ACC', 'Column Headers with a custom delimiter');
is($array2[3], '2005;;1;1;;3;5;3;2;2;60.00%;60.00%', 'Sample result with a custom delimiter');
is($array2[4], 'TOTAL;1;6;1;7;5;20;15;3;5;83.33%;75.00%', 'Total line with a custom delimiter');

untie @array2;

makeConfusionMatrix($hash, $fh2, ';');

tie my @array2, 'Tie::File', $fh2 or die "$!";

is($array2[0], ';1974;1978;2002;2003;2005;TOTAL;TP;FP;FN;SENS;ACC',
               'Reuse csv - Column Headers with a custom delimiter');
is($array2[3], '2005;;1;1;;3;5;3;2;2;60.00%;60.00%',
               'Reuse csv - Sample result with a custom delimiter');
is($array2[4], 'TOTAL;1;6;1;7;5;20;15;3;5;83.33%;75.00%',
               'Reuse csv - Total line with a custom delimiter');

untie @array2;

close $fh2;



my $hash2 = {
    'apple' => {
        'apple' => 7,
        'fish' => 6
    },
    'fish' => {
        'apple' => 8,
        'fish' => 8
    },
    'pants' => {
        'apple' => 5,
        'fish' => 1,
        'pants' => 1
     }
};

my $fh3 = tempfile();
makeConfusionMatrix($hash2, $fh3);

tie my @array3, 'Tie::File', $fh3 or die "$!";

is($array3[0], ',apple,fish,pants,TOTAL,TP,FP,FN,SENS,ACC', 'Column Headers');
is($array3[3], 'pants,5,1,1,7,1,0,6,100.00%,14.29%', 'Sample result');
is($array3[4], 'TOTAL,20,15,1,36,16,20,20,44.44%,44.44%', 'Total line');

untie @array3;

close $fh3;
