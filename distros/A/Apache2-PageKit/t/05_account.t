use strict;

#use warnings FATAL => 'all';
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw'GET POST';

# skip tests if we use a old version of LWP.
plan tests => 6, sub { have_lwp() && $LWP::VERSION >= 5.76 };
require HTTP::Cookies;
require HTML::Form;
my $cookie_jar = HTTP::Cookies->new;
Apache::TestRequest::user_agent(
                                 reset                 => 1,
                                 cookie_jar            => $cookie_jar,
                                 requests_redirectable => [qw/GET HEAD POST/]
);

# check if we can request a page
my $r = GET '/newacct1';
ok t_cmp( $r->code, 200, '$r->code == HTTP_OK?' );
ok t_cmp( $r->content,
          qr:\Q<title>PageKit.org | New Account</title>:,
          "new account page" );

# not all HTML::Form versions know about parse($r) so we use
# HTML::Form->parse($r->content, $r->base ) instead
#my @forms     = HTML::Form->parse($r);
my @forms = HTML::Form->parse( $r->content, $r->base );
my $pkit_done = eval { $forms[0]->find_input('pkit_done')->value };

my $t = 0;
for ( 0 .. 10 ) {
  my $login = sprintf( "%s_%08x", 'charlie', $t );
  $r = POST '/newacct2',
    [
      email     => 'charlie@brown.xy',
      login     => $login,
      passwd1   => 'MySecret',
      passwd2   => 'MySecret',
      pkit_done => $pkit_done
    ];
  if ( $r->code == 200 ) {
    my $content = $r->content;

    # leave loop if the new account is successfull created and
    # we are logged in
    last if ( $content =~ m:\QYou are logged in as <b>$login</b>.  You may: );
  }
}
continue {

  # choice t randomly, but the first try is with 0
  $t = time + int( rand(1000) );
}

ok t_cmp( 200, $r->code, '$r->code == 200 Found?' );

my $cookie_cnt  = 0;
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
ok $cookie_cnt >= 1;
ok $pkit_id_cnt >= 1;
