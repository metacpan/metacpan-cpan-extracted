#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use App::Dazz::Common;

{
    print "#lcss\n";

    my @data = (

        [   [   qw{ ab
                    b }
            ],
            undef,
        ],

        [   [   qw{ abc
                    bc }
            ],
            "bc",
        ],

        [   [   qw{ xyzzx
                    abcxyzefg }
            ],
            "xyz",
        ],

        [   [   qw{ abcxyzzx
                    abcxyzefg }
            ],
            "abcxyz",
        ],

        [   [   qw{ foobar
                    abcxyzefg }
            ],
            undef,
        ],

    );

    for my $i ( 0 .. $#data ) {
        my ( $refs, $expect ) = @{ $data[$i] };

        my $result = App::Dazz::Common::lcss( @{$refs} );
        is( $result, $expect, "lcss $i" );
    }
}

{
    print "#lcss array\n";

    my @data = (

        [   [   qw{ xyzzx
                    abcxyzefg }
            ],
            [qw{xyz 0 3}],
        ],

        [   [   qw{ AbCdefg
                    AbCDef }
            ],
            [qw{AbC 0 0}],
        ],

    );

    for my $i ( 0 .. $#data ) {
        my ( $refs, $expect ) = @{ $data[$i] };

        my @results = App::Dazz::Common::lcss( @{$refs} );
        is_deeply( \@results, $expect, "lcss array $i" );
    }
}

{
    print "#histogram\n";
    my @bins = ( 1 .. 100 );
    my %hist_of = map { ( $_, 1 ) } @bins;

    is( App::Dazz::Common::histogram_percentile( \%hist_of, 0.5 ), 50,  "median" );
    is( App::Dazz::Common::histogram_percentile( \%hist_of, 0.25 ), 25,  "quartile" );
    is( App::Dazz::Common::histogram_percentile( \%hist_of, 1 ),   100, "all" );
}

done_testing();
