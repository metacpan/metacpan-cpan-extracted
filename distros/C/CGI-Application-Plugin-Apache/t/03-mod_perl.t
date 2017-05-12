use strict;
use warnings FATAL => 'all';
use Apache::Test qw(plan ok have_lwp);
use Apache::TestRequest qw(GET);
use Apache::TestUtil qw(t_cmp);

plan( tests => 44, have_lwp() );
Apache::TestRequest::user_agent( cookie_jar => {});

my $response;
my $content;

# 1..3
{
    $response = GET '/mp?rm=query_obj';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode query_obj/);
    ok($content =~ /obj is Apache\d?::Request/);
}

# 4..6
{
    $response = GET '/mp?rm=header';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode header/);
    ok($response->header('Content-Type') =~ /text\/html/); 
}

# 7..9
#{
#    $response = GET '/mp?rm=no_header';
#    ok($response->is_success);
#    $content = $response->content();
#    ok($content =~ /in runmode no_header/);
#    ok($response->header('Content-Type') =~ /text\/plain/); 
#}

# 10
{
    $response = GET '/mp?rm=invalid_header';
    ok($response->is_error);
}

# 11..13
{
    $response = GET '/mp?rm=redirect';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode redirect2/);
    ok($response->header('Content-Type') =~ /text\/html/);
}

# 14..17
{
    $response = GET '/mp?rm=add_header';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode add_header/);
    ok($response->header('Content-Type') =~ /text\/html/);
    ok($response->header('Me') eq 'Myself and I');
}

# 18..21
{
    $response = GET '/mp?rm=cgi_cookie';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode cgi_cookie/);
    ok($response->header('Content-Type') =~ /text\/html/);
    ok($response->header('Set-Cookie') =~ /cgi_cookie=yum/);
}

# 22..25
{
    $response = GET '/mp?rm=apache_cookie';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode apache_cookie/);
    ok($response->header('Content-Type') =~ /text\/html/);
    ok($response->header('Set-Cookie') =~ /apache_cookie=yummier/);
}

# 26..29
{
    $response = GET '/mp?rm=baking_apache_cookie';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode baking_apache_cookie/);
    ok($response->header('Content-Type') =~ /text\/html/);
    ok($response->header('Set-Cookie') =~ /baked_cookie=yummiest/);
}

# 30..34
{
    $response = GET '/mp?rm=cgi_and_apache_cookies';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode cgi_and_apache_cookies/);
    ok($response->header('Content-Type') =~ /text\/html/);
    ok($response->header('Set-Cookie') =~ /cgi_cookie=yum(:|%3A)both/);
    ok($response->header('Set-Cookie') =~ /apache_cookie=yummier(:|%3(A|a))both/);
}

# 35..39
{
    $response = GET '/mp?rm=cgi_and_baked_cookies';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode cgi_and_baked_cookies/);
    ok($response->header('Content-Type') =~ /text\/html/);
    ok($response->header('Set-Cookie') =~ /cgi_cookie=yum(:|%3(A|a))both/);
    ok($response->header('Set-Cookie') =~ /baked_cookie=yummiest(:|%3(A|a))both/);
}

# 40..43
{
    $response = GET '/mp?rm=redirect_cookie';
    ok($response->is_success);
    $content = $response->content();
    ok($response->header('Content-Type') =~ /text\/html/);
    ok($content =~ /in runmode redirect2/);
    ok($content =~ /cookie value = 'mmmm'/);
}

# 44..47
{
    $response = GET '/mp?rm=cookies';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode cookies/);
    ok($response->header('Set-Cookie') =~ /cookie1=mmmm/);
    ok($response->header('Set-Cookie') =~ /cookie2=tasty/);
}





