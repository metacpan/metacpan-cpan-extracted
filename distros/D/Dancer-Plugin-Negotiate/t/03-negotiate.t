use Test::Most import => ['!pass'];

my $origin = 'http://example.com/';

{
    package Webservice;
    use Dancer;
    use Dancer::Plugin::Negotiate;

	set views => 't/views';	
	set plugins => {
		Negotiate => {
			languages => [qw[ de en ]],
		}
	};

    get '/' => sub {
		return template negotiate 'index';
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

$R = dancer_response(GET => '/');
header_include("GET /foo", %all_nego,
);
is($R->{content} => 'C');

$R = dancer_response(GET => '/', { headers => [ 'Accept-Language' => 'en' ] });
header_include("GET /foo", %all_nego,
	'Content-Language' => 'en'
);
is($R->{content} => 'EN');

$R = dancer_response(GET => '/', { headers => [ 'Accept-Language' => 'de' ] });
header_include("GET /foo", %all_nego,
	'Content-Language' => 'de'
);
is($R->{content} => 'DE');

diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

done_testing;

