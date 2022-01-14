#!perl

use 5.006;
use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd            ();
use File::Basename ();
use File::Spec     ();

use Test::More 0.88;
use Test::MockModule 0.14;

use lib qw(.);
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), '../corpus/lib' );

require_ok('bin/report-prereqs') or BAIL_OUT();

note(q{download file from invalid url});
SKIP:
{
    my $res = {
        'success' => q{},
        'headers' => {
            'content-type'   => 'text/plain',
            'content-length' => 76,
        },
        'content' => "Could not connect to 'no.such.url:80': node name or service name not known\n",
        'url'     => 'http://no.such.url./cpanfile',
        'reason'  => 'Internal Exception',
        'status'  => 599,
    };

    my $module = Test::MockModule->new('HTTP::Tiny');
    $module->redefine( 'get', sub { return $res; } );

    local @ARGV = ('http://no.such.url/cpanfile');

    my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
    is( $result[0], 1, '_main() returns 1' );
    ok( scalar @result == 1, '... and nothing else' );
    is( $stdout, q{},             '... prints nothing to STDOUT' );
    is( $stderr, $res->{content}, '... prints the error message from HTTP::Tiny' );
}

note(q{download file from valid url});
SKIP:
{
    my $res = {
        'status'   => '200',
        'reason'   => 'OK',
        'success'  => 1,
        'protocol' => 'HTTP/1.1',
        'url'      => 'https://raw.githubusercontent.com/skirmess/App-ReportPrereqs/master/cpanfile',
        'content'  => <<'CONTENT',
requires 'Local::Alpha';
requires 'Local::Alpha::DoesNotExist';
requires 'Local::Beta';
requires 'Local::Beta::DoesNotExist';
CONTENT
        'headers' => {
            'source-age'                  => '0',
            'cache-control'               => 'max-age=300',
            'x-frame-options'             => 'deny',
            'access-control-allow-origin' => q{*},
            'x-served-by'                 => 'cache-hhn1550-HHN',
            'date'                        => 'Thu, 07 Jun 2018 20:15:24 GMT',
            'x-github-request-id'         => '747E:5754:48FEFA:4A566D:5B19925C',
            'strict-transport-security'   => 'max-age=31536000',
            'x-geo-block-list'            => q{},
            'vary'                        => 'Authorization,Accept-Encoding',
            'connection'                  => 'keep-alive',
            'accept-ranges'               => 'bytes',
            'content-length'              => '7840',
            'x-xss-protection'            => '1; mode=block',
            'expires'                     => 'Thu, 07 Jun 2018 20:20:24 GMT',
            'x-timer'                     => 'S1528402525.672062,VS0,VE96',
            'content-security-policy'     => 'default-src \'none\'; style-src \'unsafe-inline\'; sandbox',
            'x-cache'                     => 'MISS',
            'x-fastly-request-id'         => 'a46d6b434a76506ced7a5caf7ef0ff54e70b6569',
            'via'                         => '1.1 varnish',
            'content-type'                => 'text/plain; charset=utf-8',
            'x-cache-hits'                => '0',
            'etag'                        => '"b82620b2b61a7275fc1d0ad1bc9a405a00dba9c1"',
            'x-content-type-options'      => 'nosniff',
        },
    };

    my $module = Test::MockModule->new('HTTP::Tiny');
    $module->redefine( 'get', sub { return $res; } );

    local @ARGV = ('https://raw.githubusercontent.com/skirmess/App-ReportPrereqs/master/cpanfile');

    my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
    is( $result[0], undef, '_main() returns undef' );
    ok( scalar @result == 0, '... and nothing else' );

    my @expected = (
        q{Versions for all modules listed in https://raw.githubusercontent.com/skirmess/App-ReportPrereqs/master/cpanfile:},
        q{},
        q{=== Runtime Requires ===},
        q{},
        q{    Module                     Want        Have},
        q{    -------------------------- ---- -----------},
        q{    Local::Alpha                any        1.11},
        q{    Local::Alpha::DoesNotExist  any     missing},
        q{    Local::Beta                 any v2018.06.02},
        q{    Local::Beta::DoesNotExist   any     missing},
        q{},
        q{},
        q{*** WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ***},
        q{},
        q{The following REQUIRED prerequisites were not satisfied:},
        q{},
        q{Local::Alpha::DoesNotExist is not installed (any version required)},
        q{Local::Beta::DoesNotExist is not installed (any version required)},
    );
    is_deeply( [ split /\n/, $stdout ], [@expected], '... prints correct report to STDOUT' );

    is( $stderr, q{}, '... prints nothing to STDERR' );
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
