#!perl -w

use strict;
use warnings;

use Carp;
use Test::Carp;
use Test::Most tests => 16;

BEGIN { use_ok('CGI::Info') }

CARP: {
	local $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';

	does_carp_that_matches(
		sub {
			local $ENV{'REQUEST_METHOD'} = 'FOO';
			my $i = new_ok('CGI::Info');
			$i->params();
			ok($i->status() == 501);
		},
		qr/^Use/
	);

	does_carp_that_matches(
		sub {
			local $ENV{'REQUEST_METHOD'} = 'POST';

			my $input = 'foo=bar';
			local $ENV{'CONTENT_LENGTH'} = length($input) + 1;	# One more than the length, should error

			open (my $fin, '<', \$input);
			local *STDIN = $fin;

			my $i = new_ok('CGI::Info');
			my %p = %{$i->params()};
			ok(!defined($p{fred}));
			is($p{'foo'}, 'bar', 'foo=bar');
			close $fin;

			# Get the warnings that the object has generated
			my @warnings = grep defined, map { ($_->{'level'} eq 'warn') ? $_->{'message'} : undef } @{$i->messages()};
			cmp_ok(join(';', @warnings), 'eq', 'POST failed: something else may have read STDIN', 'warnings()');
		},
		qr/^POST failed: something else may have read STDIN/
	);

	does_croak_that_matches(sub { CGI::Info->new({ expect => 'foo' }); }, qr/expect has been deprecated/);

	{
		local $ENV{'REQUEST_METHOD'} = 'POST';
		local $ENV{'CONTENT_TYPE'} = 'Multipart/form-data; boundary=-----xyz';
		my $input = <<'EOF';
-------xyz
Content-Disposition: form-data; name="country"

44
-------xyz
Content-Disposition: form-data; name="datafile"; filename="foo.txt"
Content-Type: text/plain

Bar

-------xyz--
EOF
		local $ENV{'CONTENT_LENGTH'} = length($input);
		if(-w '/') {
			# GitHub actions images run as root
			diag('/ is writeable');
			ok(1);
			ok(1);
		} else {
			does_carp_that_matches(sub { new_ok('CGI::Info')->params(upload_dir => '/') }, qr/ isn't writeable$/);
		}
		does_carp_that_matches(sub { new_ok('CGI::Info')->params(upload_dir => 't/carp.t') }, qr/ isn't a full pathname$/);
		does_carp_that_matches(sub { new_ok('CGI::Info')->params(upload_dir => '/t/carp.t') }, qr/ isn't a directory$/);
		# new_ok('CGI::Info')->params(upload_dir => '/t/carp.t');
	}
}
