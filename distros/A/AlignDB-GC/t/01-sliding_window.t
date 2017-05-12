use strict;
use warnings;

use Test::More;
use AlignDB::IntSpan;

use AlignDB::GC;

{
    print "#sliding_window\n";

    my $GC = AlignDB::GC->new(
        wave_window_size => 100,
        wave_window_step => 50,
    );

    my @data = (
        [ [ AlignDB::IntSpan->new->add_pair( 1, 101 ), ], ["1-100"], ],
        [ [ AlignDB::IntSpan->new->add_pair( 1, 199 ), ], [ "1-100", "51-150", ], ],
        [ [ AlignDB::IntSpan->new->add_pair( 1, 101 ), 10, 50 ], [ "1-10", "51-60", ], ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $input_ref, $except_ref ) = @{ $data[$i] };

        my @results = $GC->sliding_window( @{$input_ref} );
        $_ = $_->runlist for @results;
        is_deeply( \@results, $except_ref, "sliding_window $i" );
    }

}

done_testing();
