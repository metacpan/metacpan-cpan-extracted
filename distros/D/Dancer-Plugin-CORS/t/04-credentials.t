use Test::Most import => ['!pass'];

my $origin = 'http://example.com/';

{
    package Webservice;
    use Dancer;
    use Dancer::Plugin::CORS;

    get '/foo' => sub { 'foo' };
	share '/foo'
	,	origin => $origin
	,	method => 'GET'
	,	credentials => 1
	;
	
    get '/bar' => sub { 'bar' };
	share '/bar'
	,	method => 'GET'
	,	credentials => 1
	;

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

my %all_cors = (
	'Access-Control-Allow-Origin' => undef,
	'Access-Control-Allow-Credentials' => undef,
	'Access-Control-Expose-Headers' => undef,
	'Access-Control-Max-Age' => undef,
	'Access-Control-Allow-Methods' => undef,
	'Access-Control-Allow-Headers' => undef,
);

$R = dancer_response(OPTIONS => '/foo', { headers => [
	'Access-Control-Request-Method' => 'GET',
	'Origin' => $origin
] });
is($R->status => 200, "OPTIONS /foo (preflight request, with allowed origin)");
header_include("OPTIONS /foo (preflight request, with allowed origin)", %all_cors
,	'Access-Control-Allow-Origin' => $origin
,	'Access-Control-Allow-Methods' => 'GET'
,	'Access-Control-Allow-Credentials' => 'true'
);

$R = dancer_response(OPTIONS => '/bar', { headers => [
	'Access-Control-Request-Method' => 'GET',
	'Origin' => $origin
] });
is($R->status => 200, "OPTIONS /bar (preflight request, with allowed origin)");
header_include("OPTIONS /bar (preflight request, with allowed origin)", %all_cors
);

ok(scalar grep { $_ eq 'For a resource that supports credentials a origin matcher must be specified.' } map { $_->{message} } grep { $_->{level} eq 'warning' } @{read_logs()});

done_testing;

