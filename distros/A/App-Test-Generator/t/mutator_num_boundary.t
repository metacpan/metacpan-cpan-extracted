use strict;
use warnings;

use Test::Most;
use PPI;
use App::Test::Generator::Mutation::NumericBoundary;

# --------------------------------------------------
# Sample source containing numeric operators
# --------------------------------------------------

my $source = <<'END_PERL';
sub test {
	if ($x > 10) {
		return 1;
	}

	if ($y == 5) {
		return 2;
	}
}
END_PERL

my $doc = PPI::Document->new(\$source);
ok($doc, 'PPI document parsed');

# --------------------------------------------------
# Run mutation
# --------------------------------------------------

my $mutation = App::Test::Generator::Mutation::NumericBoundary->new;

my @mutants = $mutation->mutate($doc);

ok(@mutants > 0, 'Numeric boundary mutants generated');

# --------------------------------------------------
# Validate structure of mutants
# --------------------------------------------------

for my $m (@mutants) {

	isa_ok($m, 'App::Test::Generator::Mutant');

	like($m->id, qr/^NUM_BOUNDARY_/, 'Correct ID prefix');

	ok(defined $m->line, 'Line number defined');

	ok($m->can('transform'), 'Has transform');

	is(ref($m->{transform}), 'CODE', 'Transform is coderef');
}

# --------------------------------------------------
# Verify expected mutations exist
# --------------------------------------------------

my @ids = map { $_->id } @mutants;

ok(grep(/^NUM_BOUNDARY_\d+_\d+_/, @ids), 'IDs formatted correctly');

# --------------------------------------------------
# Apply one mutant and verify operator changed
# --------------------------------------------------

my ($first) = @mutants;

my $clone = PPI::Document->new(\$source);
$first->{transform}->($clone);

like($clone->serialize, qr/!=|>=|<=|<|>/, 'Operator was transformed');

done_testing();
