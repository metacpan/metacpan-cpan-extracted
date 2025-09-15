#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::Needs 'Test::MockModule';
use File::Temp qw(tempdir);
use JSON::MaybeXS qw(encode_json);
use Test::Returns;

BEGIN { use_ok('CGI::Info') }

# Mock environment for testing
my %mock_env;
my $original_env = \%ENV;

sub setup_mock_env {
	%mock_env = @_;
	%ENV = %mock_env;
}

sub restore_env {
	%ENV = %$original_env;
}

# Test basic parameter parsing
subtest 'Basic parameter parsing' => sub {
	my $info = new_ok('CGI::Info');

	# Test command line mode
	local @ARGV = ('name=John', 'age=30');
	my $params = $info->params();

	is($params->{name}, 'John', 'Command line parameter parsing');
	is($params->{age}, '30', 'Multiple command line parameters');
};

# Test HTTP GET parameter parsing
subtest 'GET request parsing' => sub {
	setup_mock_env(
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'GET',
		QUERY_STRING => 'user=admin&action=login&token=abc123'
	);

	my $info = CGI::Info->new();
	my $params = $info->params();

	is($params->{user}, 'admin', 'GET parameter extraction');
	is($params->{action}, 'login', 'Multiple GET parameters');
	is($params->{token}, 'abc123', 'Token parameter');

	restore_env();
};

# Test POST request parsing
subtest 'POST request parsing' => sub {
	setup_mock_env(
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'POST',
		CONTENT_TYPE => 'application/x-www-form-urlencoded',
		CONTENT_LENGTH => '25'
	);

	# Mock STDIN data
	$CGI::Info::stdin_data = 'username=test&password=secret';

	my $info = CGI::Info->new();
	my $params = $info->params();

	is($params->{username}, 'test', 'POST parameter extraction');
	is($params->{password}, 'secret', 'POST password parameter');

	restore_env();

	$CGI::Info::stdin_data = undef;
};

# Test JSON parsing
subtest 'JSON request parsing' => sub {
	setup_mock_env(
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'POST',
		CONTENT_TYPE => 'application/json',
		CONTENT_LENGTH => '35'
	);

	my $json_data = encode_json({name => 'Alice', role => 'admin'});
	$CGI::Info::stdin_data = $json_data;

	my $info = CGI::Info->new();
	my $params = $info->params();

	is($params->{name}, 'Alice', 'JSON parameter parsing');
	is($params->{role}, 'admin', 'JSON multiple parameters');

	restore_env();
	$CGI::Info::stdin_data = undef;
};

# Test XML parsing
subtest 'XML request parsing' => sub {
	setup_mock_env(
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'POST',
		CONTENT_TYPE => 'text/xml',
		CONTENT_LENGTH => '45'
	);

	$CGI::Info::stdin_data = '<request><user>testuser</user></request>';

	my $info = CGI::Info->new();
	my $params = $info->params();

	ok($params->{XML}, 'XML content stored');
	like($params->{XML}, qr/<user>testuser<\/user>/, 'XML content preserved');

	restore_env();
	$CGI::Info::stdin_data = undef;
};

# Test allow list validation
subtest 'Allow list validation' => sub {
	my $info = CGI::Info->new();

	delete $ENV{'GATEWAY_INTERFACE'};
	delete $ENV{'REQUEST_METHOD'};
	delete $ENV{'QUERY_STRING'};
	local @ARGV = ('allowed=yes', 'forbidden=no');

	my $params = $info->params(
		allow => {
			allowed => undef,  # Any value allowed
			# forbidden parameter not in allow list
		}
	);

	is($params->{allowed}, 'yes', 'Allowed parameter accepted');
	ok(!exists($params->{forbidden}), 'Forbidden parameter rejected');
	is($info->{status}, 422, 'Correct status code for rejected parameter');
};

# Test regex validation
subtest 'Regex validation' => sub {
	my $info = CGI::Info->new();

	local @ARGV = ('user_id=123', 'invalid_id=abc');

	my $params = $info->params(
		allow => {
			user_id => qr/^\d+$/,	 # Numbers only
			invalid_id => qr/^\d+$/,  # Should fail
		}
	);

	is($params->{user_id}, '123', 'Valid numeric parameter accepted');
	ok(!exists($params->{invalid_id}), 'Invalid parameter rejected');
};

# Test exact match validation
subtest 'Exact match validation' => sub {
	my $info = CGI::Info->new();

	local @ARGV = ('action=login', 'action2=register');

	my $params = $info->params(
		allow => {
			action => 'login',	# Exact match required
			action2 => 'login',   # Should fail
		}
	);

	is($params->{action}, 'login', 'Exact match validation passed');
	ok(!exists($params->{action2}), 'Non-matching parameter rejected');
};

# Test custom validation subroutines
subtest 'Custom validation subroutines' => sub {
	my $info = CGI::Info->new();

	local @ARGV = ('even=4', 'odd=3', 'negative=-5');

	my $params = $info->params(
		allow => {
			even => sub {
				my ($key, $value, $info_obj) = @_;
				return $value % 2 == 0;
			},
			odd => sub {
				my ($key, $value, $info_obj) = @_;
				return $value % 2 == 0;  # Should fail for odd numbers
			},
			negative => sub {
				my ($key, $value, $info_obj) = @_;
				return $value >= 0;  # Should fail for negative
			}
		}
	);

	is($params->{even}, '4', 'Custom validation passed for even number');
	ok(!exists($params->{odd}), 'Custom validation failed for odd number');
	ok(!exists($params->{negative}), 'Custom validation failed for negative');
};

# Test Params::Validate::Strict integration
subtest 'Strict validation rules' => sub {
	plan skip_all => 'Params::Validate::Strict not available'
		unless eval { require Params::Validate::Strict; 1 };

	my $info = CGI::Info->new();

	local @ARGV = ('age=25', 'invalid_age=200');

	my $params = $info->params(
		allow => {
			age => {
				type => 'integer',
				min => 0,
				max => 150
			},
			invalid_age => {
				type => 'integer',
				min => 0,
				max => 150
			}
		}
	);

	is($params->{age}, 25, 'Strict validation passed for valid age');
	ok(!exists($params->{invalid_age}), 'Strict validation failed for invalid age');
};

# Test security features - SQL injection detection
subtest 'SQL injection detection' => sub {
	setup_mock_env(
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'GET',
		QUERY_STRING => "search=' OR 1=1--"
	);

	my $info = CGI::Info->new();
	my $params = $info->params();

	is($info->{status}, 403, 'SQL injection blocked with 403 status');
	ok(!defined($params), 'No parameters returned for SQL injection');

	restore_env();
};

# Test XSS injection detection
subtest 'XSS injection detection' => sub {
	setup_mock_env(
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'GET',
		QUERY_STRING => 'comment=<script>alert("xss")</script>'
	);

	# Mock STDIN data so that we don't hang on reading
	$CGI::Info::stdin_data = 'username=test&password=secret';

	my $info = CGI::Info->new();
	my $params = $info->params();

	is($info->{status}, 403, 'XSS injection blocked');
	ok(!defined($params), 'No parameters returned for XSS injection');

	restore_env();
	$CGI::Info::stdin_data = undef;
};

# Test directory traversal detection
subtest 'Directory traversal detection' => sub {
	setup_mock_env(
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'GET',
		QUERY_STRING => 'file=../../../etc/passwd'
	);

	my $info = CGI::Info->new();
	my $params = $info->params();

	is($info->{status}, 403, 'Directory traversal blocked');
	ok(!defined($params), 'No parameters returned for directory traversal');

	restore_env();
};

# Test User-Agent SQL injection detection
subtest 'User-Agent SQL injection detection' => sub {
	setup_mock_env(
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'GET',
		QUERY_STRING => 'q=test',
		HTTP_USER_AGENT => "Mozilla' AND 1=1 ORDER BY 1--"
	);

	my $info = CGI::Info->new();
	my $params = $info->params();

	is($info->{status}, 403, 'User-Agent SQL injection blocked');
	ok(!defined($params), 'No parameters returned for malicious User-Agent');

	restore_env();
};

# Test file upload validation
subtest 'File upload validation' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	setup_mock_env(
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'POST',
		CONTENT_TYPE => 'multipart/form-data; boundary=test123',
		CONTENT_LENGTH => '100'
	);

	my $info = CGI::Info->new();

	# Test without upload_dir
	$CGI::Info::stdin_data = '{}';
	my $params = $info->params();
	ok(!defined($params), 'Upload rejected without upload_dir');

	# Test with invalid upload_dir
	$params = $info->params(upload_dir => '/invalid/path');
	is($info->{status}, 500, 'Invalid upload directory rejected');

	# Test with valid upload_dir in temp area
	$params = $info->params(upload_dir => $temp_dir);
	# Should pass validation (actual multipart parsing would need more setup)

	restore_env();
	$CGI::Info::stdin_data = undef;
};

# Test parameter caching
subtest 'Parameter caching' => sub {
	delete $ENV{'GATEWAY_INTERFACE'};
	delete $ENV{'REQUEST_METHOD'};
	delete $ENV{'QUERY_STRING'};
	my $info = CGI::Info->new();

	local @ARGV = ('cached=value');

	my $params1 = $info->params();
	my $params2 = $info->params();

	is($params1, $params2, 'Parameters are cached on repeat calls');
	is($params1->{cached}, 'value', 'Cached parameters retain values');
};

# Test param() method
subtest 'param() method' => sub {
	my $info = CGI::Info->new();

	local @ARGV = ('name=John', 'age=30');

	is($info->param('name'), 'John', 'Single parameter retrieval');
	is($info->param('age'), '30', 'Numeric parameter as string');
	is($info->param('missing'), undef, 'Missing parameter returns undef');

	# Test param() without arguments (should call params())
	my $all_params = $info->param();
	is_deeply($all_params, {name => 'John', age => '30'}, 'param() without args returns all');
};

# Test param() with allow list
subtest 'param() with allow list' => sub {
	my $info = CGI::Info->new(carp_on_warn => 1);

	local @ARGV = ('allowed=yes', 'forbidden=no');

	# Set up allow list
	$info->params(allow => { allowed => undef });

	is($info->param('allowed'), 'yes', 'Allowed parameter accessible via param()');

	# Test accessing forbidden parameter
	my $warnings = '';
	local $SIG{__WARN__} = sub { $warnings .= $_[0] };

	is($info->param('forbidden'), undef, 'Forbidden parameter returns undef');
	like($warnings, qr/forbidden.*isn't in the allow list/, 'Warning generated for forbidden access');
};

# Test edge cases and error conditions
subtest 'Edge cases and error conditions' => sub {
	my $info = CGI::Info->new();

	# Test empty parameters
	local @ARGV = ();
	my $params = $info->params();
	ok(!defined($params), 'Empty parameters return undef');

	# Test malformed key=value pairs
	local @ARGV = ('=value', 'key=', 'malformed');
	$params = $info->params();

	ok(!exists($params->{''}), 'Empty key ignored');
	is($params->{key}, undef, 'Empty value handled correctly');
	ok(!exists($params->{malformed}), 'Malformed pair without = ignored');
};

# Test URL decoding
subtest 'URL decoding' => sub {
	my $info = CGI::Info->new();

	local @ARGV = ('name=John%20Doe', 'email=test%40example.com', 'plus=a+b');

	my $params = $info->params();

	is($params->{name}, 'John Doe', 'Space decoding from %20');
	is($params->{email}, 'test@example.com', 'At symbol decoding from %40');
	is($params->{plus}, 'a b', 'Plus to space conversion');
};

# Test duplicate parameter handling
subtest 'Duplicate parameter handling' => sub {
	my $info = CGI::Info->new();

	# Simulate duplicate parameters (normally from query string)
	local @ARGV = ('tag=red', 'tag=blue', 'tag=green');

	my $params = $info->params();

	# Should combine with commas
	is($params->{tag}, 'red,blue,green', 'Duplicate parameters combined with commas');
};

# Test content length validation
subtest 'Content length validation' => sub {
	setup_mock_env(
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'POST',
		CONTENT_TYPE => 'application/x-www-form-urlencoded'
	);

	my $info = CGI::Info->new();

	# Test missing content length
	my $params = $info->params();
	is($info->{status}, 411, 'Missing content length returns 411');

	# Test invalid content length
	$ENV{CONTENT_LENGTH} = 'invalid';
	$params = $info->params();
	is($info->{status}, 411, 'Invalid content length returns 411');

	# Test oversized content
	$info = CGI::Info->new();
	$info->{max_upload_size} = 100;
	$ENV{CONTENT_LENGTH} = '1000';
	$params = $info->params();
	is($info->{status}, 413, 'Oversized content returns 413');

	restore_env();
};

# Test HTTP method validation
subtest 'HTTP method validation' => sub {
	# Test OPTIONS method
	setup_mock_env(
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'OPTIONS'
	);

	my $info = CGI::Info->new();
	my $params = $info->params();
	is($info->{status}, 405, 'OPTIONS method returns 405');

	# Test DELETE method
	$ENV{REQUEST_METHOD} = 'DELETE';
	$params = $info->params();
	is($info->{status}, 405, 'DELETE method returns 405');

	# Test unsupported method
	$ENV{REQUEST_METHOD} = 'PATCH';
	$params = $info->params();
	is($info->{status}, 501, 'Unsupported method returns 501');

	restore_env();
};

# Test testing flags
subtest 'Testing flags' => sub {
	local %ENV;
	delete $ENV{'GATEWAY_INTERFACE'};
	delete $ENV{'REQUEST_METHOD'};
	delete $ENV{'QUERY_STRING'};
	my $info = CGI::Info->new();

	# Test robot flag
	local @ARGV = ('--robot', 'param=value');
	my $params = $info->params();

	ok($info->{is_robot}, 'Robot flag sets is_robot');
	is($params->{param}, 'value', 'Parameters parsed after flag');

	# Test mobile flag
	$info = CGI::Info->new();
	local @ARGV = ('--mobile', 'device=phone');
	$params = $info->params();

	ok($info->{is_mobile}, 'Mobile flag sets is_mobile');

	# Test search engine flag
	$info = CGI::Info->new();
	local @ARGV = ('--search-engine', 'bot=google');
	$params = $info->params();

	ok($info->{is_search_engine}, 'Search engine flag sets is_search_engine');

	# Test tablet flag
	$info = CGI::Info->new();
	local @ARGV = ('--tablet', 'screen=large');
	$params = $info->params();

	ok($info->{is_tablet}, 'Tablet flag sets is_tablet');
};

# Test NUL byte poisoning protection
subtest 'NUL byte poisoning protection' => sub {
	my $info = CGI::Info->new();

	# NUL bytes in parameters should be stripped
	local $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	local $ENV{'REQUEST_METHOD'} = 'GET';
	local $ENV{'QUERY_STRING'} = "key\0poison=value&clean=test\0null";

	my $params = $info->params();

	is($params->{keypoison}, 'value', 'NUL bytes stripped from key');
	is($params->{clean}, 'testnull', 'NUL bytes stripped from value');
};

# Performance and memory tests
subtest 'Performance considerations' => sub {
	local %ENV;
	delete $ENV{'GATEWAY_INTERFACE'};
	delete $ENV{'REQUEST_METHOD'};
	delete $ENV{'QUERY_STRING'};
	my $info = CGI::Info->new();

	# Test with large number of parameters
	my @large_argv;
	for my $i (1..1000) {
		push @large_argv, "param$i=value$i";
	}

	local @ARGV = @large_argv;

	my $start_time = time;
	my $params = $info->params();
	my $end_time = time;

	ok($params, 'Large parameter set processed successfully');
	returns_is($params, { type => 'hashref', 'min' => 1000, 'max' => 1000 }, 'All parameters processed');

	# Should complete reasonably quickly (within 5 seconds)
	ok($end_time - $start_time < 5, 'Performance acceptable for large parameter set');
};

# Test logger integration
subtest 'Logger integration' => sub {
	my @log_messages;

	# Mock logger that captures messages
	my $mock_logger = sub {
		push @log_messages, @_;
	};

	my $info = CGI::Info->new();

	local @ARGV = ('test=value');

	my $params = $info->params(logger => $mock_logger);

	# Should have debug messages about parameters
	ok(@log_messages > 0, 'Logger received messages');
};

# Test Return::Set integration
subtest 'Return::Set integration' => sub {
	local %ENV;

	delete $ENV{'GATEWAY_INTERFACE'};
	delete $ENV{'REQUEST_METHOD'};
	delete $ENV{'QUERY_STRING'};

	my $info = CGI::Info->new();

	local @ARGV = ('param=value');

	my $params = $info->params();

	# Test that Return::Set constraints are applied
	returns_is($params, { type => 'hashref', min => 1 }, 'Returns::Set returns what we expect');

	# Test param() return type
	my $single_param = $info->param('param');
	ok(defined($single_param), 'Single parameter returns defined value');
};

done_testing();
