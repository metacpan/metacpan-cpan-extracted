use lib qw(t/lib);
use Test::More tests => 9;
use Test::WWW::Mechanize::CGI;

use MyApp;

my $app;
my $mech = Test::WWW::Mechanize::CGI->new;
$mech->cgi(
    sub {
        $app = MyApp->new;
        $app->mode_param( path_info => 2 );
        $app->run;
    }
);

{
    ### no cache
    $mech->get_ok('http://localhost/index.cgi/do_test2');
    $mech->content_contains('test2');
    is($app->{'Cache::Adaptive::type'}, 'miss');
}

{
    ### no cached
    $mech->get_ok('http://localhost/index.cgi/do_test2/?foo=bar');
    $mech->content_contains('test2');
    is($app->{'Cache::Adaptive::type'}, 'miss');
}

{
    ### no cached
    $mech->get_ok('http://localhost/index.cgi/do_test2/?foo=bar&hoge=fuga');
    $mech->content_contains('test2');
    is($app->{'Cache::Adaptive::type'}, 'miss');
}

