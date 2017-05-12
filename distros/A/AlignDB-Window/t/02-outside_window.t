use strict;
use warnings;

use Test::More;
use AlignDB::IntSpan;

use AlignDB::Window;

{
    print "#outside_window\n";

    my $maker = AlignDB::Window->new( max_out_distance => 2, );

    my @data = (
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 500, 500 ],
            [   {   distance => 1,
                    set      => "400-499",
                    type     => "L",
                },
                {   distance => 2,
                    set      => "300-399",
                    type     => "L",
                },
                {   distance => 1,
                    set      => "501-600",
                    type     => "R",
                },
                {   distance => 2,
                    set      => "601-700",
                    type     => "R",
                },
            ],
        ],
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 500, 600 ],
            [   {   distance => 1,
                    set      => "400-499",
                    type     => "L",
                },
                {   distance => 2,
                    set      => "300-399",
                    type     => "L",
                },
                {   distance => 1,
                    set      => "601-700",
                    type     => "R",
                },
                {   distance => 2,
                    set      => "701-800",
                    type     => "R",
                },
            ],
        ],
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 101, 101 ],
            [   {   distance => 1,
                    set      => "1-100",
                    type     => "L",
                },
                {   distance => 1,
                    set      => "102-201",
                    type     => "R",
                },
                {   distance => 2,
                    set      => "202-301",
                    type     => "R",
                },
            ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $input_ref, $except_ref ) = @{ $data[$i] };

        my @results = $maker->outside_window( @{$input_ref} );
        $_->{set} = $_->{set}->runlist for @results;
        is_deeply( \@results, $except_ref, "outside window $i" );
    }
}

{
    print "#outside_window_2\n";

    my $maker = AlignDB::Window->new( max_out_distance => 1, );

    my @data = (
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 500, 500 ],
            [   {   distance => 0,
                    set      => "450-499",
                    type     => "L",
                },
                {   distance => 1,
                    set      => "350-449",
                    type     => "L",
                },
                {   distance => 0,
                    set      => "501-550",
                    type     => "R",
                },
                {   distance => 1,
                    set      => "551-650",
                    type     => "R",
                },
            ],
        ],
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 101, 101 ],
            [   {   distance => 0,
                    set      => "51-100",
                    type     => "L",
                },
                {   distance => 0,
                    set      => "102-151",
                    type     => "R",
                },
                {   distance => 1,
                    set      => "152-251",
                    type     => "R",
                },
            ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $input_ref, $except_ref ) = @{ $data[$i] };

        my @results = $maker->outside_window_2( @{$input_ref} );
        $_->{set} = $_->{set}->runlist for @results;
        is_deeply( \@results, $except_ref, "outside_window_2 $i" );
    }
}

done_testing();
