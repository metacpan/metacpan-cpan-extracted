use strict;
use warnings;

use Test::More;

use AlignDB::Codon;

{    # compare normal codons
    my $codon = AlignDB::Codon->new( table_id => 1 );

    my @compare
        = ( [qw{ TTT TTA }], [qw{ TTT TTC }], [qw{ TTT GTA }], [qw{ TTT GTG }], [qw{ TTG AGA }], );

    my @expect
        = ( [ 0, 1 ], [ 1, 0 ], [ 0.5, 1.5 ], [ 0.5, 1.5 ], [ 0.75, 2.25 ], );

    for my $i ( 0 .. $#compare ) {
        my ( $exp1, $exp2 ) = @{ $expect[$i] };
        my ( $syn,  $nsy )  = $codon->comp_codons( @{ $compare[$i] } );
        is( $syn, $exp1, "syn $i" );
        is( $nsy, $exp2, "nsy $i" );
    }
}

{    # compare normal codons with frames
    my $codon = AlignDB::Codon->new( table_id => 1 );

    my @compare = (
        [qw{ TTT TTA 2 }], [qw{ TTT TTA 0 }], [qw{ TTT TTC 2 }], [qw{ TTT TTC 1 }],
        [qw{ TTT GTA 0 }], [qw{ TTT GTA 1 }], [qw{ TTT GTA 2 }], [qw{ TTG AGA 0 }],
        [qw{ TTG AGA 1 }], [qw{ TTG AGA 2 }],
    );

    my @expect = (
        [ 0,    1 ],
        [ 0,    0 ],
        [ 1,    0 ],
        [ 0,    0 ],
        [ 0,    1 ],
        [ 0,    0 ],
        [ 0.5,  0.5 ],
        [ 0,    1 ],
        [ 0,    1 ],
        [ 0.75, 0.25 ],

    );

    for my $i ( 0 .. $#compare ) {
        my ( $exp1, $exp2 ) = @{ $expect[$i] };
        my ( $syn,  $nsy )  = $codon->comp_codons( @{ $compare[$i] } );
        is( $syn, $exp1, "syn_pos $i" );
        is( $nsy, $exp2, "nsy_pos $i" );
    }

}

{    # gaps in codons
    my $codon = AlignDB::Codon->new( table_id => 1 );

    my @compare
        = ( [qw{ --- TTA }], [qw{ TTT --A }], );

    for my $i ( 0 .. $#compare ) {
        my ( $exp1, $exp2 ) = ( 0, 0 );
        my ( $syn, $nsy ) = $codon->comp_codons( @{ $compare[$i] } );
        is( $syn, $exp1, "syn $i" );
        is( $nsy, $exp2, "nsy $i" );
    }
}

{    # wrong codons
    my @compare
        = ( [qw{ XTT TTA }], [qw{ TTT TXA }], );

    for my $i ( 0 .. $#compare ) {
        eval { AlignDB::Codon->new->comp_codons( @{ $compare[$i] } ); };
        like( $@, qr{Wrong codon}i, "Wrong codon" );
    }
}

{    # Wrong codon position
    my @compare
        = ( [qw{ TTT TTA -1 }], [qw{ TTT TTA 6 }], );

    for my $i ( 0 .. $#compare ) {
        eval { AlignDB::Codon->new->comp_codons( @{ $compare[$i] } ); };
        like( $@, qr{Wrong codon position}i, "Wrong codon position" );
    }
}

{    # Codon length error
    my @compare
        = ( [qw{ TTT TT }], [qw{ TT TTA}], );

    for my $i ( 0 .. $#compare ) {
        eval { AlignDB::Codon->new->count_diffs( @{ $compare[$i] } ); };
        like( $@, qr{Codon length error}i, "Codon length error" );
    }
}

done_testing();
