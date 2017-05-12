use strict;
eval { require warnings; };
use Test::More tests => 9;

BEGIN { use_ok('Acme::HaltingProblem'); }

my $problem = new Acme::HaltingProblem(
				Machine	=> sub { 1; },
					);
ok(defined $problem, 'Created a simple instance');
ok(UNIVERSAL::isa($problem, 'Acme::HaltingProblem'),
				'The instance is a HaltingProblem');
ok($problem->analyse, 'The machine halts.');

{
	package My::HaltingProblem;
	use base 'Acme::HaltingProblem';
}

$problem = new My::HaltingProblem(
				Machine	=> sub { 1; },
					);
ok(defined $problem, 'Created a subclass instance');
ok(UNIVERSAL::isa($problem, 'Acme::HaltingProblem'),
				'The instance is a HaltingProblem');
ok($problem->analyse, 'The machine halts.');

$problem = new Acme::HaltingProblem(
				Machine	=> sub { $_[0] + $_[1]; },
				Input	=> [ 3, 4 ],
					);
ok(defined $problem, 'Created a complex instance');
ok($problem->analyse, 'The machine halts.');
