use Test::Most import => ['!pass'];

my $origin = 'http://example.com/';

{
    package Webservice;
    use Dancer;
    use Dancer::Plugin::CORS;
	
	my $sub = sub { 1 };

    @_ = get '/code1' => $sub;
	share $_[1]
	,	origin => sub { shift eq $origin }
	,	method => 'GET'
	;
	
    @_ = get '/code2' => $sub;
	share $_[1]
	,	origin => sub { 0 }
	,	method => 'GET'
	;
	
    @_ = get '/code3' => $sub;
	share $_[1]
	,	origin => sub { undef }
	,	method => 'GET'
	;
	
    @_ = get '/code4' => $sub;
	share $_[1]
	,	origin => sub { 1 }
	,	method => 'GET'
	;
	
    @_ = get '/array' => $sub;
	share $_[1]
	,	origin => [ $origin ]
	,	method => 'GET'
	;
	
    @_ = get '/regexp' => $sub;
	share $_[1]
	,	origin => qr{^\Q$origin\E$}
	,	method => 'GET'
	;
	
    @_ = get '/error' => $sub;
	share $_[1]
	,	origin => undef
	,	method => 'GET'
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

foreach my $resource (qw(/code1 /code4 /array /regexp)) {
	$R = dancer_response(GET => $resource, { headers => [
		'Origin' => $origin
	] });
	header_include("GET $resource (OK)", %all_cors
	,	'Access-Control-Allow-Origin' => $origin
	,	'Access-Control-Allow-Methods' => 'GET'
	);
}

foreach my $resource (qw(/code1 /code2 /code3 /array /regexp)) {
	$R = dancer_response(GET => $resource, { headers => [
		'Origin' => $origin.'~'
	] });
	header_include("GET $resource (NOT OK)", %all_cors);
}

diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

done_testing;

