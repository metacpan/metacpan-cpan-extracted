#!perl -w

# Check CGI::Buffer correctly sets the Last-Modified header when requested

use strict;
use warnings;
use Test::Most;
use Test::TempDir::Tiny;
use DateTime;
# use Test::NoWarnings;	# HTML::Clean has them

BEGIN {
	use_ok('CGI::Buffer');
}

TEST: {
	LAST_MODIFIED: {
		delete $ENV{'REMOTE_ADDR'};
		delete $ENV{'HTTP_USER_AGENT'};
		delete $ENV{'NO_CACHE'};
		delete $ENV{'NO_STORE'};

		ok(CGI::Buffer::can_cache() == 1);
		ok(CGI::Buffer::is_cached() == 0);

		my $test_count = 13;

		SKIP: {
			eval {
				require CHI;

				CHI->import();
			};

			if($@) {
				$test_count = 4;
				skip 'CHI required to test', 1 if $@;
			}

			my $filename = tempdir() . 'last_mod.t';
			open(my $tmp, '>', $filename);
			print $tmp "use strict;\n";
			print $tmp "use CGI::Buffer;\n";
			print $tmp "use CHI;\n";
			print $tmp "my \$hash = {};\n";
			print $tmp "my \$c = CHI->new(driver => 'Memory', datastore => \$hash);\n";
			print $tmp "CGI::Buffer::init({cache => \$c, cache_key => 'foo'});\n";
			print $tmp "print \"Content-type: text/html; charset=ISO-8859-1\";\n";
			print $tmp "print \"\\n\\n\";\n";
			print $tmp "print \"<HTML><BODY>   Hello World</BODY></HTML>\\n\";\n";

			open(my $fin, '-|', "$^X -Iblib/lib " . $filename);

			my $keep = $_;
			undef $/;
			my $output = <$fin>;
			$/ = $keep;

			close $fin;
			close $tmp;

			ok($output !~ /^Content-Encoding: gzip/m);
			ok($output !~ /^ETag: "/m);

			my ($headers, $body) = split /\r?\n\r?\n/, $output, 2;

			ok($headers =~ /^Last-Modified:\s+(.+)/m);
			my $date = $1;
			ok(defined($date));

			ok($headers =~ /^Content-Length:\s+(\d+)/m);
			my $length = $1;
			ok(defined($length));

			ok($body =~ /^<HTML><BODY>   Hello World<\/BODY><\/HTML>/m);
			ok(CGI::Buffer::is_cached() == 0);

			ok(length($body) eq $length);

			eval {
				require DateTime::Format::HTTP;

				DateTime::Format::HTTP->import();
			};

			if($@) {
				skip 'DateTime::Format::HTTP required to test everything', 1 if $@;
			} else {
				my $dt = DateTime::Format::HTTP->parse_datetime($date);
				ok($dt <= DateTime->now());
			}
		}
		done_testing($test_count);
	}
}
