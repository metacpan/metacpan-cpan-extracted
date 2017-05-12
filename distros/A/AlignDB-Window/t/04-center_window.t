use strict;
use warnings;

use Test::More;
use AlignDB::IntSpan;

use AlignDB::Window;

{
    print "#center_window\n";

    my $maker = AlignDB::Window->new( max_out_distance => 1, );

    my @data = (
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 500, 500 ],
            [   {   distance => 0,
                    set      => "451-549",
                    type     => "M",
                },
                {   distance => 1,
                    set      => "351-450",
                    type     => "L",
                },
                {   distance => 1,
                    set      => "550-649",
                    type     => "R",
                },
            ],
        ],
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 500, 800 ],
            [   {   distance => 0,
                    set      => "600-699",
                    type     => "M",
                },
                {   distance => 1,
                    set      => "500-599",
                    type     => "L",
                },
                {   distance => 1,
                    set      => "700-799",
                    type     => "R",
                },
            ],
        ],
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 101, 101 ],
            [   {   distance => 0,
                    set      => "52-150",
                    type     => "M",
                },
                {   distance => 1,
                    set      => "151-250",
                    type     => "R",
                },
            ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $input_ref, $except_ref ) = @{ $data[$i] };

        my @results = $maker->center_window( @{$input_ref} );
        $_->{set} = $_->{set}->runlist for @results;
        is_deeply( \@results, $except_ref, "center window $i" );
    }
}

{
    print "#center_intact_window\n";

    my $maker = AlignDB::Window->new( max_out_distance => 1, );

    my @data = (
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 500, 500 ],
            [   {   distance => 0,
                    set      => "451-549",
                    type     => "M",
                },
                {   distance => 1,
                    set      => "351-450",
                    type     => "L",
                },
                {   distance => 1,
                    set      => "550-649",
                    type     => "R",
                },
            ],
        ],
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 500, 800 ],
            [   {   distance => 0,
                    set      => "500-800",
                    type     => "M",
                },
                {   distance => 1,
                    set      => "400-499",
                    type     => "L",
                },
                {   distance => 1,
                    set      => "801-900",
                    type     => "R",
                },
            ],
        ],
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 101, 101 ],
            [   {   distance => 0,
                    set      => "52-150",
                    type     => "M",
                },
                {   distance => 1,
                    set      => "151-250",
                    type     => "R",
                },
            ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $input_ref, $except_ref ) = @{ $data[$i] };

        my @results = $maker->center_intact_window( @{$input_ref} );
        $_->{set} = $_->{set}->runlist for @results;
        is_deeply( \@results, $except_ref, "center_intact_window $i" );
    }
}

done_testing();
