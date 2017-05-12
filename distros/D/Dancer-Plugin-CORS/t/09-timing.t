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
	,	timing => 1
	;
	
    get '/bar' => sub { 'bar' };
	share '/bar'
	,	method => 'GET'
	,	timing => 1
	;
	
    get '/baf' => sub { 'baf' };
	share '/baf'
	,	method => 'GET'
	,	timing => undef
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
	'Timing-Allow-Origin' => undef,
);

$R = dancer_response(GET => '/foo', { headers => [
	'Origin' => $origin,
] });
is($R->status => 200, "GET /foo");
header_include("GET /foo", %all_cors
,	'Access-Control-Allow-Origin' => $origin
,	'Access-Control-Allow-Methods' => 'GET'
,	'Timing-Allow-Origin' => $origin
);

$R = dancer_response(GET => '/bar', { headers => [
	'Origin' => $origin,
] });
is($R->status => 200, "GET /bar");
header_include("GET /bar", %all_cors
,	'Access-Control-Allow-Origin' => '*'
,	'Access-Control-Allow-Methods' => 'GET'
,	'Timing-Allow-Origin' => '*'
);

$R = dancer_response(GET => '/baf', { headers => [
	'Origin' => $origin,
] });
is($R->status => 200, "GET /baf");
header_include("GET /baf", %all_cors
,	'Access-Control-Allow-Origin' => '*'
,	'Access-Control-Allow-Methods' => 'GET'
,	'Timing-Allow-Origin' => 'null'
);

done_testing;

