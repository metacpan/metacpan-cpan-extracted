use 5.010;
use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;

{
    package App;
    use Dancer2;
    use Dancer2::Plugin::Deferred;

    @{engine('template')->config}{qw(start_tag end_tag)} = qw(<% %>);

    set show_errors => 1;

    set views => path( 't', 'views' );
    set session => 'Simple';

    get '/show' => sub {
      template 'index';
    };

    get '/link' => sub {
      deferred msg => "sayonara";
      template 'link' => { link => uri_for( '/show', {deferred_param} ) };
    };
}

my $test = Plack::Test->create( App->to_app );
my $url  = "http://localhost/";
my $jar  = HTTP::Cookies->new;

{
    my $res = $test->request( GET $url . "show" );
    like $res->content, qr/^message:\s*$/sm, "no messages pending";
    $jar->extract_cookies($res);
}

my $location;
{
    my $req = GET $url . "link";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    $jar->extract_cookies($res);
    $location = $res->content;
    chomp $location;
}

{
    my $req = GET $location;
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    $jar->extract_cookies($res);
    like $res->content, qr/^message: sayonara/sm,
      "message set and returned via keep/link";
}

{
    my $req = GET $url . "show";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    like $res->content, qr/^message:\s*$/sm, "no messages pending";
}

done_testing;

# COPYRIGHT
