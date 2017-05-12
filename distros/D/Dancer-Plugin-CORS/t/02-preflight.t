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
	,	maxage => 1111
	;
	
	my @routes = get('/bar' => sub { 'bar' });
	share $routes[1]
	,	origin => $origin
	,	maxage => 1111
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

foreach my $resource (qw(/foo /bar)) {

	diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

	$R = dancer_response(OPTIONS => $resource);
	diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

	is($R->status => 200, "OPTIONS $resource (preflight request, no origin)");
	header_include("OPTIONS $resource (preflight request, no origin)", %all_cors);
	
	$R = dancer_response(OPTIONS => $resource, { headers => [
		'Access-Control-Request-Method' => 'GET',
		'Origin' => $origin
	] });
	diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

	is($R->status => 200, "OPTIONS $resource (preflight request, with allowed origin)");
	header_include("OPTIONS $resource (preflight request, with allowed origin)", %all_cors
	,	'Access-Control-Allow-Origin' => $origin
	,	'Access-Control-Allow-Methods' => 'GET'
	,	'Access-Control-Max-Age' => 1111
	);
	
	$R = dancer_response(OPTIONS => $resource, { headers => [
		'Access-Control-Request-Method' => 'GET',
		'Origin' => $origin.'~'
	] });
	diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

	is($R->status => 200, "OPTIONS $resource (preflight request, with unknown origin)");
	header_include("OPTIONS $resource (preflight request, with unknown origin)", %all_cors);

}

diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

done_testing;

