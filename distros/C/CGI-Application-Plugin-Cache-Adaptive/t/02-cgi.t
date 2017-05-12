use lib qw(t/lib);
use Test::More tests => 6;
use Test::WWW::Mechanize::CGI;

use MyApp;

my $app;
my $mech = Test::WWW::Mechanize::CGI->new;
$mech->cgi(
    sub {
        $app = MyApp->new;
        $app->run;
    }
);

{
    ### no cache
    $mech->get_ok('http://localhost/index.cgi');
    $mech->content_contains('test1');
    is($app->{'Cache::Adaptive::type'}, 'miss');
}

{
    ### cached
    $mech->get_ok('http://localhost/index.cgi');
    $mech->content_contains('test1');
    is($app->{'Cache::Adaptive::type'}, 'hit');
}

