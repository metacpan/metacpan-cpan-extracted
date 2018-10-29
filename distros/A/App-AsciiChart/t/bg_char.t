use strict;
use warnings;

use Test::More;
use App::AsciiChart;

subtest 'basic test' => sub {
    my $chart = App::AsciiChart->new(bg_char => ' ');

    my $plot = $chart->plot( [ 1, 2, 3 ] );

    is $plot, <<'EOF';
3┤ ╭ 
2┤╭╯ 
1┼╯  
EOF
};

done_testing;
