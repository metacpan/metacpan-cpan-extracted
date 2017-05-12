use strict;
use warnings;

use Test::More;
use AlignDB::IntSpan;

use AlignDB::Window;

{
    print "#strand_window\n";

    my $maker = AlignDB::Window->new( max_out_distance => 2, );

    my @data = (
        [ [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 500, 500 ], [], ],
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 500, 600, 100, "-" ],
            [   {   distance => 1,
                    set      => "501-600",
                    type     => "-",
                }
            ],
        ],
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 500, 1000 ],
            [   {   distance => 1,
                    set      => "500-599",
                    type     => "+",
                },
                {   distance => 2,
                    set      => "600-699",
                    type     => "+",
                },
                {   distance => 3,
                    set      => "700-799",
                    type     => "+",
                },
                {   distance => 4,
                    set      => "800-899",
                    type     => "+",
                },
                {   distance => 5,
                    set      => "900-999",
                    type     => "+",
                },
            ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $input_ref, $except_ref ) = @{ $data[$i] };

        my @results = $maker->strand_window( @{$input_ref} );
        $_->{set} = $_->{set}->runlist for @results;
        is_deeply( \@results, $except_ref, "strand window $i" );
    }
}

done_testing();
