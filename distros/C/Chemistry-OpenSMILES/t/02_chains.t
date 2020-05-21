#!/usr/bin/perl

use strict;
use warnings;
use List::Util qw(sum);
use Chemistry::OpenSMILES::Parser;
use Test::More;

my %cases = (
    'CC'    => [ 2, 1 ],
    'CCO'   => [ 3, 2 ],
    'NCCCC' => [ 5, 4 ],
    'CCCCN' => [ 5, 4 ],

    'C=C'   => [ 2, 1 ],
    'C#N'   => [ 2, 1 ],
    'CC#CC' => [ 4, 3 ],
    'CCC=O' => [ 4, 3 ],
    '[Rh-](Cl)(Cl)(Cl)(Cl)$[Rh-](Cl)(Cl)(Cl)Cl' => [ 10, 9 ],

    'C-C' => [ 2, 1 ],

    'CCC(CC)CO'           => [  7,  6 ],
    'CC(C)C(=O)C(C)C'     => [  8,  7 ],
    'OCC(CCC)C(C(C)C)CCC' => [ 13, 12 ],
    'OS(=O)(=S)O'         => [  5,  4 ],
    'C(C(C(C(C(C(C(C(C(C(C(C(C(C(C(C(C(C(C(C(C))))))))))))))))))))C' => [ 22, 21 ],

    'C1CCCCC1'          => [  6,  6 ],
    'N1CC2CCCCC2CC1'    => [ 10, 11 ],
    'C=1CCCCC=1'        => [  6,  6 ],
    'C1CCCCC1C1CCCCC1'  => [ 12, 13 ],
    'C1CCCCC1C2CCCCC2'  => [ 12, 13 ],
    'C0CCCCC0'          => [  6,  6 ],
    'C%25CCCCC%25'      => [  6,  6 ],
    'C1CCCCC%01'        => [  6,  6 ],
    'C12(CCCCC1)CCCCC2' => [ 11, 12 ],

    # The following case is not allowed by OpenSMILES specification,
    # however, it is easier to support it than forbid.
    'C(CCCCC1)12CCCCC2' => [ 11, 12 ],

    '[Na+].[Cl-]'             => [ 2,  2,  0 ],
    'c1cc(O.NCCO)ccc1'        => [ 2, 11, 10 ],
    'Oc1cc(.NCCO)ccc1'        => [ 2, 11, 10 ],
    'C1.C1'                   => [ 1,  2,  1 ],
    'C1.C12.C2'               => [ 1,  3,  2 ],
    'c1c2c3c4cc1.Br2.Cl3.Cl4' => [ 1,  9,  9 ],

    'C(C(C1))C1' => [ 4, 4 ],
);

plan tests => 3 * scalar keys %cases;

for my $case (sort keys %cases) {
    my $parser = Chemistry::OpenSMILES::Parser->new;
    my @graphs = $parser->parse( $case );

    is( scalar @graphs, @{$cases{$case}} == 3 ? $cases{$case}->[0] : 1 );

    is( sum( map { scalar $_->vertices } @graphs ), $cases{$case}->[-2] );
    is( sum( map { scalar $_->edges    } @graphs ), $cases{$case}->[-1] );
}
