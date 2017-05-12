use strict;
use Algorithm::DimReduction;
use Test::More;

# check whether Octave is installed or not
my $octave_path = `/usr/bin/which octave`;
chomp $octave_path;
if ( !-e $octave_path ) {
    plan skip_all => 'Skip some tests because Octave is not installed';
}
else {
    plan tests => 3;
}

# test matrix. its a just array reference
my $matrix = [
    [ 1,  2,  3,  4,  5 ],
    [ 6,  7,  8,  9,  10 ],
    [ 11, 12, 13, 14, 15 ],
    [ 16, 17, 18, 19, 20 ],
];

# analyze and result test
{
    my $reductor = Algorithm::DimReduction->new;
    my $result   = $reductor->analyze($matrix);
    my $correct  = [
        {
            'rate'      => '0.947634',
            'reduct_to' => 1
        },
        {
            'rate'      => '1',
            'reduct_to' => 2
        },
        {
            'rate'      => '1',
            'reduct_to' => 3
        },
        {
            'rate'      => '1',
            'reduct_to' => 4
        }
    ];
    is_deeply( $result->contribution_rate, $correct,
        "contribution_rate() returns correct data" );
}

# save_analyze test
{
    my $reductor = Algorithm::DimReduction->new;
    my $result   = $reductor->analyze($matrix);
    $reductor->save_analyzed( $result, '/tmp' );
    is( ( -e '/tmp/svd.oct' ), 1, 'save_analyzed() output svd.oct file' );
}

# load and reduce test
{
    my $reductor       = Algorithm::DimReduction->new;
    my $result         = $reductor->load_analyzed('/tmp');
    my $reduced_matrix = $reductor->reduce( $result, 2 );
    my $correct = [
        [ '-0.957430478227885', '-1.42073262329549' ],
        [ '-2.4777069982605',   '-0.739951937560792' ],
        [ '-3.99798351829312',  '-0.0591712518261' ],
        [ '-5.51826003832574',  '0.621609433908591' ]
    ];
    is_deeply( $reduced_matrix, $correct, "reduce() returns correct data" );
}

