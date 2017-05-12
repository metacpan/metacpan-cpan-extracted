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
	,	origin => $origin
	,	rule => 1
	;
	
    @_ = post '/foo' => $sub;
	share $_[0]
	,	origin => $origin
	,	rule => 2
	;
	
	hook after => sub {
		my $cors = var 'CORS';
		Dancer::SharedData->response->headers('X-Rule' => $cors->{rule} || 0);
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

my %all_cors = (
	'Access-Control-Allow-Origin' => undef,
	'Access-Control-Allow-Credentials' => undef,
	'Access-Control-Expose-Headers' => undef,
	'Access-Control-Max-Age' => undef,
	'Access-Control-Allow-Methods' => undef,
	'Access-Control-Allow-Headers' => undef,
);

diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

$R = dancer_response(OPTIONS => '/foo', { headers => [
	'Access-Control-Request-Method' => 'GET',
	'Origin' => $origin
] });

diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

header_include("GET /foo (first rule match)", %all_cors
,	'Access-Control-Allow-Origin' => $origin
,	'Access-Control-Allow-Methods' => 'GET'
,	'X-Rule' => 1
);

diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

$R = dancer_response(OPTIONS => '/foo', { headers => [
	'Access-Control-Request-Method' => 'POST',
	'Origin' => $origin
] });

diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

header_include("POST /foo (second rule match)", %all_cors
,	'Access-Control-Allow-Origin' => $origin
,	'Access-Control-Allow-Methods' => 'POST'
,	'X-Rule' => 2
);


diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

done_testing;
