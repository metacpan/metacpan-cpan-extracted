#!perl

use Test::More;
use strict;
use warnings;

plan tests => 465;

use_ok('Business::LCCN') || BAIL_OUT('Could not load Business::LCCN');

my @test_groups = ( [  'n78-090351',
                       'n78-090351',
                       'n 78090351 ',
                       'n 78090351',
                       'n78090351 //r781',
                       'n 78-90351',
                       'n 78090351 //r863',
                       'n 78090351 /AB',
                       'n 78090351 /CD',
                       'n 78090351 /AB/r86'
                    ],
                    [ ' 85000002 ', '85-2 ', '85000002 ', '85-2', ],
);

foreach my $group (@test_groups) {
    for my $first ( @{$group} ) {
        for my $second ( @{$group} ) {
            my $lccn_a = new Business::LCCN($first);
            my $lccn_b = new Business::LCCN($second);
            ok( $lccn_a == $lccn_b, qq{"$first" == "$second" [as object]} );
            ok( $lccn_a == $second, qq{"$first" == "$second" [as string]} );
            ok( $lccn_a eq $lccn_b, qq{"$first" eq "$second" [as object]} );
            ok( $lccn_a eq $second, qq{"$first" eq "$second" [as string]} );
        }
    }
}

# Local Variables:
# mode: perltidy
# End:
