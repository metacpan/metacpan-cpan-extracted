
use constant N => 100;

use Test::More tests => 1+2*N;
BEGIN { use_ok('Business::BR::CNPJ', 'random_cnpj', 'test_cnpj') };

# the seed is set so that the test is reproducible
srand(161803398874989);

for ( my $i=0; $i<N; $i++ ) {
	my $cnpj = random_cnpj();
	ok(test_cnpj($cnpj), "random cnpj '$cnpj' is correct");
}
for ( my $i=0; $i<N; $i++ ) {
	my $cnpj = random_cnpj(0);
	ok(!test_cnpj($cnpj), "random invalid cnpj '$cnpj' is incorrect");
}

