use strict;
use warnings;
use Test::More;
use Path::Tiny ();
use List::Util qw( sum );
use Wallflower;

use Plack::Request;

# basic response builder
sub build_response {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $uri = $req->uri;
    return $uri->path eq '/nope'
      ? [ 404, [ 'Content-Type' => 'text/plain', 'Content-Length' => 0 ], '' ]
      : [
        200,
        [ 'Content-Type' => 'text/plain', 'Content-Length' => length($uri) ],
        [$uri]
      ];
}

# test data is an array ref containing:
# - quick description of the app
# - the app itself
# - a list of test url for the app
#   as [ url, status, headers, file, content ]
my @tests;

# some test urls
my @urls = (
    [
        '/' => 200,
        [ 'Content-Type' => 'text/plain', 'Content-Length' => 24 ],
        'index.html',
        'http://blah.example.com/'
    ],
    [
        '/clunk' => 200,
        [ 'Content-Type' => 'text/plain', 'Content-Length' => 29 ],
        'clunk', 'http://blah.example.com/clunk'
    ],
    [   '/nope' => 404,
        [ 'Content-Type' => 'text/plain', 'Content-Length' => 0 ],
        '', ''
    ],
);

# setup test data
push @tests, [ 'direct content', \&build_response, @urls ];

push @tests, [
    'delayed response',
    sub {
        my $res = build_response(shift);
        sub { shift->($res) }
    },
    @urls
];

push @tests, [
    'streaming',
    sub {
        my $res = build_response(shift);
        my $body = ref $res->[2] ? $res->[2][0] : $res->[2];
        sub {
            my $responder = shift;
            my $writer = $responder->( [ @{$res}[ 0, 1 ] ] );
            $writer->write( $body );
            $writer->close;
          }
    },
    @urls
];

plan tests => sum map 2 * ( @$_ - 2 ), @tests;

for my $t (@tests) {
    my ( $desc, $app, @urls ) = @$t;
    my $dir = Path::Tiny->tempdir;

    my $wf = Wallflower->new(
        application => $app,
        destination => $dir,
        url         => 'http://blah.example.com',
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
            is( $file_content, $content, "content ($desc) for $url [$status]" );
        }
        else {
            is( $result->[2], '', "no file ($desc) for $url [$status]" );
        }
    }
}

