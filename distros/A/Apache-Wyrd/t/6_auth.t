use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';
use LWP::UserAgent;

my $ua = LWP::UserAgent->new(
	keep_alive => 1,
	timeout => 30,
	requests_redirectable	=> []
);

plan tests => 7;

my $res = $ua->get('http://localhost:8529/restricted/test.html');
my $cookie = $res->header('Set-Cookie');

ok ($cookie =~ /check_cookie=checking/);

$ua->requests_redirectable(['GET']);
$res = $ua->get('http://localhost:8529/restricted/test.html', Cookie => $cookie);

ok ($res->is_success);

my $content = $res->content;
$content =~ m#<ls>(.+)</ls>.*<on_success>(.+)</on_success>.*<ticket>(.+)</ticket>#s;
my $ls = $1;
my $on_success = $2;
my $ticket = $3;

ok ($ls && $on_success && $ticket);

$ua->requests_redirectable([]);
$res = $ua->get("$ls?on_success=$on_success&ticket=$ticket&username=testuser&password=testing123", Cookie => $cookie);
my $new_location = $res->header('Location');
$res = $ua->get($new_location, Cookie => $cookie);
$cookie = $res->header('Set-Cookie');

ok ($cookie =~ /auth_cookie=/);

$new_location = $res->header('Location');
$res = $ua->get($new_location, Cookie => $cookie);
$content = $res->content;

ok ($content =~ /SETEC ASTRONOMY/);

$res = $ua->get('http://localhost:8529/restricted/test.html', Cookie => $cookie);
$content = $res->content;

ok ($content =~ /SETEC ASTRONOMY/);

$res = $ua->get('http://localhost:8529/15.html', Cookie => $cookie);
$content = $res->content;

ok ($content =~ /\b24\b/);
