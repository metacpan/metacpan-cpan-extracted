use strict;
use warnings;
use Test::More;
use List::Util qw( sum );
use URI;
use HTTP::Date qw( str2time );
use Path::Tiny ();
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
        if ($env->{PATH_INFO} !~ m!^/?$!) {
            return [
                404,
                [ 'Content-Type' => 'text/plain', 'Content-Length' => 3 ],
                [ '404' ]
            ];
        }

        [   200,
            [ 'Content-Type' => 'text/plain', 'Content-Length' => 13 ],
            [ 'Hello,', ' ', 'World!' ]
        ];
    },
    [   '/mmm' => 200,
        [ 'Content-Type' => 'text/plain', 'Content-Length' => 13 ],
        'mmm',
        'Hello, World!'
    ],
    [   "/blah" => 404,
        [ 'Content-Type' => 'text/plain' ], # Plack::App::URLMap returns this
        '', ''
    ],
    [   "/mmm/blah" => 404,
        [ 'Content-Type' => 'text/plain', 'Content-Length' => 3 ],
        '', ''
    ],
];

plan tests => sum map 2 * ( @$_ - 3 ), @tests;

for my $t (@tests) {
    my ( $desc, $dir, $app, @urls ) = @$t;

    my $wf = Wallflower->new(
        application => $app,
        destination => $dir,
        url         => 'http://localhost/mmm'
    );

    for my $u (@urls) {
        my ( $url, $status, $headers, $file, $content ) = @$u;

        my $result = $wf->get($url);
        is_deeply(
            $result,
            [ $status, $headers, $file && Path::Tiny->new( $dir, $file ) ],
            "app ($desc) for $url"
        );

        if ( $status == 200 ) {
            my $file_content
                = do { local $/; local @ARGV = ( $result->[2] ); <> };
            is( $file_content, $content, "content ($desc) for $url" );
        }
        else {
            is( $result->[2], '', "no file ($desc) for $url" );
        }
    }
}
