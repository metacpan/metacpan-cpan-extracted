#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use File::Temp qw/tempfile/;
use Test::Most;

# Load the module being tested
BEGIN { use_ok('CGI::Info') }

local %ENV;
$ENV{'SCRIPT_NAME'} = 'test_script';
$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0';

# Test object creation
my $cgi_info = new_ok('CGI::Info');
ok($cgi_info, 'CGI::Info object created');

# Test script_name method
can_ok($cgi_info, 'script_name');
my $script_name = $cgi_info->script_name();
is($script_name, $ENV{'SCRIPT_NAME'}, 'script_name matches the environment variable');

# Test host_name method
can_ok($cgi_info, 'host_name');
like($cgi_info->host_name(), qr/\w+/, 'host_name returns a valid string');

# Test is_mobile method
can_ok($cgi_info, 'is_mobile');
is($cgi_info->is_mobile(), 0, 'is_mobile returns false by default (not a mobile device)');

# Helper to mock environment variables
sub mock_env {
	my ($env, $code) = @_;
	local %ENV = %$env;
	$code->();
}

subtest 'CGI::Info' => sub {
	subtest 'Constructor (new)' => sub {
		subtest 'should handle invalid parameters gracefully' => sub {
		throws_ok { CGI::Info->new('invalid_param', 'value', 'another parm') } qr/Invalid arguments/, 'Dies on invalid args';
		};

		subtest 'should load config file if provided' => sub {
			my ($fh, $config_file) = tempfile(TEMPLATE => 'test_configXXXX', SUFFIX => '.yml');
			print $fh "---\nmax_upload_size: 100\n";
			close $fh;

			my $info = CGI::Info->new(config_file => $config_file);
			is $info->{max_upload_size}, 100, 'Config file loaded correctly';
			unlink $config_file;
		};

		subtest 'should reject non-ARRAY expect parameter' => sub {
			throws_ok { CGI::Info->new(expect => {}) } qr/expect must be a reference/, 'Rejects non-array expect';
		};
	};

	subtest 'script_name, script_path, script_dir' => sub {
		subtest 'should handle CLI environment' => sub {
			mock_env({}, sub {
				my $info = CGI::Info->new();
				like $info->script_name, qr/\w+\.t/, "Script name from \$0 in CLI";
				ok -e $info->script_path, 'Script path exists';
				ok -d $info->script_dir, 'Script directory exists';
			});
		};

		subtest 'should handle CGI environment' => sub {
			mock_env({ SCRIPT_NAME => '/cgi-bin/test.cgi', DOCUMENT_ROOT => '/var/www' }, sub {
				my $info = CGI::Info->new();
				is $info->script_name, 'test.cgi', 'Correct script name from SCRIPT_NAME';
				like $info->script_path, qr/\/var\/www\/cgi-bin\/test\.cgi/, 'Script path constructed correctly';
			});
		};
	};

	subtest 'params method' => sub {
		subtest 'should handle GET requests' => sub {
			mock_env({
		GATEWAY_INTERFACE => 'CGI/1.1',
				REQUEST_METHOD => 'GET',
				QUERY_STRING => 'name=John&age=30'
			}, sub {
				my $info = CGI::Info->new();
				my $params = $info->params;
				is $params->{name}, 'John', "GET param 'name' correct";
				is $params->{age}, '30', "GET param 'age' correct";
			});
		};

		subtest 'should block SQL injection attempts' => sub {
			mock_env({
		GATEWAY_INTERFACE => 'CGI/1.1',
				REQUEST_METHOD => 'GET',
				QUERY_STRING => 'id=1%27%20OR%201=1--'
			}, sub {
				my $info = CGI::Info->new(allow => { id => qr/^\d+$/ });
				my $params = $info->params;
				is $info->status, 422, 'Status 422 on SQL injection';
				ok !defined $params->{id}, 'Blocked malicious parameter';
			});
		};

		subtest 'should handle multipart form uploads' => sub {
			mock_env({
		GATEWAY_INTERFACE => 'CGI/1.1',
				REQUEST_METHOD => 'POST',
				CONTENT_TYPE	=> 'multipart/form-data; boundary=----boundary',
				CONTENT_LENGTH => 1000
			}, sub {
				local *STDIN;
				open STDIN, '<', \"------boundary\nContent-Disposition: form-data; name=\"file\"; filename=\"test.txt\"\n\ncontent\n------boundary--";
				my $info = CGI::Info->new(upload_dir => File::Spec->tmpdir());
				my $params = $info->params;
				like $params->{file}, qr/test\.txt/, 'File upload handled';
			});
		};

		subtest 'should reject oversized uploads' => sub {
			mock_env({
		GATEWAY_INTERFACE => 'CGI/1.1',
				REQUEST_METHOD => 'POST',
				CONTENT_TYPE   => 'application/x-www-form-urlencoded',
				CONTENT_LENGTH => 600 * 1024	# 600KB
			}, sub {
				my $info = CGI::Info->new(max_upload => 500);	# 500KB limit
				my $params = $info->params;
				is $info->status, 413, 'Status 413 on oversized upload';
				ok !defined $params, 'No params returned';
			});
		};
	};

	subtest 'Security Checks' => sub {
		subtest 'should block XSS attempts' => sub {
			mock_env({
		GATEWAY_INTERFACE => 'CGI/1.1',
				REQUEST_METHOD => 'GET',
				QUERY_STRING   => 'comment=<script>alert(1)</script>'
			}, sub {
				my $info = CGI::Info->new();
				my $params = $info->params;
				unlike $params->{comment}, qr/<script>/, 'XSS attempt sanitized';
			});
		};

		subtest 'should prevent directory traversal' => sub {
			mock_env({
		GATEWAY_INTERFACE => 'CGI/1.1',
				REQUEST_METHOD => 'GET',
				QUERY_STRING  => 'file=../../etc/passwd'
			}, sub {
				my $info = new_ok('CGI::Info');
				my $params = $info->params();
				is($info->status(), 403, 'Status 403 on traversal attempt');
			});
		};
	};

	subtest 'User Agent Detection' => sub {
		subtest 'should detect mobile devices' => sub {
			mock_env({ HTTP_USER_AGENT => 'Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75 Mobile/14E5239e Safari/602.1' }, sub {
				my $info = CGI::Info->new();
				ok $info->is_mobile, 'iPhone detected as mobile';
			});
		};

		subtest 'should detect search engines' => sub {
			mock_env({
				REMOTE_ADDR => '66.249.65.32',
				HTTP_USER_AGENT => 'Googlebot/2.1 (+http://www.google.com/bot.html)'
			}, sub {
				my $info = new_ok('CGI::Info');
				ok $info->is_search_engine, 'Googlebot detected as search engine';
			});
		};
	};

	subtest 'Directory Methods' => sub {
		subtest 'should find valid tmpdir' => sub {
			my $info = new_ok('CGI::Info');
			ok -d $info->tmpdir, 'tmpdir exists and is directory';
		};

		subtest 'should handle non-writable logdir' => sub {
			my $info = new_ok('CGI::Info');
			throws_ok { $info->logdir('/non/existent/path') } qr/Invalid logdir/, 'Handles invalid logdir';
		};
	};

	subtest 'AUTOLOAD' => sub {
		subtest 'should delegate unknown methods to param' => sub {
			mock_env({
				GATEWAY_INTERFACE => 'CGI/1.1',
				REQUEST_METHOD => 'GET',
				QUERY_STRING => 'test=value'
			}, sub {
				my $info = new_ok('CGI::Info');
				is($info->test(), 'value', 'AUTOLOAD delegates to param');
				$info = CGI::Info->new('auto_load' => 0);
				throws_ok { $info->test() } qr/Unknown method/, 'auto_load can be disabled';
			});
		};
	};
};

done_testing();
