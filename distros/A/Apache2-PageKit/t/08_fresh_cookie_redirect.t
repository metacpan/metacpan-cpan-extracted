use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw/GET/;

# skip tests if we use a old version of LWP.
plan tests => 4, sub {  have_lwp() && $LWP::VERSION >= 5.76 };

require HTTP::Cookies;

sub HTTP_OK () { 200 }

# simple load test
ok 1;

my $cookie_jar = HTTP::Cookies->new;
Apache::TestRequest::user_agent( cookie_jar => $cookie_jar );
my $url = '/create_and_redirect';
my $r = GET $url;
ok $r->code == HTTP_OK();
my $cookie_cnt = 0;
$cookie_jar->scan(
  sub {
    $cookie_cnt++;
    next unless ( $_[1] eq 'pkit_session_id' );
    ok length( $_[2] ) == 32;
  }
);
ok $cookie_cnt == 1;
