#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempdir);
use File::Spec;

# Load the module
BEGIN {
	use_ok('App::Test::Generator::SchemaExtractor');
}

# Helper to create a temporary Perl module file
sub create_test_module {
	my ($content) = @_;
	my $dir = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'TestModule.pm');
	open my $fh, '>', $file or die "Cannot create $file: $!";
	print $fh $content;
	close $fh;
	return $file;
}

# Helper to create an extractor for testing
sub create_extractor {
	my ($module_content) = @_;
	my $module_file = create_test_module($module_content);
	return App::Test::Generator::SchemaExtractor->new(
		input_file => $module_file,
		output_dir => tempdir(CLEANUP => 1),
		verbose	=> 0,
	);
}

# Test 1: Basic default value patterns
subtest 'Basic Default Value Patterns' => sub {
	my $module = <<'END_MODULE';
package Test::Defaults;
use strict;
use warnings;

sub method_with_defaults {
	my ($self, $param1, $param2, $param3, $param4, $param5, $param6, $param7) = @_;

	# Various default patterns
	$param1 = $param1 || 'default_string';
	$param2 //= 42;
	$param3 = defined $param3 ? $param3 : 3.14;
	$param4 = $param4 || 0;
	$param5 = 'auto' unless defined $param5;
	$param6 ||= 1;
	$param7 = $param7 // undef;

	return 1;
}
END_MODULE

	my $extractor = create_extractor($module);

	# Get the document for analysis
	my $doc = PPI::Document->new($extractor->{input_file});
	$extractor->{_document} = $doc;

	# Test extraction from code
	my $method_body = <<'END_BODY';
	my ($self, $param1, $param2, $param3, $param4, $param5, $param6, $param7) = @_;

	# Various default patterns
	$param1 = $param1 || 'default_string';
	$param2 //= 42;
	$param3 = defined $param3 ? $param3 : 3.14;
	$param4 = $param4 || 0;
	$param5 = 'auto' unless defined $param5;
	$param6 ||= 1;
	$param7 = $param7 // undef;

	return 1;
END_BODY

	# Test individual parameter default extraction
	is(
		$extractor->_extract_default_value('param1', $method_body),
		'default_string',
		'Extracts string default from || pattern'
	);

	is(
		$extractor->_extract_default_value('param2', $method_body),
		42,
		'Extracts integer default from //= pattern'
	);

	is(
		$extractor->_extract_default_value('param3', $method_body),
		3.14,
		'Extracts float default from ternary pattern'
	);

	is(
		$extractor->_extract_default_value('param4', $method_body),
		0,
		'Extracts zero default from || pattern'
	);

	is(
		$extractor->_extract_default_value('param5', $method_body),
		'auto',
		'Extracts default from "unless defined" pattern'
	);

	is(
		$extractor->_extract_default_value('param6', $method_body),
		1,
		'Extracts default from ||= pattern'
	);

	is(
		$extractor->_extract_default_value('param7', $method_body),
		undef,
		'Extracts undef default from // pattern'
	);

	done_testing();
};

# Test 2: Complex default value patterns
subtest 'Complex Default Value Patterns' => sub {
	my $module = <<'END_MODULE';
package Test::ComplexDefaults;
use strict;
use warnings;

sub method_complex {
	my ($self, $name, $count, $enabled, $list, $hash, $custom) = @_;

	# Complex patterns with variables and expressions
	$name = $name || $self->{default_name} || 'unknown';
	$count = defined $count ? $count : $ENV{DEFAULT_COUNT} || 10;
	$enabled //= $self->is_enabled() ? 1 : 0;

	# Multi-line patterns
	if (!defined $list) {
		$list = [];
	}

	unless (defined $hash) {
		$hash = {};
	}

	$custom = $custom // get_default_custom();

	return 1;
}
END_MODULE

	my $extractor = create_extractor($module);

	my $method_body = <<'END_BODY';
	my ($self, $name, $count, $enabled, $list, $hash, $custom) = @_;

	# Complex patterns with variables and expressions
	$name = $name || $self->{default_name} || 'unknown';
	$count = defined $count ? $count : $ENV{DEFAULT_COUNT} || 10;
	$enabled //= $self->is_enabled() ? 1 : 0;

	# Multi-line patterns
	if (!defined $list) {
		$list = [];
	}

	unless (defined $hash) {
		$hash = {};
	}

	$custom = $custom // get_default_custom();

	return 1;
END_BODY

	# Test complex patterns - note: some return expressions we can't evaluate
	is(
		$extractor->_extract_default_value('name', $method_body),
		'unknown',
		'Extracts final default from chained || pattern'
	);

	# Note: $count extraction is complex - we get the expression
	my $count_default = $extractor->_extract_default_value('count', $method_body);
	ok($count_default, 'Extracts expression for complex ternary default');

	# Multi-line patterns should work
	is_deeply(
		$extractor->_extract_default_value('list', $method_body),
		[],
		'Extracts empty arrayref from multi-line if pattern'
	);

	is_deeply(
		$extractor->_extract_default_value('hash', $method_body),
		{},
		'Extracts empty hashref from multi-line unless pattern'
	);

	done_testing();
};

# Test 3: Default value cleaning
subtest 'Default Value Cleaning' => sub {
	my $extractor = create_extractor('package Dummy; sub dummy {}');

	# Test string cleaning
	is(
		$extractor->_clean_default_value("'hello'"),
		'hello',
		'Cleans single-quoted strings'
	);

	is(
		$extractor->_clean_default_value('"world"'),
		'world',
		'Cleans double-quoted strings'
	);

	# Test numeric cleaning
	is(
		$extractor->_clean_default_value('42'),
		42,
		'Cleans integers'
	);

	is(
		$extractor->_clean_default_value('3.14'),
		3.14,
		'Cleans floats'
	);

	# Test boolean cleaning
	is(
		$extractor->_clean_default_value('1'),
		1,
		'Cleans boolean true (1)'
	);

	is(
		$extractor->_clean_default_value('0'),
		0,
		'Cleans boolean false (0)'
	);

	is(
		$extractor->_clean_default_value('true'),
		1,
		'Cleans boolean true string'
	);

	is(
		$extractor->_clean_default_value('false'),
		0,
		'Cleans boolean false string'
	);

	# Test data structures
	is_deeply(
		$extractor->_clean_default_value('[]'),
		[],
		'Cleans empty arrayref'
	);

	is_deeply(
		$extractor->_clean_default_value('{}'),
		{},
		'Cleans empty hashref'
	);

	# Test special values
	is(
		$extractor->_clean_default_value('undef'),
		undef,
		'Cleans undef'
	);

	is(
		$extractor->_clean_default_value('__PACKAGE__'),
		'__PACKAGE__',
		'Preserves __PACKAGE__ constant'
	);

	# Test with extra whitespace
	is(
		$extractor->_clean_default_value("  'test'  "),
		'test',
		'Cleans string with whitespace'
	);

	is(
		$extractor->_clean_default_value(' 42 '),
		42,
		'Cleans integer with whitespace'
	);

	# Test escaped strings
	is(
		$extractor->_clean_default_value('"line1\\nline2"'),
		"line1\nline2",
		'Handles escaped newlines'
	);

	is(
		$extractor->_clean_default_value("'it\\'s working'"),
		"it's working",
		'Handles escaped quotes'
	);

	done_testing();
};

# Test 4: POD default value extraction
subtest 'POD Default Value Extraction' => sub {
	my $module = <<'END_MODULE';
package Test::PODDefaults;
use strict;
use warnings;

=head2 process_data

Process data with various parameters.

=over 4

=item * $name - string, the name to process. Default: 'anonymous'

=item * $count - integer, number of items. Default: 10

=item * $enabled - boolean, whether enabled. Default: true

=item * $mode - string, processing mode. Optional, default: 'auto'

=back

Defaults to: 1 on success

=cut

sub process_data {
	my ($self, $name, $count, $enabled, $mode) = @_;

	$name ||= 'anonymous';
	$count //= 10;
	$enabled //= 1;
	$mode = 'auto' unless defined $mode;

	return 1;
}

=head2 another_method

Another method with different POD patterns.

Parameters:
  $host - string, hostname. Defaults to: 'localhost'
  $port - integer, port number. Default: 8080
  $timeout - number, timeout in seconds. Optional, default: 30.0

=cut

sub another_method {
	my ($self, $host, $port, $timeout) = @_;

	$host ||= 'localhost';
	$port //= 8080;
	$timeout = 30.0 unless defined $timeout;

	return 1;
}
END_MODULE

	my $extractor = create_extractor($module);

	# Get POD for first method
	my $doc = PPI::Document->new($extractor->{input_file});
	$extractor->{_document} = $doc;

	# Find the first method's POD
	my $methods = $extractor->_find_methods($doc);
	my $process_data = (grep { $_->{name} eq 'process_data' } @$methods)[0];

	ok($process_data->{pod}, 'Found POD for process_data');

	# Extract defaults from POD
	my $defaults = $extractor->_extract_defaults_from_pod($process_data->{pod});

	is_deeply(
		$defaults,
		{
			name => 'anonymous',
			count => 10,
			enabled => 1,
			mode => 'auto',
		},
		'Extracts defaults from POD documentation'
	);

	# Test the second method's POD
	my $another_method = (grep { $_->{name} eq 'another_method' } @$methods)[0];
	my $another_defaults = $extractor->_extract_defaults_from_pod($another_method->{pod});

	is(
		$another_defaults->{host},
		'localhost',
		'Extracts host default from "Defaults to:" pattern'
	);

	is(
		$another_defaults->{port},
		8080,
		'Extracts port default from "Default:" pattern'
	);

	is(
		$another_defaults->{timeout},
		30.0,
		'Extracts timeout default from "Optional, default:" pattern'
	);

	done_testing();
};

# Test 5: Integrated parameter analysis with defaults
subtest 'Integrated Parameter Analysis with Defaults' => sub {
	my $module = <<'END_MODULE';
package Test::IntegratedDefaults;
use strict;
use warnings;

=head2 configure

Configure the system.

Parameters:
  $host - string, hostname. Default: 'localhost'
  $port - integer, port number. Default: 8080
  $ssl - boolean, use SSL. Default: false
  $timeout - number, timeout in seconds. Optional, default: 30.0

=cut

sub configure {
	my ($self, $host, $port, $ssl, $timeout) = @_;

	# Various default patterns mixed
	$host = $host || 'localhost';
	$port //= 8080;
	$ssl = defined $ssl ? $ssl : 0;
	$timeout = $timeout || 30.0;

	return 1;
}

=head2 process

Process with array and hash defaults.

=cut

sub process {
	my ($self, $items, $options) = @_;

	$items = [] unless defined $items;
	$options = {} unless $options;

	return scalar @$items;
}
END_MODULE

	my $extractor = create_extractor($module);

	# Extract all schemas
	my $schemas = $extractor->extract_all();

	# Test configure method
	my $configure_schema = $schemas->{configure};
	ok($configure_schema, 'Found configure method schema');

	my $configure_input = $configure_schema->{input};

	is(
		$configure_input->{host}{default},
		'localhost',
		'Schema includes host default from code and POD'
	);

	is(
		$configure_input->{host}{type},
		'string',
		'Type inferred from string default'
	);

	is(
		$configure_input->{port}{default},
		8080,
		'Schema includes port default'
	);

	is(
		$configure_input->{port}{type},
		'integer',
		'Type inferred from integer default'
	);

	is(
		$configure_input->{ssl}{default},
		0,
		'Schema includes ssl default'
	);

	is(
		$configure_input->{ssl}{type},
		'boolean',
		'Type inferred from boolean default'
	);

	is(
		$configure_input->{timeout}{default},
		30.0,
		'Schema includes timeout default'
	);

	is(
		$configure_input->{timeout}{type},
		'number',
		'Type inferred from float default'
	);

	# Test process method with data structures
	my $process_schema = $schemas->{process};
	my $process_input = $process_schema->{input};

	is_deeply(
		$process_input->{items}{default},
		[],
		'Schema includes empty arrayref default'
	);

	is(
		$process_input->{items}{type},
		'arrayref',
		'Type inferred from arrayref default'
	);

	is_deeply(
		$process_input->{options}{default},
		{},
		'Schema includes empty hashref default'
	);

	is(
		$process_input->{options}{type},
		'hashref',
		'Type inferred from hashref default'
	);

	done_testing();
};

# Test 6: Edge cases and tricky patterns
subtest 'Edge Cases and Tricky Patterns' => sub {
	my $module = <<'END_MODULE';
package Test::EdgeCases;
use strict;
use warnings;

sub edge_cases {
	my ($self, $param1, $param2, $param3, $param4, $param5) = @_;

	# Edge case 1: Default with quotes inside quotes
	$param1 = $param1 || "it's complicated";

	# Edge case 2: Default with escaped characters
	$param2 //= "line1\\nline2\\ttab";

	# Edge case 3: Default as expression in parentheses
	$param3 = defined $param3 ? $param3 : (10 + 20);

	# Edge case 4: Default with trailing comment
	$param4 = $param4 || 'default';  # this is a comment

	# Edge case 5: Default with q// operator
	$param5 = $param5 || q{default value};

	return 1;
}

sub no_defaults {
	my ($self, $required) = @_;

	# No default - should be required
	die 'Required!' unless defined $required;

	return 1;
}
END_MODULE

	my $extractor = create_extractor($module);

	# Test edge case method
	my $doc = PPI::Document->new($extractor->{input_file});
	$extractor->{_document} = $doc;

	my $methods = $extractor->_find_methods($doc);
	my $edge_cases = (grep { $_->{name} eq 'edge_cases' } @$methods)[0];

	# Analyze parameters
	my $body = $edge_cases->{body};
	my $code_params = $extractor->_analyze_code($edge_cases->{body});

	# Check specific edge cases
	is(
		$code_params->{param1}{default},
		"it's complicated",
		'Handles quotes inside string default'
	);

is(
	$code_params->{param2}{default},
	"line1\\nline2\\ttab",
	'Preserves escaped characters in default'
);
	is(
		$code_params->{param2}{default},
		"line1\\nline2\\ttab",
		'Preserves escaped characters in default'
	);

	# Note: param3 returns expression "(10 + 20)" which we can't evaluate
	ok(
		$code_params->{param3}{default},
		'Extracts expression default (even if unevaluatable)'
	);

	is(
		$code_params->{param4}{default},
		'default',
		'Ignores trailing comments in default extraction'
	);

	is(
		$code_params->{param5}{default},
		'default value',
		'Extracts default from q{} operator'
	);

	# Test required parameter (no defaults)
	my $no_defaults = (grep { $_->{name} eq 'no_defaults' } @$methods)[0];
	my $no_defaults_params = $extractor->_analyze_code($no_defaults->{body});

	is(
		$no_defaults_params->{required}{optional},
		0,
		'Parameter without default is marked as required'
	);

	ok(
		!exists $no_defaults_params->{required}{default},
		'Required parameter has no default value'
	);

	done_testing();
};

# Test 7: Real-world example
subtest 'Real-World Example' => sub {
	my $module = <<'END_MODULE';
package Test::RealWorld;
use strict;
use warnings;

=head2 connect_to_database

Connect to a database with sensible defaults.

Parameters:
  $host - Database hostname. Default: 'localhost'
  $port - Database port. Default: 3306
  $user - Username. Optional, default: 'app_user'
  $password - Password. Optional, default: undef (no password)
  $database - Database name. Required.
  $ssl - Use SSL connection. Default: false
  $timeout - Connection timeout in seconds. Default: 10

Returns: Database connection object

=cut

sub connect_to_database {
	my ($self, $host, $port, $user, $password, $database, $ssl, $timeout) = @_;

	# Set defaults
	$host //= 'localhost';
	$port = $port || 3306;
	$user = 'app_user' unless defined $user;
	$password //= undef;  # No password by default
	$ssl = defined $ssl ? $ssl : 0;
	$timeout = $timeout // 10;

	# Database is required
	die "Database name is required" unless $database;

	# ... connection logic ...

	return bless {}, 'DB::Connection';
}

=head2 send_email

Send an email with default options.

=cut

sub send_email {
	my ($self, $to, $subject, $body, $options) = @_;

	$to = $to || $ENV{DEFAULT_EMAIL} || 'admin@example.com';
	$subject //= 'No subject';
	$body = defined $body ? $body : '';
	$options ||= { from => 'noreply@example.com', cc => [] };

	# ... email sending logic ...

	return 1;
}
END_MODULE

	my $extractor = create_extractor($module);

	# Extract all schemas
	my $schemas = $extractor->extract_all();

	# Test database connection method
	my $db_schema = $schemas->{connect_to_database};
	my $db_input = $db_schema->{input};

	is(
		$db_input->{host}{default},
		'localhost',
		'Real-world: Database host default'
	);

	is(
		$db_input->{port}{default},
		3306,
		'Real-world: Database port default'
	);

	is(
		$db_input->{user}{default},
		'app_user',
		'Real-world: Database user default'
	);

	is(
		$db_input->{password}{default},
		undef,
		'Real-world: Database password defaults to undef'
	);

	is(
		$db_input->{database}{optional},
		0,
		'Real-world: Database name is required (no default)'
	);

	is(
		$db_input->{ssl}{default},
		0,
		'Real-world: SSL defaults to false'
	);

	is(
		$db_input->{timeout}{default},
		10,
		'Real-world: Timeout default'
	);

	# Test email method
	my $email_schema = $schemas->{send_email};
	my $email_input = $email_schema->{input};

	is(
		$email_input->{subject}{default},
		'No subject',
		'Real-world: Email subject default'
	);

	is(
		$email_input->{body}{default},
		'',
		'Real-world: Email body defaults to empty string'
	);

	# Note: $options default is a hashref with from and cc keys
	my $options_default = $email_input->{options}{default};
	ok(ref $options_default eq 'HASH', 'Real-world: Options defaults to hashref');

	done_testing();
};

# Final summary
done_testing();
