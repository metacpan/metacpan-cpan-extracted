use strict;
use warnings;
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw'GET POST';

# skip tests if we use a old version of LWP.
plan tests => 9, sub {  have_lwp() && $LWP::VERSION >= 5.76 };

require HTTP::Cookies;

my $cookie_jar = HTTP::Cookies->new;

Apache::TestRequest::user_agent(
                                 reset                 => 1,
                                 cookie_jar            => $cookie_jar,
                                 requests_redirectable => [qw/GET HEAD POST/]
);

 my  $r = POST '/login2',
    [
      login     => '_illegal_login_',
      passwd   => 'wrong_secret',
      pkit_done => '/index',
      pkit_login => 1
    ];

 ok t_cmp( 200, $r->code, '$r->code == 200 Found?' );
  ok t_cmp( $r->content, qr:\QYour login/password is invalid. Please try again.:, "Invalid Login?");

   $r = POST '/login2',
    [
      login     => 'charlie_00000000',
      passwd   => 'wrong_secret',
      pkit_done => '/index',
      pkit_login => 1
    ];
 ok t_cmp( 200, $r->code, '$r->code == 200 Found?' );
  ok t_cmp( $r->content, qr:\QYour login/password is invalid. Please try again.:, "Login Invalid?");
 
   $r = POST '/login2',
    [
      login     => 'charlie_00000000',
      passwd   => 'MySecret',
      pkit_done => '/index',
      pkit_login => 1
    ];
 ok t_cmp( 200, $r->code, '$r->code == 200 Found?' );
  ok t_cmp( $r->content, qr:\QYou have successfully logged in.:, "Login success?"); 


my $cookie_cnt = 0;
my $pkit_id_cnt = 0;
$cookie_jar->scan(
  sub {
    $cookie_cnt++;
    next unless ( $_[1] eq 'pkit_id' );
    $pkit_id_cnt++;
    # cookie has no expire field and or discard is set
    ok( !$_[8] or $_[9] );    # temp cookie
  }
);
ok $cookie_cnt  >= 1;
ok $pkit_id_cnt >= 1;
