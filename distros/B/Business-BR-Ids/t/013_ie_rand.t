
use constant N => 100;
use constant STATES => [ qw(AC AL AP AM BA MA MG RO RR SP PR) ]; # by now
#use constant STATES => [ qw(BA) ];
use constant N_STATES => 0+@{+STATES}; 

use Test::More tests => 1+2*N*N_STATES;
BEGIN { use_ok('Business::BR::IE', 'random_ie', 'test_ie') };

# the seed is set so that the test is reproducible
srand(161803398874989);

for my $s (@{+STATES}) {

  for ( my $i=0; $i<N; $i++ ) {
    my $ie = random_ie($s);
    ok(test_ie($s, $ie), "random IE/$s '$ie' is correct");
  }
  for ( my $i=0; $i<N; $i++ ) {
    my $ie = random_ie($s, 0);
    ok(!test_ie($s, $ie), "random invalid IE/$s '$ie' is incorrect");
  }

}

