use strict;
use warnings;

use File::Temp qw(tempdir tempfile);
use File::Spec;
use Test::DescribeMe qw(extended);
use Test::Most;
use IPC::Run3 qw(run3);

BEGIN {
	use_ok('App::Test::Generator');
	use_ok('App::Test::Generator::SchemaExtractor');
}

# Temporary workspace
my $dir = tempdir(CLEANUP => 1);

# ------------------------------------------------------------------
# Create a minimal test module to extract schema from
# ------------------------------------------------------------------
my $module = File::Spec->catfile($dir, 'TestSchema.pm');

open my $mod_fh, '>', $module or die $!;
print {$mod_fh} <<'EOF';
package TestSchema;

# This is the package that will be tested

use Scalar::Util qw(looks_like_number);

sub add {
	if($_[0] && ($_[0] eq __PACKAGE__)) {
		shift;
	}
	my ($a, $b) = @_;
	die 'missing a' unless defined($a);
	die 'not numeric' unless looks_like_number($a);
	die 'not numeric' if defined($b) && !looks_like_number($b);
	return $a + ($b // 0);
}

1;
EOF
close $mod_fh;

ok(-e $module, 'Test module created');

# ------------------------------------------------------------------
# Extract schema
# ------------------------------------------------------------------
my $extractor = App::Test::Generator::SchemaExtractor->new(
	input_file => $module,
	output_dir => $dir,
	quiet => 1,
);

my $schema = $extractor->extract_all();

ok(ref $schema eq 'HASH', 'Schema extracted as hashref');
ok(exists $schema->{add}, 'Schema contains add()');
is($schema->{add}{output}{_type_confidence}, 'medium', 'Numeric expression output has medium confidence');
cmp_bag(
	$schema->{add}{_yamltest_hints}{boundary_values},
	[ -1, 0, 1, 2, 100 ],
	'Numeric boundary values added for numeric method'
);

# use Data::Dumper;
# diag(Dumper($schema->{'add'}));
# exit;

# ------------------------------------------------------------------
# Generate test from schema
# ------------------------------------------------------------------
my ($fh, $tempfile) = tempfile(
	DIR => $dir,
	SUFFIX => '.t',
);
close $fh;

my $generator;

lives_ok {
	App::Test::Generator->generate(
		schema => $schema->{'add'},
		output_file => $tempfile,
		quiet => 1,
	);
} 'Generator runs successfully with schema input';

ok(-e $tempfile, 'fuzz test file created');

# ------------------------------------------------------------------
# Inspect generated content
# ------------------------------------------------------------------
open my $tfh, '<', $tempfile or die $!;
my $content = do { local $/; <$tfh> };
close $tfh;

like($content, qr/diag\(/, 'fuzz test has diag line');

# ------------------------------------------------------------------
# Syntax check
# ------------------------------------------------------------------
system("$^X -I$dir -c $tempfile > /dev/null 2>&1");
is($?, 0, 'Generated test script compiles');

# ------------------------------------------------------------------
# Run generated test
# ------------------------------------------------------------------
my ($stdout, $stderr);
run3 [ $^X, "-I$dir", $tempfile ], undef, \$stdout, \$stderr;

ok($? == 0, 'Generated test script exits successfully')
	or diag("STDOUT:\n$stdout\nSTDERR:\n$stderr");

like($stderr, qr/test case created/, 'Test creation message present');
like($stdout, qr/^ok \d/sm, 'At least one created test passed');
if($stdout =~ /1\.\.(\d+)/ms) {
	# Show how many tests we ran on TestSchema::add
	diag("$1 tests created and run");
}

unlike($stdout, qr/^not ok \d/sm, 'No created test failed');

done_testing();
