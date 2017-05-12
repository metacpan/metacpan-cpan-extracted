use warnings;
use strict;
use Test::More;
use Test::Exception;

plan tests => 16;

use CGI::Easy::URLconf qw(  setup_path path2view set_param
                            setup_view view2path with_params );


my ($r, $url);


sub myabout {}
sub terms {}
sub list_all_articles {}
sub list_articles {}
sub add_article {}

setup_path(
    '/about/'               => \&myabout,
    '/terms.php'            => \&terms,
    qr{\A /articles/ \z}xms => \&list_all_articles,
);
setup_path(
    qr{\A /articles/(\d+)/ \z}xms
        => set_param('year')
        => \&list_articles,
    qr{\A /articles/tag/(\w+)/(\d+)/ \z}xms
        => set_param('tag','year')
        => \&list_articles,
);
setup_path( POST =>
    '/articles/'            => \&add_article,
);
setup_view(
    \&list_all_articles     => '/articles/',
    \&list_articles         => [
        with_params('tag','year')   => '/articles/tag/?/?/',
        with_params('year')         => '/articles/?/',
    ],
);

$r->{ENV}{REQUEST_METHOD} = 'GET';
$r->{path} = '/';
$r->{GET} = {};

is path2view($r), undef,                    $r->{path};

$r->{path} = '/about/';
is path2view($r), \&myabout,                $r->{path};
$url = view2path( \&myabout );
is $url, '/about/',                         '&myabout';

$r->{path} = '/terms.php';
is path2view($r), \&terms,                  $r->{path};

$r->{path} = '/articles/';
is path2view($r), \&list_all_articles,      $r->{path};
$url = view2path( \&list_all_articles );
is $url, '/articles/',                      '&list_all_articles';

is_deeply $r->{GET}, {},                    'GET={}';

$r->{path} = '/articles/2000/';
is path2view($r), \&list_articles,          $r->{path};
is_deeply $r->{GET}, {year=>2000},          'GET={year=>2000}';

$r->{GET} = {year=>1999,x=>5};
$r->{path} = '/articles/tag/Linux/2000/';
is path2view($r), \&list_articles,          $r->{path};
is_deeply $r->{GET}, {tag=>'Linux',year=>2000,x=>5}, 'GET={tag=>"Linux",year=>2000,x=>5}';

$url = view2path( \&list_articles, year=>2010 );
is $url, '/articles/2010/';
$url = view2path( \&list_articles, year=>2010, month=>12 );
is $url, '/articles/2010/?month=12';
$url = view2path( \&list_articles, tag=>'Linux', year=>2010 );
is $url, '/articles/tag/Linux/2010/';
$url = view2path( \&list_articles, tag=>'Linux', year=>2010, month=>12 );
is $url, '/articles/tag/Linux/2010/?month=12';
throws_ok { view2path( \&list_articles, month=>12 ) } qr/not match/;

