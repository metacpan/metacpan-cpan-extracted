use Test::Most import => ['!pass'];

my $origin = 'http://example.com/';

{
    package Webservice;
    use Dancer;
    use Dancer::Plugin::CORS;
	
	my $sub = sub {
		my $cors = var 'CORS';
		use Data::Dumper;
		return 0 unless defined $cors;
		return $cors->{rule};
	};

    @_ = get '/foo' => $sub;
	share $_[1]
	,	origin => 'aaa'
	,	method => 'GET'
	,	rule => 1
	;
	share $_[1]
	,	origin => $origin
	,	method => 'GET'
	,	rule => 2
	;
	
    @_ = get '/bar' => $sub;
	share $_[1]
	,	origin => $origin
	,	method => 'GET'
	,	rule => 1
	;
	share $_[1]
	,	origin => $origin
	,	method => 'GET'
	,	rule => 2
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

$R = dancer_response(GET => '/foo', { headers => [
	'Origin' => $origin
] });
header_include("GET /foo (second rule match)", %all_cors
,	'Access-Control-Allow-Origin' => $origin
,	'Access-Control-Allow-Methods' => 'GET'
);
is($R->{content} => 2);

$R = dancer_response(GET => '/bar', { headers => [
	'Origin' => $origin
] });
header_include("GET /bar (first rule match)", %all_cors
,	'Access-Control-Allow-Origin' => $origin
,	'Access-Control-Allow-Methods' => 'GET'
);
is($R->{content} => 1);


diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

done_testing;

