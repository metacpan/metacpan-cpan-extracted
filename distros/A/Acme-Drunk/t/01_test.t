use Test::More qw[no_plan];
use strict;
use warnings;

BEGIN { use_ok 'Acme::Drunk' }

my $bac = drunk(
                gender         => MALE, # or FEMALE
                hours          => 2,    # since start of binge
                body_weight    => 150,  # in lbs
                alcohol_weight => 3,    # oz of alcohol
               );

cmp_ok( sprintf("%.2f",$bac), '==', sprintf("%.2f",0.125491176470588) );

