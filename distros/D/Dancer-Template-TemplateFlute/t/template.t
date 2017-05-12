#! perl

use strict;
use warnings;

use Test::More tests => 76;

use File::Spec;
use Data::Dumper;
use XML::Twig;

use lib File::Spec->catdir( 't', 'lib' );

use Dancer qw/:tests/;

set template => 'template_flute';
set views => 't/views';
set log => 'debug';
set logger => 'console';
set layout => 'main';

use MyTestApp;
use Dancer::Test;

my $resp = dancer_response GET => '/';

response_status_is $resp, 200, "GET / is found";
response_content_like $resp, qr/Hello world/;

$resp = dancer_response GET => '/register';
response_status_is $resp, 200, "GET /register is found";
response_content_like $resp, qr/input name="password"/;

my %form = (
            email => 'pallino',
            password => '1234',
            verify => '5678',
           );

$resp = dancer_response(POST => '/register', { body =>  { %form } });

diag "Checking form keyword and stickyness";
response_status_is $resp, 200, "POST /register found";
check_sticky_form($resp, %form);

$resp = dancer_response(POST => '/login', { body =>  { %form } });

diag "Checking form keyword and stickyness";
response_status_is($resp, 200, "POST /login found")|| exit;
check_sticky_form($resp, %form);

my %other_form = (
                  email_2 => 'pinco',
                  password_2 => 'pazzw0rd',
                 );

# unclear why we have to repeat the request twice. The first call gets
# empty params. It seems more a Dancer::Test bug, because from the app it works.
$resp = dancer_response(POST => '/login', { body => { login => "Login", %other_form } });
$resp = dancer_response(POST => '/login', { body => { login => "Login", %other_form } });

foreach my $f (keys %other_form) {
    my $v = $other_form{$f};
    response_content_like $resp, qr/<input[^>]*name="\Q$f\E"[^>]*value="\Q$v\E"/,
      "Found form field $f => $v";
}



set logger => 'capture';

response_status_is [GET => '/bugged_single'] => 200, "route to bugged single found";

response_status_is [GET => '/bugged_multiple'] => 200, "route to bugged multiple found";

response_status_is [POST => '/bugged_single'] => 200, "route to bugged single found";

response_status_is [POST => '/bugged_multiple'] => 200, "route to bugged multiple found";

is_deeply(read_logs, [
                      {
                       'level' => 'debug',
                       'message' => 'Missing form parameters for forms registration'
                      },
                      {
                       'level' => 'debug',
                       'message' => 'Missing form parameters for forms login, registration'
                      },
                      {
                       'level' => 'debug',
                       'message' => 'Missing form parameters for forms registration'
                      },
                      {
                       'level' => 'debug',
                       'message' => 'Missing form parameters for forms login, registration'
                      },
                     ], "Warning logged in debug as expected");



# values for first form

my %multiple_first = (
                      emailtest => "Fritz",
                      passwordtest => "Frutz",
                      verifytest => "Frotz",
                     );

# values for second form

my %multiple_second = (
                       emailtest_2 => "Hanz",
                       passwordtest_2 => "Hunz",
                      );

# $resp 


$resp = dancer_response (GET => '/multiple');
diag "Checking if the form is clean";
check_sticky_form($resp,
                  emailtest => "",
                  passwordtest => "",
                  verifytest => "",
                  emailtest_2 => "",
                  passwordtest_2 => "");
                  
diag "Checking multiple forms";

$resp = dancer_response (POST => '/multiple', { body => { register => 1, %multiple_first}});
check_sticky_form($resp, %multiple_first);

$resp = dancer_response (GET => '/multiple');
check_sticky_form($resp, %multiple_first);

$resp = dancer_response (POST => '/multiple', { body => { login => 1, %multiple_second}});
check_sticky_form($resp, %multiple_first, %multiple_second);

$resp = dancer_response (GET => '/multiple');
check_sticky_form($resp, %multiple_first, %multiple_second);

$multiple_second{passwordtest_2} = "xXxXx";

$resp = dancer_response (POST => '/multiple', { body => { login => 1, %multiple_second}});
check_sticky_form($resp, %multiple_first, %multiple_second);

$resp = dancer_response (GET => '/multiple');
check_sticky_form($resp, %multiple_first, %multiple_second);


%multiple_first = (
                   first_name => "Pippo",
                   last_name => "Pluto",
                  );
%multiple_second = (
                    gender => "Mixed up",
                    address => "via del pioppo",
                   );


$resp = dancer_response ( GET => '/checkout' );
$resp = dancer_response ( POST => '/checkout', { body => { submit => 1, %multiple_first }});
check_sticky_form($resp, %multiple_first, gender => "", address => "");
$resp = dancer_response ( POST => '/checkout', { body => { submit_details => 1,
                                                           %multiple_second }});
check_sticky_form($resp, %multiple_first, %multiple_second);
$resp = dancer_response ( GET => '/checkout' );
$resp = dancer_response (POST => '/checkout', { body => {
                                                         submit => 1,
                                                         %multiple_first,
                                                         day => 15,
                                                        }
                                              });
check_sticky_form($resp, %multiple_first, %multiple_second);
response_content_like $resp, qr/<option selected="selected" value="15">/;
$resp = dancer_response ( POST => '/checkout', { body => { submit_details => 1,
                                                           %multiple_second,
                                                           year => 2019,
                                                         }});
response_content_like $resp, qr/<option selected="selected" value="15">/,
  "Found sticky day";
response_content_like $resp, qr/<option selected="selected" value="2019">/,
  "Found sticky year";

diag "Trying out of range values";

$multiple_first{first_name} = "Topolino";
$multiple_second{gender} = "Male";

$resp = dancer_response ( GET => '/checkout' );
$resp = dancer_response (POST => '/checkout', { body => {
                                                         submit => 1,
                                                         %multiple_first,
                                                         day => 60,
                                                        }
                                              });
$resp = dancer_response ( GET => '/checkout' );

$resp = dancer_response ( POST => '/checkout', { body => { submit_details => 1,
                                                           %multiple_second,
                                                           year => 2050,
                                                         }});

check_sticky_form($resp, %multiple_first, %multiple_second);

response_content_unlike $resp, qr/<option selected="selected"/,
  "Options are not selected";



$resp = dancer_response GET => '/iter';

response_status_is $resp, 200, "GET / is found";
response_content_like $resp, qr{<option value="b">a</option><option value="d">c</option>}, "Found the dropdown";

$resp = dancer_response GET => '/double-dropdown-noform';

response_content_like $resp,
  qr{<select id="role" name="role"><option value="">Please select role</option><option>1</option><option>2</option><option>3</option><option>4</option></select>}, "No duplicate for a dropdown without form";

$resp = dancer_response GET => '/double-dropdown';

response_content_like $resp,
  qr{<select id="role" name="role"><option value="">Please select role</option><option>1</option><option>2</option><option>3</option><option>4</option></select>},
  "No duplicate for a dropdown with a form";

diag "Testing entities with $XML::Twig::VERSION";

$resp = dancer_response GET => '/ampersand';

response_status_is $resp, 200, "GET /ampersand is found";
response_content_like $resp,
  qr{<select class="countries"><option>Select</option><option>Trinidad&amp;Tobago</option></select>},
  "Testing ampersand injected from data";

sub check_sticky_form {
    my ($res, %params) = @_;
    foreach my $f (keys %params) {
        my $v = $params{$f};
        response_content_like $resp, qr/<input[^>]*name="\Q$f\E"[^>]*value="\Q$v\E"/,
          "Found form field $f => $v";
    }
}
