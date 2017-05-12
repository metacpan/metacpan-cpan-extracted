use warnings;
use strict;
use Test::More;
use Test::Exception;

plan tests=>18;

use CGI::Easy::URLconf qw(  setup_path path2view set_param
                            setup_view view2path with_params );


my ($r, $url);


sub show_home_page {}
sub list_articles {}
sub show_article {}
sub add_new_article {}
sub unsupported {}

setup_path(
    '/articles/'        => \&list_articles,
    '/articles.php'     => \&list_articles,
    '/index.php'        => \&show_home_page,
);
setup_path( POST =>
    '/articles/'        => \&add_new_article,
);
setup_view(
    \&list_articles     => '/articles/',
);
setup_path(
    '/article.php'          => \&show_article,
    qr{^/article/(\d+)/$}   => set_param('id') => \&show_article,
    qr{^/old/}              => \&unsupported,
);
setup_view(
    \&show_article          => [
        with_params('id')       => '/article/?/',
    ],
);


$r->{ENV}{REQUEST_METHOD} = 'GET';
$r->{GET} = {};

$r->{path} = '/';
is path2view($r), undef,                    $r->{path};
$r->{path} = '/index.html';
is path2view($r), undef,                    $r->{path};
$r->{path} = '/new/index.php';
is path2view($r), undef,                    $r->{path};

$r->{path} = '/index.php';
is path2view($r), \&show_home_page,         $r->{path};
$r->{path} = '/old/something';
is path2view($r), \&unsupported,            $r->{path};

$r->{path} = '/article/123/';
is path2view($r), \&show_article,           $r->{path};
is_deeply $r->{GET}, {id=>123},             'GET={id=>123}';
$r->{path} = '/article.php';
is path2view($r), \&show_article,           $r->{path};

$r->{path} = '/articles/';
is path2view($r), \&list_articles,          'GET '.$r->{path};
$r->{path} = '/articles.php';
is path2view($r), \&list_articles,          'GET '.$r->{path};

$r->{ENV}{REQUEST_METHOD} = 'POST';

$r->{path} = '/articles/';
is path2view($r), \&add_new_article,        'POST '.$r->{path};
$r->{path} = '/articles.php';
is path2view($r), \&list_articles,          'POST '.$r->{path};

$url = view2path(\&show_home_page);
is $url, '/index.php';
$url = view2path(\&list_articles);
is $url, '/articles/';
$url = view2path(\&show_article, id=>123);
throws_ok { view2path(\&show_article, ID=>123) } qr/not match/;
is $url, '/article/123/';
$url = view2path(\&add_new_article);
is $url, '/articles/';
throws_ok { view2path(\&unsupported) } qr/unknown/;

