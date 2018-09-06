use strict;
use warnings;
use Test::More;
use Path::Tiny ();
use List::Util qw( sum );
use Wallflower;

# setup test data
my @tests;

# test data is an array ref containing:
# - quick description of the app
# - destination directory
# - the app itself
# - a list of test url for the app
#   as [ url, status, headers, file, content ]

push @tests, [
    'direct content',
    Path::Tiny->tempdir,
    sub {
        my $env = shift;
        require Plack::Request;
        my $req = Plack::Request->new($env);
        my $uri = $req->uri;

        [   200,
            [ 'Content-Type' => 'text/plain', 'Content-Length' => length($uri) ],
            [ $uri ]
        ];
    },
    [   '/' => 200,
        [ 'Content-Type' => 'text/plain', 'Content-Length' => 24 ],
        'index.html',
        'https://ssl.example.com/'
    ],
    [   '/clunk' => 200,
        [ 'Content-Type' => 'text/plain', 'Content-Length' => 29 ],
        'clunk', 'https://ssl.example.com/clunk'
    ],
];

plan tests => sum map 2 * ( @$_ - 3 ), @tests;

for my $t (@tests) {
    my ( $desc, $dir, $app, @urls ) = @$t;

    my $wf = Wallflower->new(
        application => $app,
        destination => $dir,
        url         => 'https://ssl.example.com/',
    );

    for my $u (@urls) {
        my ( $url, $status, $headers, $file, $content ) = @$u;

        my $result = $wf->get($url);
        is_deeply(
            $result,
            [   $status, $headers, $file && File::Spec->catfile( $dir, $file )
            ],
            "app ($desc) for $url"
        );

        if ( $status eq '200' ) {
            my $file_content
                = do { local $/; local @ARGV = ( $result->[2] ); <> };
            is( $file_content, $content, "content ($desc) for $url" );
        }
        else {
            is( $result->[2], '', "no file ($desc) for $url" );
        }
    }
}

