
use Apache::Test qw(:withtestmore);
use Apache::TestRequest qw(GET POST);
use Apache2::Const -compile => qw(:common); 

use Test::More no_plan => 1;
use Test::Group;

test 'sitemap.xml 1 - status ok' => sub {
    my $res = GET '/sitemap.xml';
    is($res->message, 'OK', 'Request is ok');
    is($res->code, '200', 'Request is ok');
};

test 'sitemap.xml 2 - status ok' => sub {
    my $res = GET '/music/sitemap.xml';
    is($res->message, 'OK', 'Request is ok');
    is($res->code, '200', 'Request is ok');
};

test 'sitemap.xml 2 - status ok' => sub {
    my $res = GET '/archives/sitemap.xml';
    is($res->message, 'OK', 'Request is ok');
    is($res->code, '200', 'Request is ok');
};
