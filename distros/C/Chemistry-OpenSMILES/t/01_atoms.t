#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer;
use Test::More;

my @cases = qw(
    C       N      Cl     *
    [U]     [Pb]   [He]
    [CH4]   [ClH]
    [Cl-]   [Cu+2]
    [13CH4] [2H+]  [238U]
);

my %cases = (
    '[*]'    => '*',
    '[ClH1]' => '[ClH]',
    '[Cu++]' => '[Cu+2]',
    '[OH-1]' => '[OH-]',
    '[OH1-]' => '[OH-]',
    map { $_ => $_ } @cases,
);

plan tests => 2 * scalar %cases;

for (sort keys %cases) {
    my $parser   = Chemistry::OpenSMILES::Parser->new;
    my( $graph ) = $parser->parse( $_, { raw => 1 } );
    is( $graph->vertices, 1 );

    # s/H([\]\-])/H1$1/;
    is( join( '', map { Chemistry::OpenSMILES::Writer::_pre_vertex( $_ ) }
                      $graph->vertices ),
        $cases{$_} );
}
