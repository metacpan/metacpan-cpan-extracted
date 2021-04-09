use Test::More;
my @lines;

open F, "<", "t/formula_tests.txt"
    or die "couldn't open t/formula_tests.txt; $!";
@lines = <F>;
close F;

plan tests => 8 + @lines;
use_ok('Chemistry::File::Formula');

# Constructors
my $mol = Chemistry::Mol->parse("CH4O", format => "formula");
isa_ok($mol, 'Chemistry::Mol', 'parse isa mol');
ok($mol->atoms == 6, "enough atoms");
my $formula = $mol->formula("%s%d{<sub>%d</sub>}");
is($formula, "CH<sub>4</sub>O", "formula format");

$mol = Chemistry::Mol->parse("1[Ph(Me)3]2", format => "formula");
my $fh = $mol->formula_hash;
is_deeply($fh, {C => 18, H => 28}, "formula hash 1[Ph(Me)3]2");

# test various parsing issues
for my $line (@lines) {
    chomp $line;
    my ($test_formula, $expected) = split /\t/, $line;
    my $got = Chemistry::Mol->parse($test_formula, format => "formula")
        ->print(format=>'formula');
    is($got, $expected, "$test_formula = $expected");
}

# parse_formula

my %formula_hash = Chemistry::File::Formula->parse_formula("C2H6O");
is_deeply(\%formula_hash, {H => 6, O => 1, C => 2}, 'parse_formula');


# parse_formula with non-integers

%formula_hash = Chemistry::File::Formula->parse_formula("C2.1H6.5O0.9");
is_deeply(\%formula_hash, {H => 6.5, O => 0.9, C => 2.1}, 
    'parse_formula (non-integer)');


# a formula with custom sort

$mol = Chemistry::Mol->parse("C2H6Br", format => "formula");
$formula = $mol->print(
    format       => 'formula', 
    formula_sort => sub {
        my $f = shift;
        reverse sort keys %$f;
    }
);
is ($formula, 'H6C2Br',     'formula_sort');

