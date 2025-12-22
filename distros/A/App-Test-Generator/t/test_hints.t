use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::DescribeMe qw(extended);
use Test::Most;
use YAML::XS qw(LoadFile);

use App::Test::Generator::SchemaExtractor;

# Create a temporary directory for the test module
my $dir = tempdir(CLEANUP => 1);
my $module = File::Spec->catfile($dir, 'TestHints.pm');

# Write a simple module with clear validation logic
open my $fh, '>', $module or die "Cannot write $module: $!";
print {$fh} <<'EOF';
package TestHints;

sub example {
	my ($x) = @_;

	die 'negative' if $x < 0;
	return unless defined($x);

	return $x * 2;
}

1;
EOF
close $fh;

# Run SchemaExtractor
my $extractor = App::Test::Generator::SchemaExtractor->new(
	input_file => $module,
	output_dir => $dir,
	quiet => 1,
);

my $schemas = $extractor->extract_all();

ok($schemas, 'Schemas returned');
ok(exists $schemas->{example}, 'Schema for method "example" exists');

my $schema = $schemas->{example};

ok(exists $schema->{_yamltest_hints}, 'yamltest_hints present in schema');

my $hints = $schema->{_yamltest_hints};

# ---- invalid_inputs -------------------------------------------------

ok(exists $hints->{invalid_inputs}, 'invalid_inputs key exists');

cmp_deeply(
	[ sort @{ $hints->{invalid_inputs} } ],
	bag('undef', -1),
	'Detected invalid inputs: undef and -1'
);

# ---- boundary_values ------------------------------------------------

ok(exists $hints->{boundary_values}, 'boundary_values key exists');

# use Data::Dumper;
# diag(Dumper($hints));
# exit;

cmp_deeply(
	[ sort @{ $hints->{boundary_values} } ],
	bag(-1, 0, 1, 2, 100),
	'Detected numeric boundary values'
);

# ---- equivalence_classes -------------------------------------------

ok(
	!exists($hints->{equivalence_classes}) || @{ $hints->{equivalence_classes} } == 0,
	'No equivalence classes inferred (expected)'
);

done_testing();
