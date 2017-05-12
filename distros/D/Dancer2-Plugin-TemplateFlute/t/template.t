use strict;
use warnings;

BEGIN {
    $ENV{DANCER_CONFDIR} = 't';
}

use Test::More;
use Test::Deep;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;
use XML::Twig;

use lib 't/lib';
use MyTestApp;

sub check_sticky_form {
    my ( $res, %params ) = @_;
    foreach my $f ( keys %params ) {
        my $v = $params{$f};
        like $res->content,
          qr/<input[^>]*name="\Q$f\E"[^>]*value="\Q$v\E"/,
          "Found form field $f => $v";
    }
}

my $url  = 'http://localhost';
my $jar  = HTTP::Cookies->new();
my $test = Plack::Test->create( MyTestApp->to_app );
my $trap = MyTestApp->dancer_app->logger_engine->trapper;

my $res = $test->request( GET "$url/" );
ok $res->is_success, "GET / successful" or diag explain $trap->read;
$jar->extract_cookies($res);
like $res->content, qr/Hello world/, "we got Hello world";

my $req = GET "$url/register";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET /register successful" or diag explain $trap->read;
like $res->content, qr/input name="password"/,
  "we got the password field in the content";

my %form = (
    email    => 'pallino',
    password => '1234',
    verify   => '5678',
);

$req = POST "$url/register", \%form;
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "POST /register successful" or diag explain $trap->read;
note "Checking form keyword and stickyness";
check_sticky_form( $res, %form );

$req = POST "$url/login", \%form;
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "POST /login successful" or diag explain $trap->read;
note "Checking form keyword and stickyness";
check_sticky_form( $res, %form );

my %other_form = (
    email_2    => 'pinco',
    password_2 => 'pazzw0rd',
);

$req = POST "$url/login", { login => "Login", %other_form };
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "POST /login successful" or diag explain $trap->read;
note "Checking form keyword and stickyness";
check_sticky_form( $res, %other_form );

$req = GET "$url/bugged_single";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET /bugged_single successful"
  or diag explain $trap->read;

$req = GET "$url/bugged_multiple";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET /bugged_multiple successful"
  or diag explain $trap->read;

$req = POST "$url/bugged_single";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "POST /bugged_single successful"
  or diag explain $trap->read;

$req = POST "$url/bugged_multiple";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "POST /bugged_multiple successful"
  or diag explain $trap->read;

my $logs = $trap->read;
cmp_deeply $logs,
  superbagof(
    {
        formatted => ignore(),
        'level'   => 'debug',
        'message' => 'Missing form parameters for forms registration'
    },
    {
        formatted => ignore(),
        'level'   => 'debug',
        'message' => 'Missing form parameters for forms login, registration'
    },
    {
        formatted => ignore(),
        'level'   => 'debug',
        'message' => 'Missing form parameters for forms registration'
    },
    {
        formatted => ignore(),
        'level'   => 'debug',
        'message' => 'Missing form parameters for forms login, registration'
    },
  ),
  "Warning logged in debug as expected"
  or diag explain $logs;

# values for first form

my %multiple_first = (
    emailtest    => "Fritz",
    passwordtest => "Frutz",
    verifytest   => "Frotz",
);

# values for second form

my %multiple_second = (
    emailtest_2    => "Hanz",
    passwordtest_2 => "Hunz",
);

$req = GET "$url/multiple";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET /multiple successful" or diag explain $trap->read;
note "Checking if the form is clean";
check_sticky_form(
    $res,
    emailtest      => "",
    passwordtest   => "",
    verifytest     => "",
    emailtest_2    => "",
    passwordtest_2 => ""
);

$trap->read;
$req = POST "$url/multiple", { register => 1, %multiple_first };
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success,
  'POST /multiple successful { register => 1, %multiple_first }'
  or diag explain $trap->read;
check_sticky_form( $res, %multiple_first );

$trap->read;
$req = GET "$url/multiple";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET /multiple successful" or diag explain $trap->read;
check_sticky_form( $res, %multiple_first );

$trap->read;
$req = POST "$url/multiple", { login => 1, %multiple_second };
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success,
  'POST /multiple successful { login => 1, %multiple_second }'
  or diag explain $trap->read;
check_sticky_form( $res, %multiple_first, %multiple_second );

$trap->read;
$req = GET "$url/multiple";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET /multiple successful" or diag explain $trap->read;
check_sticky_form( $res, %multiple_first, %multiple_second );

$multiple_second{passwordtest_2} = "xXxXx";

$trap->read;
$req = POST "$url/multiple", { login => 1, %multiple_second };
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success,
'POST /multiple successful { login => 1, %multiple_second, passwordtest_2 => "xXxXx" }'
  or diag explain $trap->read;
check_sticky_form( $res, %multiple_first, %multiple_second );

$trap->read;
$req = GET "$url/multiple";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET /multiple successful" or diag explain $trap->read;
check_sticky_form( $res, %multiple_first, %multiple_second );

note "Checking multiple forms";
%multiple_first = (
    first_name => "Pippo",
    last_name  => "Pluto",
);
%multiple_second = (
    gender  => "Mixed up",
    address => "via del pioppo",
);

$trap->read;
$req = GET "$url/checkout";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET /checkout successful" or diag explain $trap->read;

$trap->read;
$req = POST "$url/checkout", { submit => 1, %multiple_first };
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success,
  'POST /checkout { submit => 1, %multiple_first } successful'
  or diag explain $trap->read;
check_sticky_form( $res, %multiple_first, gender => "", address => "" );

$trap->read;
$req = POST "$url/checkout", { submit_details => 1, %multiple_second };
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success,
  'POST /checkout { submit_details => 1, %multiple_second } successful'
  or diag explain $trap->read;
check_sticky_form( $res, %multiple_first, %multiple_second );

$trap->read;
$req = GET "$url/checkout";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET /checkout successful" or diag explain $trap->read;

$trap->read;
$req = POST "$url/checkout", { submit => 1, %multiple_first, day => 15 };
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success,
  'POST /checkout { submit => 1, %multiple_first, day => 15 } successful'
  or diag explain $trap->read;
check_sticky_form( $res, %multiple_first, %multiple_second );
like $res->content, qr/<option selected="selected" value="15">/,
  "we also have day 15 selected";

$trap->read;
$req = POST "$url/checkout",
  { submit_details => 1, %multiple_second, year => 2019 };
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success,
'POST /checkout { submit_details => 1, %multiple_second, year => 2019 } successful'
  or diag explain $trap->read;

like $res->content, qr/<option selected="selected" value="15">/,
  "Found sticky day";
like $res->content, qr/<option selected="selected" value="2019">/,
  "Found sticky year";

note "Trying out of range values";

$multiple_first{first_name} = "Topolino";
$multiple_second{gender}    = "Male";

$trap->read;
$req = GET "$url/checkout";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET /checkout successful" or diag explain $trap->read;

$trap->read;
$req = POST "$url/checkout", { submit => 1, %multiple_first, day => 60 };
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success,
  'POST /checkout { submit => 1, %multiple_first, day => 60 } successful'
  or diag explain $trap->read;

$trap->read;
$req = GET "$url/checkout";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET /checkout successful" or diag explain $trap->read;

$trap->read;
$req = POST "$url/checkout",
  { submit_details => 1, %multiple_second, year => 2050 };
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success,
'POST /checkout { submit_details => 1, %multiple_second, year => 2050 } successful'
  or diag explain $trap->read;

check_sticky_form( $res, %multiple_first, %multiple_second );

unlike $res->content, qr/<option selected="selected"/,
  "Options are not selected";

$trap->read;
$req = GET "$url/iter";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET /iter successful" or diag explain $trap->read;

like $res->content,
  qr{<option value="b">a</option><option value="d">c</option>},
  "Found the dropdown";

$trap->read;
$req = GET "$url/double-dropdown-noform";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET /double-dropdown-noform successful"
  or diag explain $trap->read;

like $res->content,
qr{<select id="role" name="role"><option value="">Please select role</option><option>1</option><option>2</option><option>3</option><option>4</option></select>},
  "No duplicate for a dropdown without form";

$trap->read;
$req = GET "$url/double-dropdown";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET /double-dropdown successful"
  or diag explain $trap->read;

like $res->content,
qr{<select id="role" name="role"><option value="">Please select role</option><option>1</option><option>2</option><option>3</option><option>4</option></select>},
  "No duplicate for a dropdown with a form";

diag "Testing entities with $XML::Twig::VERSION";

$trap->read;
$req = GET "$url/ampersand";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET /ampersand successful" or diag explain $trap->read;

like $res->content,
qr{<select class="countries"><option>Select</option><option>Trinidad&amp;Tobago</option></select>},
  "Testing ampersand injected from data";

done_testing;
