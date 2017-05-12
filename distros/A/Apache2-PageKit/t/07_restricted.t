use strict;
use warnings;
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw'POST GET';

# skip tests if we use a old version of LWP.
plan tests => 6, sub {  have_lwp() && $LWP::VERSION >= 5.76 };

Apache::TestRequest::user_agent(
                                 reset                 => 1,
                                 cookie_jar            => {},
                                 requests_redirectable => [qw/GET HEAD POST/]
);

# check if we can request a page
my $url = '/restricted';
my $r   = GET $url;
ok $r->is_success;
ok t_cmp( $r->content, qr:\QThis page requires a login.:, "require login" );

# login
$r = POST '/login2',
  [
    login      => 'charlie_00000000',
    passwd     => 'MySecret',
    pkit_done  => '/index',
    pkit_login => 1
  ];
ok t_cmp( 200, $r->code, '$r->code == 200 Found?' );
ok t_cmp( $r->content, qr:\QYou have successfully logged in.:, "Login success?" );
$r = GET $url;
ok $r->is_success;
ok t_cmp( $r->content, qr:\QThis page is only visible if you login recently.:, "require login" );
