use strict;
use warnings;
use Test::More;
use Path::Tiny ();
use URI;
use Wallflower::Util qw( links_from );

# setup test data
my @tests = (
    [   '/',
        [   200,
            [ 'Content-Type' => 'text/plain' ],
            Path::Tiny->new( t => 'file-01.html' )
        ],
    ],
    [   '/',
        [   200,
            [ 'Content-Type' => 'text/html' ],
            Path::Tiny->new( t => 'file-01.html' )
        ],
        '/style.css',
        '/#content',
        '/',
        '/',
        '/news.html',
        '/credits.html',
        '/contact.html',
        'http://www.cpan.org/',
        '/img/lorem.png',
    ],
    [   '/foo/bar.css',
        [   200,
            [ 'Content-Type' => 'text/css' ],
            Path::Tiny->new( t => 'file-01.css' )
        ],
        '/foo/foo.css', '/foo/bar.css', '/img.png', '/foo/img_qq.png', '/img_q.png', 'http://example.com/ex.png',
    ],
);

plan tests => scalar @tests;

for my $t (@tests) {
    my ( $url, $response, @expected ) = @$t;
    is_deeply( [ links_from( $response, $url ) ],
        \@expected, "links for $response->[2]" );
}
