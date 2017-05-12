use Test::Most import => ['!pass'];

my $origin = 'http://example.com/';

{
    package Webservice;
    use Dancer;
    use Dancer::Plugin::Negotiate;

    get '/foo' => sub {
		return apply_variant(
			var1 => {
				Quality => 1.000,
				Type => 'text/html',
				Charset => 'iso-8859-1',
				Language => 'en'
			},
			var2 => {
				Quality => 0.950,
				Type => 'text/plain',
				Charset => 'us-ascii',
				Language => 'no'
			},
		);
	};

}

use Dancer::Test;

my ($R);

sub header_include($%) {
	my $testname = shift;
	local %_ = @_;
	while (my ($H, $V) = each %_) {
		if (defined $V) {
			if (ok(exists($R->{headers}->{lc($H)}), "$testname, header $H exists")) {
				is($R->{headers}->{lc($H)} => $V, "$testname, header value $H");
			}
		} else {
			unless (ok(not(exists($R->{headers}->{lc($H)})), "$testname, header $H not exists")) {
				diag("$testname, header $H contains: ".$R->{headers}->{lc($H)});
			}
		}
	}
}

my %all_nego = (
	'Content-Encoding' => undef,
	'Content-Charset' => undef,
	'Content-Language' => undef,
);

$R = dancer_response(GET => '/foo');
header_include("GET /foo", %all_nego,
	'Content-Type' => 'text/html',
	'Content-Charset' => 'iso-8859-1',
	'Content-Language' => 'en',
);
is($R->{content} => 'var1');

$R = dancer_response(GET => '/foo', { headers => [ Accept => 'text/plain' ] });
header_include("GET /foo", %all_nego,
	'Content-Type' => 'text/plain',
	'Content-Charset' => 'us-ascii',
	'Content-Language' => 'no',
);
is($R->{content} => 'var2');

diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

done_testing;

