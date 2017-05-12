
use constant N => 100;

use Test::More tests => 1+2*N;
BEGIN { use_ok('Business::BR::CPF', 'random_cpf', 'test_cpf') };

# the seed is set so that the test is reproducible
srand(271828182845905);

for ( my $i=0; $i<N; $i++ ) {
	my $cpf = random_cpf();
	ok(test_cpf($cpf), "random cpf '$cpf' is correct");
}
for ( my $i=0; $i<N; $i++ ) {
	my $cpf = random_cpf(0);
	ok(!test_cpf($cpf), "random invalid cpf '$cpf' is incorrect");
}

