
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw( GET_BODY GET_STR GET_HEAD );
use FindBin;

use Apache2::Const -compile => qw(
    HTTP_OK
);

use lib "$FindBin::Bin/lib";
use Apache2::Controller::Test::Funk qw( diag );
use YAML::Syck;
use URI::Escape;

my $cookie_name = 'testapp_sessid';
my $cookie_path = '/session';

my @CHARS = ('A'..'Z', 'a'..'z', 0 .. 9);
my %TD = (
    foo     => {
        boz     => [qw( noz schnoz )]
    },
    bar     => 'biz',
    floobie => join('', map $CHARS[int(rand @CHARS)], 1 .. 50),
);
my $testdata_dump = Dump(\%TD);

use HTTP::Cookies;
my $jar = HTTP::Cookies->new();

plan tests => 12, need_lwp;
my $ua = Apache::TestRequest::user_agent(
    cookie_jar              => $jar, 
    requests_redirectable   => 0,
);
Apache::TestRequest::lwp_debug(2);

use TestApp::Session::Controller;

my $url = "/session";

my $get = "$url/set?data=".uri_escape($testdata_dump);
my $response = GET_BODY $get;

ok t_cmp($response, "Set session data.\n", "Set data.");

$response = GET_BODY "$url/read";
my $session = Load($response);
my $response_testdata = $session->{testdata};

ok t_cmp(Dump($response_testdata), $testdata_dump, "Read data.");

# what about a redirect?  if i save something in a controller
# that returns redirect, does it actually get saved?
my $redirect = GET_HEAD "$url/redirect";
ok t_cmp($redirect, qr{ ^ \# Location: \s+ \Q$url\E/read }mxs, 'Redirect ok');

my $redirect_set_data = GET_BODY "$url/read";
$session = Load($redirect_set_data);
$response_testdata = Dump($session->{testdata});

ok t_cmp($response_testdata, $testdata_dump, 
    "Read data after redirect - did not save.");

my $error = GET_HEAD "$url/server_error";
ok t_cmp($error, qr{ ^ \# Title: \s+ 500 \s+ Internal \s+ Server \s+ Error }mxs,
    'error page ok' );

# check to make sure the forced-save flag works
my $redirect_force_save = GET_HEAD "$url/redirect_force_save";
ok t_cmp($redirect, qr{ ^ \# Location: \s+ \Q$url\E/read }mxs, 
    'Redirect (force save) ok');

$TD{redirect_data} = 'redirect data test';
$testdata_dump = Dump(\%TD);

my $redirect_forced_data = GET_BODY "$url/read";
$session = Load($redirect_forced_data);
$response_testdata = Dump($session->{testdata});

ok t_cmp($response_testdata, $testdata_dump, 
    "Read data after redirect with forced save - saved data.");

diag("HORTA: jar is '$jar':\n".Dump($jar).$jar->as_string);

my $error_data_set = GET_BODY "$url/read";
$session = Load($error_data_set);
$response_testdata = Dump($session->{testdata});
#diag($response_testdata);


ok t_cmp($response_testdata, $testdata_dump, "Read data after error unchanged.");

my $old_sess_id = q{};
$jar->scan(sub { 
    diag("lame:\n".Dump(\@_));
    $old_sess_id ||= $_[2];
}); # See HTTP::Cookie

diag("session id was '$old_sess_id'");
diag("set raw cookie val to 1 in headers_out (invalid cookie freeze/thaw bug)");
my ($cookie_domain) = keys %{$jar->{COOKIES}}; # ('highlander.therecanbeonly1.com')
diag("cookie domain is '$cookie_domain'");

my $full_url = Apache::TestRequest::module2url('', { path => "$url/read" });
diag("full_url: '$full_url'");

$response = $ua->get($full_url);
ok t_cmp($response->code, Apache2::Const::HTTP_OK, '2xcheck response is HTTP_OK');

my $doublecheck_sess_id = q{};
$jar->scan(sub { $doublecheck_sess_id ||= $_[2] });
diag('double-check');
ok t_cmp($old_sess_id, $doublecheck_sess_id,
    'double-check sess id is the same across requests',
);

diag("SPOCK: '$ua'");
$jar->clear();
diag("KIRK: ".Dump($jar));

$response = $ua->get($full_url, 'Set-Cookie3' => qq{1; path="$cookie_path"; domain=$cookie_domain; discard; version=0});

diag("response code:\n".$response->code);

diag("as_string:\n".$response->as_string);

diag("UHURA: ".Dump($jar));

my $new_sess_id = q{};
$jar->scan(sub { $new_sess_id ||= $_[2] });

ok t_cmp($response->code, Apache2::Const::HTTP_OK, 
    'response after bad cookie is HTTP_OK',
);

ok !t_cmp($new_sess_id, $old_sess_id, 'new sess id is different after bad cookie');
