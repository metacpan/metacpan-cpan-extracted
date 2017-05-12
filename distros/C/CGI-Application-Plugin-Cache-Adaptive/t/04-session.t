use lib qw(t/lib);
use Test::More tests => 6;
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
    $mech->get_ok("http://localhost/index.cgi/do_test3");
    $mech->content_contains($app->session->id);
    diag('session-id : ', $app->session->id);
    is($app->{'Cache::Adaptive::type'}, 'miss');
}

{
    $mech->get_ok("http://localhost/index.cgi/do_test3");
    $mech->content_contains($app->session->id);
    diag('session-id : ', $app->session->id);
    is($app->{'Cache::Adaptive::type'}, 'miss');
}
