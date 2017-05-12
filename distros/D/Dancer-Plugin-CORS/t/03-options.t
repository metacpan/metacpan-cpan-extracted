use Test::Most import => ['!pass'];

my $origin = 'http://example.com/';

{
    package Webservice;
    use Dancer;
    use Dancer::Plugin::CORS;

    get '/' => sub { 'foo' };
	share '/'
	,	origin => $origin
	,	methods => [qw[ GET ]]
	,	expose => 'X-Baf'
	,	headers => [qw[ X-Foo X-Bar ]]
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
	'Access-Control-Allow-Origin' => $origin,
	'Access-Control-Allow-Credentials' => undef,
	'Access-Control-Expose-Headers' => 'X-Baf',
	'Access-Control-Max-Age' => undef,
	'Access-Control-Allow-Methods' => 'GET',
	'Access-Control-Allow-Headers' => 'X-Foo, X-Bar',
);

$R = dancer_response(GET => '/', { headers => [
	'Origin' => $origin
] });
header_include("GET /", %all_cors);
	
$R = dancer_response(GET => '/', { headers => [
	'Origin' => $origin,
	'Access-Control-Request-Method' => 'GET',
	'Access-Control-Request-Headers' => 'X-Bar, X-Foo',
] });
header_include("GET /", %all_cors);
	
diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

done_testing;

