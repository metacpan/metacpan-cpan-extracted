use strict;
use warnings;

use Test::More;
use Test::Number::Delta within => 1e-2;
use AlignDB::IntSpan;

use AlignDB::GC;

{
    print "#segment\n";

    my $GC = AlignDB::GC->new(
        wave_window_size => 100,
        wave_window_step => 50,
    );

    my @data = (
        [ [ AlignDB::IntSpan->new->add_pair( 1, 101 ), ], [ "1-101", ], ],
        [ [ AlignDB::IntSpan->new->add_pair( 1, 199 ), ], [ "1-199", ], ],
        [ [ AlignDB::IntSpan->new->add_pair( 1, 101 ), 10, 50, ], [ "1-10", "51-60", ], ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $input_ref, $except_ref ) = @{ $data[$i] };

        my @results = $GC->segment( @{$input_ref} );
        $_ = $_->runlist for @results;
        is_deeply( \@results, $except_ref, "segment $i" );
    }
}

{
    print "#segment_gc_stat\n";

    my $GC = AlignDB::GC->new(
        stat_window_size => 50,
        stat_window_step => 50,
    );

    my @data = (
        [ [ [ "AC" x 100, ], AlignDB::IntSpan->new->add_pair( 1, 101 ), ], [ 0.5, 0, 0, 0, ], ],
        [ [ [ "AC" x 100, ], AlignDB::IntSpan->new->add_pair( 1, 200 ), ], [ 0.5, 0, 0, 0, ], ],
        [   [ [ "ACC" x 20 . "ATG" x 50, ], AlignDB::IntSpan->new->add_pair( 1, 101 ), ],
            [ 0.53, 0.1838, 0.3912, 0.26, ],
        ],
        [   [ [ "ACC" x 20 . "ATG" x 50, ], AlignDB::IntSpan->new->add_pair( 1, 200 ), ],
            [ 0.43, 0.1571, 0.3652, 0.1133, ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $input_ref, $except_ref ) = @{ $data[$i] };

        my @results = $GC->segment_gc_stat( @{$input_ref}, );

        #        $_ = $_->runlist for @results;
        Test::Number::Delta::delta_ok( \@results, $except_ref, "segment_gc_stat $i" );
    }
}

{
    print "#segment_gc_stat_one\n";

    my $GC = AlignDB::GC->new;

    my @data = (
        [   [   [ "ATC" x 500, ],
                AlignDB::IntSpan->new->add_pair( 1,    1500 ),
                AlignDB::IntSpan->new->add_pair( 1000, 1100 ),
            ],
            [ 0.327, 0.016, ],
        ],
        [   [   [ "ATCCTTT" x 500, ],
                AlignDB::IntSpan->new->add_pair( 1,    3500 ),
                AlignDB::IntSpan->new->add_pair( 1000, 1100 ),
            ],
            [ 0.277, 0.029, ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $input_ref, $except_ref ) = @{ $data[$i] };

        my @results = grep {defined} $GC->segment_gc_stat_one( @{$input_ref}, );

        #        $_ = $_->runlist for @results;
        Test::Number::Delta::delta_ok( \@results, $except_ref, "segment_gc_stat_one $i" );
    }
}

done_testing();
