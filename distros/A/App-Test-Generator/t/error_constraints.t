use strict;
use warnings;

use Test::DescribeMe qw(extended);
use Test::Most;
use File::Temp qw(tempdir);

BEGIN {
	use_ok('App::Test::Generator::SchemaExtractor');
}

# Create a temporary module for testing advanced types
my $tempdir = tempdir(CLEANUP => 1);
my $test_module = File::Spec->catfile($tempdir, 'AdvancedTypes.pm');

# Write test module with various advanced type patterns
open my $fh, '>', $test_module or die "Can't create test module: $!";
print $fh <<'END_MODULE';
package ErrorConstraints;

sub age {
	my ($age) = @_;
	die "Age must be positive" if $age <= 0;
}

sub name {
	my ($name) = @_;
	croak "Name too short" if length($name) < 3;
}

sub count {
	my ($count) = @_;
	die if $count == 0;
}

sub unknown {
	my ($foo) = @_;
	die "bad bar" if $bar < 0;
}
1;
END_MODULE
close $fh;

# Module instantiation
my $extractor = App::Test::Generator::SchemaExtractor->new(
	input_file => $test_module,
	output_dir => File::Spec->catdir($tempdir, 'schemas'),
	verbose	=> 0,
);

isa_ok($extractor, 'App::Test::Generator::SchemaExtractor');

# Extract schemas
my $schemas = $extractor->extract_all();

ok($schemas, 'extract_all returns schemas');
is(ref($schemas), 'HASH', 'schemas is a hashref');

cmp_ok($schemas->{'age'}->{'input'}->{'age'}->{'min'}, '==', 1, 'Minimum input value is 1 (die if $age <= 0)');

# use Data::Dumper;
# diag(Dumper($schemas));

done_testing;
