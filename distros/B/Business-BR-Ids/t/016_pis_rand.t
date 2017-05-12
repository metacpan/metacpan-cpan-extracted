
use constant N => 100;

use Test::More tests => 1+2*N;
BEGIN { use_ok('Business::BR::PIS', 'random_pis', 'test_pis') };

# the seed is set so that the test is reproducible
srand(271828182845905);

for ( my $i=0; $i<N; $i++ ) {
	my $pis = random_pis();
	ok(test_pis($pis), "random pis '$pis' is correct");
}
for ( my $i=0; $i<N; $i++ ) {
	my $pis = random_pis(0);
	ok(!test_pis($pis), "random invalid pis '$pis' is incorrect");
}

