use strict;
use warnings;

use Test::More;
use AlignDB::IntSpan;

use AlignDB::GC;

{
    print "#gc_wave\n";

    my $GC = AlignDB::GC->new(
        wave_window_size => 20,
        wave_window_step => 10,
    );

    my @data = (
        [   [   [ "ATGAGTCAAGAAAACAGGTAACAGAATAGCAGTAGCAATTTCATACCACCCAT" x 5 ],
                AlignDB::IntSpan->new->add_pair( 1, 250 ),
            ],
            [ 24, "NNNNNNNNNNNNNNNNNNNNCNNN" ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $input_ref, $except_ref ) = @{ $data[$i] };

        my @results = $GC->gc_wave( @{$input_ref} );
        my $str = join "", map { $_->{high_low_flag} } @results;
        is( scalar(@results), $except_ref->[0], "gc_wave $i" );
        is( $str, $except_ref->[1], "gc_wave $i" );
    }
}

done_testing();
