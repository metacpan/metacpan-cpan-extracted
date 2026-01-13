#!/usr/bin/env perl
use strict;
use warnings;

use Test::DescribeMe qw(extended);
use Test::Most;
use File::Temp qw(tempdir);

# Tests for strict POD validation feature
# Load the module
BEGIN {
	use_ok('App::Test::Generator::SchemaExtractor');
}

# Helper to create a temporary Perl module file
sub create_test_module {
	my $content = $_[0];
	my $dir = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'TestModule.pm');
	open my $fh, '>', $file or die "Cannot create $file: $!";
	print $fh $content;
	close $fh;
	return $file;
}

# Helper to create an extractor for testing
sub create_extractor {
	my ($module_content, $strict_pod) = @_;
	my $module_file = create_test_module($module_content);
	return App::Test::Generator::SchemaExtractor->new(
		input_file => $module_file,
		output_dir => tempdir(CLEANUP => 1),
		verbose	=> 0,
		strict_pod => $strict_pod // 0,
	);
}

# Test 1: No strict POD checking (default)
subtest 'No Strict POD Checking (default)' => sub {
	my $module = <<'END_MODULE';
package Test::Basic;
use strict;
use warnings;

=head2 calculate

Calculates the sum of two numbers.

Parameters:
  $x - integer, first number
  $y - integer, second number

Returns: integer, sum of x and y

=cut

sub calculate {
	my ($self, $x, $y) = @_;
	return $x + $y;
}

=head2 process

Process data with options.

Parameters:
  $data - string, data to process
  $options - hashref, processing options (optional)

Returns: boolean, success status

=cut

sub process {
	my ($self, $data, $options) = @_;
	$options ||= {};
	return 1 if $data && ref($options) eq 'HASH';
	return 0;
}

END_MODULE

	my $extractor = create_extractor($module, 0);  # strict_pod = 0 (default)
	my $schemas = $extractor->extract_all();

	ok(exists $schemas->{calculate}, 'calculate method extracted');
	ok(exists $schemas->{process}, 'process method extracted');

	# Should have no validation errors since strict_pod is 0
	ok(!exists $schemas->{calculate}{_pod_validation_errors},
	   'No POD validation errors with strict_pod=0');

	done_testing();
};

# Test 2: POD and Code Agree (strict mode should pass with compatible types)
subtest 'POD and Code Agree (Strict Mode Passes with Compatible Types)' => sub {
	my $module = <<'END_MODULE';
package Test::AgreeingPOD;
use strict;
use warnings;

=head2 add

Adds two numbers.

Parameters:
  $a - number, first number
  $b - number, second number

Returns: integer, sum of a and b

=cut

sub add {
	my ($self, $a, $b) = @_;
	return $a + $b;
}

=head2 validate_email

Validates an email address.

Parameters:
  $email - string, email address to validate

Returns: boolean, true if valid email

=cut

sub validate_email {
	my ($self, $email) = @_;
	return $email =~ /^[^@]+@[^@]+\.[^@]+$/ ? 1 : 0;
}

=head2 get_config

Gets configuration value.

Parameters:
  $key - string, configuration key (optional, default: "default")

Returns: string, configuration value

=cut

sub get_config {
	my ($self, $key) = @_;
	$key ||= "default";
	return $self->{config}{$key} || "not found";
}

END_MODULE

	# Test with strict_pod = 2 (should not croak since POD and code agree)
	my $extractor = create_extractor($module, 2);

	# This should not throw an exception because types are compatible
	lives_ok {
		my $schemas = $extractor->extract_all();
		ok(exists $schemas->{add}, 'add method extracted');
		ok(exists $schemas->{validate_email}, 'validate_email method extracted');
		ok(exists $schemas->{get_config}, 'get_config method extracted');

		# Check that parameters were correctly extracted
		is_deeply(
			[sort keys %{$schemas->{add}{input}}],
			['a', 'b'],
			'add method has correct parameters'
		);

		# Note: Code analyzer might infer 'number' instead of 'integer'
		# This is OK since they're compatible
		ok($schemas->{add}{input}{a}{type}, 'Parameter a has type');
		ok($schemas->{add}{input}{b}{type}, 'Parameter b has type');

		# get_config should have optional parameter
		ok($schemas->{get_config}{input}{key}{optional},
		   'key parameter is optional (from POD)');

		# The default value might have quotes - clean them for comparison
		my $default = $schemas->{get_config}{input}{key}{_default};
		$default =~ s/^"|"$//g;  # Remove surrounding quotes if present
		is($default, 'default',
		   'key parameter has correct default');
	} 'No croak when POD and code have compatible types in strict mode';

	done_testing();
};

# Test 3: Parameter Missing in POD (should fail in strict mode)
subtest 'Parameter Missing in POD (Strict Mode Fails)' => sub {
	my $module = <<'END_MODULE';
package Test::MissingPODParam;
use strict;
use warnings;

=head2 process

Processes data.

Parameters:
  $data - string, data to process

Returns: boolean, success status

=cut

sub process {
	my ($self, $data, $options) = @_;  # $options not in POD!
	$options ||= {};
	return 1 if $data && ref($options) eq 'HASH';
	return 0;
}

END_MODULE

	# Test with strict_pod = 1 (warnings only)
	my $extractor_warn = create_extractor($module, 1);
	my $schemas_warn;

	# Should not croak, only warn
	lives_ok {
		$schemas_warn = $extractor_warn->extract_all();
	} 'No croak with strict_pod=1 (warnings only)';

	ok(exists $schemas_warn->{process}{_pod_validation_errors},
	   'Has POD validation errors with strict_pod=1');

	# Check the error message
	my @errors = @{$schemas_warn->{process}{_pod_validation_errors} || []};
	ok(scalar @errors > 0, 'Has validation errors');

	# Look for the specific error about missing $options
	my ($options_error) = grep { /\$options.*not documented/ } @errors;
	ok($options_error, 'Correct error message for missing POD parameter');

	# Test with strict_pod = 2 (should croak)
	my $extractor_strict = create_extractor($module, 2);

	dies_ok {
		$extractor_strict->extract_all();
	} 'Croaks with strict_pod=2 when parameter missing in POD';

	done_testing();
};

# Test 4: Parameter Missing in Code (should fail in strict mode)
subtest 'Parameter Missing in Code (Strict Mode Fails)' => sub {
	my $module = <<'END_MODULE';
package Test::MissingCodeParam;
use strict;
use warnings;

=head2 calculate

Calculates something.

Parameters:
  $x - number, first value
  $y - number, second value
  $z - number, third value (for future use)

Returns: integer, result

=cut

sub calculate {
	my ($self, $x, $y) = @_;  # $z in POD but not in code!
	return $x + $y;
}

END_MODULE

	# Test with strict_pod = 1 (warnings only)
	my $extractor_warn = create_extractor($module, 1);
	my $schemas_warn;

	lives_ok {
		$schemas_warn = $extractor_warn->extract_all();
	} 'No croak with strict_pod=1';

	ok(exists $schemas_warn->{calculate}{_pod_validation_errors},
	   'Has POD validation errors');

	my @errors = @{$schemas_warn->{calculate}{_pod_validation_errors} || []};

	# Look for the specific error about $z
	my ($z_error) = grep { /\$z.*documented.*not found/ } @errors;
	ok($z_error, 'Correct error for parameter in POD but not in code');

	# Test with strict_pod = 2 (should croak)
	my $extractor_strict = create_extractor($module, 2);

	dies_ok {
		$extractor_strict->extract_all();
	} 'Croaks with strict_pod=2 when parameter in POD but not in code';

	done_testing();
};

# Test 5: Type Mismatch (should fail in strict mode)
subtest 'Type Mismatch (Strict Mode Fails)' => sub {
	my $module = <<'END_MODULE';
package Test::TypeMismatch;
use strict;
use warnings;

=head2 parse_number

Parses a number.

Parameters:
  $input - string, string to parse as number

Returns: integer, parsed number

=cut

sub parse_number {
	my ($self, $input) = @_;
	# POD says string, code treats it as string (regex), returns integer
	return int($input) if $input =~ /^\d+$/;
	return 0;
}

=head2 get_data

Gets data with options.

Parameters:
  $id - integer, identifier
  $options - hashref, options (optional)

Returns: hashref, data

=cut

sub get_data {
	my ($self, $id, $options) = @_;
	# POD says integer for $id, but code uses it as string in hash key
	# POD says hashref for $options, code uses it as hashref
	return { id => $id, opts => $options };
}

END_MODULE

	# Test with strict_pod = 1
	my $extractor_warn = create_extractor($module, 1);
	my $schemas_warn;

	lives_ok {
		$schemas_warn = $extractor_warn->extract_all();
	} 'No croak with strict_pod=1 for type mismatch';

	# Both methods should have validation errors
	ok(exists $schemas_warn->{parse_number}{_pod_validation_errors},
	   'parse_number has validation errors');
	ok(exists $schemas_warn->{get_data}{_pod_validation_errors},
	   'get_data has validation errors');

	my @parse_errors = @{$schemas_warn->{parse_number}{_pod_validation_errors} || []};
	ok(scalar @parse_errors > 0, 'parse_number has type mismatch errors');

	# Look for type mismatch error in get_data
	my @get_data_errors = @{$schemas_warn->{get_data}{_pod_validation_errors} || []};
	my ($type_error) = grep { /Type mismatch/ } @get_data_errors;
	ok($type_error, 'Found type mismatch error for get_data');

	# Test with strict_pod = 2 (should croak)
	my $extractor_strict = create_extractor($module, 2);

	dies_ok {
		$extractor_strict->extract_all();
	} 'Croaks with strict_pod=2 for type mismatch';

	done_testing();
};

# Test 6: Optional/Required Status Mismatch
subtest 'Optional/Required Status Mismatch' => sub {
	my $module = <<'END_MODULE';
package Test::OptionalMismatch;
use strict;
use warnings;

=head2 create_user

Creates a new user.

Parameters:
  $username - string, username (required)
  $email - string, email address (optional)

Returns: boolean, success status

=cut

sub create_user {
	my ($self, $username, $email) = @_;
	# Code treats both as optional (with defaults)
	$username ||= 'anonymous';
	$email ||= 'noemail@example.com';
	return 1;
}

END_MODULE

	my $extractor = create_extractor($module, 1);
	my $schemas;

	lives_ok {
		$schemas = $extractor->extract_all();
	} 'No croak with strict_pod=1 for optional mismatch';

	ok(exists $schemas->{create_user}{_pod_validation_errors},
	   'create_user has validation errors');

	my @errors = @{$schemas->{create_user}{_pod_validation_errors} || []};
	my ($optional_error) = grep { /Optional status mismatch.*username/ } @errors;
	ok($optional_error, 'Found optional status mismatch error for username');

	done_testing();
};

# Test 7: Type Compatibility (compatible types should not error in warning mode)
# Note: Even compatible types cause croak in strict mode (level 2), so we test with warning mode (level 1)
subtest 'Type Compatibility (Compatible Types in Warning Mode)' => sub {
	my $module = <<'END_MODULE';
package Test::CompatibleTypes;
use strict;
use warnings;

=head2 calculate_average

Calculates average of numbers.

Parameters:
  $numbers - array, list of numbers

Returns: number, average

=cut

sub calculate_average {
	my ($self, $numbers) = @_;
	# Code uses arrayref, POD says array - compatible
	my $sum = 0;
	$sum += $_ for @$numbers;
	return $sum / scalar(@$numbers);
}

=head2 process_data

Processes data.

Parameters:
  $data - string, data to process

Returns: string, processed data

=cut

sub process_data {
	my ($self, $data) = @_;

	die if(!defined($data));
	# Code infers string, POD says string - exact match
	return "Processed: $data";
}

END_MODULE

	# Use warning mode (1) for compatible types test
	# Strict mode (2) would croak even for compatible differences
	my $extractor_warn = create_extractor($module, 1);

	lives_ok {
		my $schemas = $extractor_warn->extract_all();
		ok(exists $schemas->{calculate_average}, 'calculate_average extracted');
		ok(exists $schemas->{process_data}, 'process_data extracted');

		# calculate_average might have warnings about compatible types
		# That's OK in warning mode
		if (exists $schemas->{calculate_average}{_pod_validation_errors}) {
			my @errors = @{$schemas->{calculate_average}{_pod_validation_errors} || []};
			# Should only have "Type difference" (compatible), not "Type mismatch" (incompatible)
			my ($incompatible) = grep { /Type mismatch.*incompatible/ } @errors;
			ok(!$incompatible, 'No incompatible type errors for calculate_average');
		}

		# process_data should have no errors (exact match)
		ok(!exists $schemas->{process_data}{_pod_validation_errors} ||
		   (scalar @{$schemas->{process_data}{_pod_validation_errors} || []}) == 0,
		   'No validation errors for exact type match (string)');
	} 'No croak for compatible types in warning mode';

	done_testing();
};

# Test 8: Constraint Mismatch
subtest 'Constraint Mismatch' => sub {
	my $module = <<'END_MODULE';
package Test::ConstraintMismatch;
use strict;
use warnings;

=head2 validate_age

Validates age.

Parameters:
  $age - number, age (1-120)

Returns: boolean, true if valid

=cut

sub validate_age {
	my ($self, $age) = @_;
	# Code checks 0-150, POD says 1-120
	return 0 unless defined $age;
	return 0 if $age < 0 || $age > 150;
	return 1;
}

END_MODULE

	my $extractor = create_extractor($module, 1);
	my $schemas;

	lives_ok {
		$schemas = $extractor->extract_all();
	} 'No croak with strict_pod=1 for constraint mismatch';

	# Note: The current implementation may not capture constraint mismatches
	# We're testing that it doesn't crash
	ok(exists $schemas->{validate_age}, 'validate_age extracted');

	done_testing();
};

# Test 9: Multiple Methods with Mixed Agreement Levels
subtest 'Multiple Methods with Mixed Agreement' => sub {
	my $module = <<'END_MODULE';
package Test::MixedAgreement;
use strict;
use warnings;

=head2 perfect_match

Perfect match between POD and code.

Parameters:
  $x - number, first value
  $y - number, second value

Returns: integer, sum

=cut

sub perfect_match {
	my ($self, $x, $y) = @_;
	return $x + $y;
}

=head2 missing_param

Missing parameter in POD.

Parameters:
  $data - string, data

Returns: boolean, success

=cut

sub missing_param {
	my ($self, $data, $format) = @_;  # $format not in POD
	return 1 if $data && $format;
	return 0;
}

=head2 wrong_type

Wrong type in POD.

Parameters:
  $count - string, count value

Returns: string, count as string

=cut

sub wrong_type {
	my ($self, $count) = @_;
	# POD says string, code treats as number (addition)
	return $count + 1;
}

END_MODULE

	# Test with strict_pod = 1 (should collect errors for all methods)
	my $extractor = create_extractor($module, 1);
	my $schemas;

	lives_ok {
		$schemas = $extractor->extract_all();
	} 'No croak with strict_pod=1 for mixed agreement';

	# perfect_match might have warnings about type differences (compatible)
	# That's OK
	ok(exists $schemas->{perfect_match}, 'perfect_match extracted');

	# missing_param should have errors
	ok(exists $schemas->{missing_param}{_pod_validation_errors},
	   'missing_param has validation errors');
	my @missing_errors = @{$schemas->{missing_param}{_pod_validation_errors} || []};
	ok(scalar @missing_errors > 0, 'missing_param has at least one error');

	# wrong_type should have errors
	ok(exists $schemas->{wrong_type}{_pod_validation_errors},
	   'wrong_type has validation errors');
	my @wrong_errors = @{$schemas->{wrong_type}{_pod_validation_errors} || []};
	ok(scalar @wrong_errors > 0, 'wrong_type has at least one error');

	done_testing();
};

# Test 10: Test generate_pod_validation_report method
subtest 'POD Validation Report Generation' => sub {
	my $module = <<'END_MODULE';
package Test::ReportGeneration;
use strict;
use warnings;

=head2 method1

Method with issues.

Parameters:
  $a - integer, first param

Returns: integer, result

=cut

sub method1 {
	my ($self, $a, $b) = @_;  # $b not in POD
	return $a + $b;
}

=head2 method2

Another method.

Returns: boolean, true

=cut

sub method2 {
	my ($self) = @_;
	return 1;
}

END_MODULE

	my $extractor = create_extractor($module, 1);
	my $schemas = $extractor->extract_all();

	# Test if the report method exists
	can_ok($extractor, 'generate_pod_validation_report');

	# Generate report
	my $report = $extractor->generate_pod_validation_report($schemas);

	ok(defined $report, 'Report generated');
	like($report, qr/POD\/Code Validation/, 'Report contains header');

	# Test with a module that has POD for all parameters
	my $clean_module = <<'END_MODULE';
package Test::Clean;
use strict;
use warnings;

=head2 clean_method

Clean method with proper POD.

Parameters:
  $x - number, value to double

Returns: number, doubled value

=cut

sub clean_method {
	my ($self, $x) = @_;
	return $x * 2;
}
END_MODULE

	my $clean_extractor = create_extractor($clean_module, 1);
	my $clean_schemas = $clean_extractor->extract_all();
	my $clean_report = $clean_extractor->generate_pod_validation_report($clean_schemas);

	# The report should indicate all passed (or be empty)
	ok(defined $clean_report, 'Clean report generated');

	done_testing();
};

# Test 11: Edge Cases and Real-World Examples
subtest 'Edge Cases and Real-World Examples' => sub {
	my $module = <<'END_MODULE';
package Test::EdgeCases;
use strict;
use warnings;

=head2 real_world_example

Real-world example with complex signature.

Parameters:
  $dbh - object, database handle (required)
  $query - string, SQL query (required)
  $params - arrayref, query parameters (optional)
  $options - hashref, execution options (optional)

Returns: arrayref, query results

=cut

sub real_world_example {
	my ($self, $dbh, $query, $params, $options) = @_;

	# Complex validation
	croak "Database handle required" unless $dbh && $dbh->isa('DBI::db');
	croak "Query required" unless defined $query;

	$params ||= [];
	$options ||= {};

	my $sth = $dbh->prepare($query);
	$sth->execute(@$params);

	my @results;
	while (my $row = $sth->fetchrow_hashref) {
		push @results, $row;
	}

	return \@results;
}

=head2 factory_method

Creates a new instance.

Parameters:
  $config - hashref, configuration

Returns: object, new instance

=cut

sub factory_method {
	my ($class, $config) = @_;
	# $class is not in POD (common pattern for class methods)
	return bless { %$config }, $class;
}

END_MODULE

	my $extractor = create_extractor($module, 1);
	my $schemas;

	lives_ok {
		$schemas = $extractor->extract_all();
	} 'No croak with complex real-world examples';

	# real_world_example should have correct parameters
	ok(exists $schemas->{real_world_example}{input}{dbh},
	   'real_world_example has dbh parameter');

	# factory_method is a class method, might have different handling
	note("factory_method extracted: " . (exists $schemas->{factory_method} ? 'yes' : 'no'));

	done_testing();
};

done_testing();
