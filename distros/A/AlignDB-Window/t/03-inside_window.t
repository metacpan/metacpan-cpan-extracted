use strict;
use warnings;

use Test::More;
use AlignDB::IntSpan;

use AlignDB::Window;

{
    print "#inside_window\n";

    my $maker = AlignDB::Window->new( max_in_distance => 2, );

    my @data = (
        [ [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 500, 698 ], [], ],
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 500, 700 ],
            [   {   distance => -1,
                    set      => "500-599",
                    type     => "l",
                },
                {   distance => -1,
                    set      => "601-700",
                    type     => "r",
                },
            ],
        ],
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 500, 1000 ],
            [   {   distance => -1,
                    set      => "500-599",
                    type     => "l",
                },
                {   distance => -2,
                    set      => "600-699",
                    type     => "l",
                },
                {   distance => -1,
                    set      => "901-1000",
                    type     => "r",
                },
                {   distance => -2,
                    set      => "801-900",
                    type     => "r",
                },
            ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $input_ref, $except_ref ) = @{ $data[$i] };

        my @results = $maker->inside_window( @{$input_ref} );
        $_->{set} = $_->{set}->runlist for @results;
        is_deeply( \@results, $except_ref, "inside window $i" );
    }
}

{
    print "#inside_window_2\n";

    my $maker = AlignDB::Window->new( max_in_distance => 2, );

    my @data = (
        [ [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 500, 698 ], [], ],
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 500, 700 ],
            [   {   distance => -90,
                    set      => "500-599",
                    type     => "l",
                },
                {   distance => -90,
                    set      => "600-699",
                    type     => "r",
                },
            ],
        ],
        [   [ AlignDB::IntSpan->new->add_pair( 1, 9999 ), 500, 1000 ],
            [   {   distance => -90,
                    set      => "650-749",
                    type     => "l",
                },
                {   distance => -89,
                    set      => "550-649",
                    type     => "l",
                },
                {   distance => -90,
                    set      => "750-849",
                    type     => "r",
                },
                {   distance => -89,
                    set      => "850-949",
                    type     => "r",
                },
            ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $input_ref, $except_ref ) = @{ $data[$i] };

        my @results = $maker->inside_window_2( @{$input_ref} );
        $_->{set} = $_->{set}->runlist for @results;
        is_deeply( \@results, $except_ref, "inside_window_2 $i" );
    }
}

done_testing();
