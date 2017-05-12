use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw/GET/;
# skip tests if we use a old version of LWP.
plan tests => 5, sub {  have_lwp() && $LWP::VERSION >= 5.76 };
require HTTP::Cookies;

sub HTTP_OK () { 200 }

# simple load test
ok 1;

# check if we can request a page
my $url = '/customize?link_color=%23ff9933&text_color=%23ffffff&bgcolor=%23000000&mod_color=%23444444';

# customize colors, to get a session ( and a cookie )
my $r = GET $url;
ok $r->code == HTTP_OK();
my $cookie_jar = HTTP::Cookies->new;
$cookie_jar->extract_cookies($r);

my $cookie_cnt = 0;
$cookie_jar->scan(
  sub {
    $cookie_cnt++;
    next unless ( $_[1] eq 'pkit_session_id' );
    ok length( $_[2] ) == 32;

    # ~ 1 year +- 1 month.
    ok $_[8] > time + ( 365 - 30 ) * 60 * 60 * 24
      && $_[8] < time + ( 365 + 30 ) * 60 * 60 * 24;
  }
);
ok $cookie_cnt == 1;
