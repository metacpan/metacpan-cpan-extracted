use utf8;

use strict;
use warnings;
use open qw(:std :utf8);

use Test::More;
use Net::CIDR qw(cidrvalidate);

my $class  = 'App::ipinfo';
my $method = 'get_info';

subtest 'sanity' => sub {
	use_ok $class;
	can_ok $class, $method;
	};

# these should fail validation
subtest 'bad IPs' => sub {
	my @bad_ips = qw(
		345.0.0.1
		::XYZ
		abc
		);

	foreach my $ip ( @bad_ips ) {
		subtest $ip => sub {
			open my $stdout, '>:raw', \ my $out;
			open my $stderr, '>:raw', \ my $err;

			my $app = $class->new(
				output_fh => $stdout,
				error_fh  => $stderr,
				);
			isa_ok $app, $class;

			$app->$method($ip);

			close $stderr;
			close $stdout;

			is $out, undef, 'nothing in standard output';
			like $err, qr/does not look like an IP address/, "error output notes <$ip> does not look like an IP address";
			};
		}
	};

# these should pass validation but fail to get info
subtest 'bogon' => sub {
	my @bogons = qw(
		10.0.0.1
		192.168.1.1
		::
		::1
		2001:db8::
		);

	foreach my $ip ( @bogons ) {
		subtest $ip => sub {
			open my $stdout, '>:raw', \ my $out;
			open my $stderr, '>:raw', \ my $err;

			my $app = $class->new(
				output_fh => $stdout,
				error_fh  => $stderr,
				);
			isa_ok $app, $class;

			ok cidrvalidate($ip), "<$ip> validates";

			$app->$method($ip);

			close $stderr;
			close $stdout;

			is $out, undef, 'nothing in standard output';
			like $err, qr/is a bogon/, "error output notes <$ip> is a bogon" or
				diag explain $app->{last_response};
			};
		}
	};

done_testing();
