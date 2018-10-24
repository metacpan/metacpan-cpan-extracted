#!perl

use 5.006;
use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(cwd);

use Test::More 0.88;
use Test::MockModule;

use lib qw(.);

use FindBin qw($RealBin);
use lib "$RealBin/../corpus/lib";

main();

sub main {
    require_ok('bin/report-prereqs') or BAIL_OUT();

    my $basedir = cwd();

    note('invalid parameter');
    {
        local @ARGV = ('--no-such-option');

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], 2, '_main() returns 2' );
        ok( scalar @result == 1, '... and nothing else' );
        is( $stdout, q{}, '... prints nothing to STDOUT' );
        like( $stderr, qr{.+\n\Qusage: main.t [--with-{develop,feature=id}] [URL]\E$}, '... prints usage to STDERR' );
    }

    note('to many arguments');
    {
        local @ARGV = qw(hello world);

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], 2, '_main() returns 2' );
        ok( scalar @result == 1, '... and nothing else' );
        is( $stdout, q{}, '... prints nothing to STDOUT' );
        like( $stderr, qr{^\Qusage: main.t [--with-{develop,feature=id}] [URL]\E$}, '... prints usage to STDERR' );
    }

    note('corpus/dist1: no cpanfile');
    {
        _chdir('corpus/dist1');

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], 1, '_main() returns 1' );
        ok( scalar @result == 1, '... and nothing else' );
        is( $stdout, q{}, '... prints nothing to STDOUT' );
        ok( length($stderr), q{... prints an error to STDERR (error is from Module::CPANfile, we don't test what the error is)} );

        _chdir($basedir);
    }

    note('corpus/dist2: invalid cpanfile');
    {
        _chdir('corpus/dist2');

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], 1, '_main() returns 1' );
        ok( scalar @result == 1, '... and nothing else' );
        is( $stdout, q{}, '... prints nothing to STDOUT' );
        ok( length($stderr), q{... prints an error to STDERR (error is from Module::CPANfile, we don't test what the error is)} );

        _chdir($basedir);
    }

    note('corpus/dist3: only Local::Alpha in cpanfile');
    {
        _chdir('corpus/dist3');

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], undef, '_main() returns undef' );
        ok( scalar @result == 0, '... and nothing else' );

        my @expected = (
            q{Versions for all modules listed in cpanfile:},
            q{},
            q{=== Runtime Requires ===},
            q{},
            q{    Module       Want Have},
            q{    ------------ ---- ----},
            q{    Local::Alpha  any 1.11},
        );
        is_deeply( [ split /\n/, $stdout ], [@expected], '... prints correct report to STDOUT' );

        is( $stderr, q{}, '... prints nothing to STDERR' );

        _chdir($basedir);
    }

    note('corpus/dist4: only Local::Alpha::DoesNotExist in cpanfile');
    {
        _chdir('corpus/dist4');

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], undef, '_main() returns undef' );
        ok( scalar @result == 0, '... and nothing else' );

        my @expected = (
            q{Versions for all modules listed in cpanfile:},
            q{},
            q{=== Runtime Requires ===},
            q{},
            q{    Module                     Want    Have},
            q{    -------------------------- ---- -------},
            q{    Local::Alpha::DoesNotExist  any missing},
            q{},
            q{},
            q{*** WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ***},
            q{},
            q{The following REQUIRED prerequisites were not satisfied:},
            q{},
            q{Local::Alpha::DoesNotExist is not installed (any version required)},
        );
        is_deeply( [ split /\n/, $stdout ], [@expected], '... prints correct report to STDOUT' );

        is( $stderr, q{}, '... prints nothing to STDERR' );

        _chdir($basedir);
    }

    note(q{corpus/dist5: 4 modules in cpanfile (2 don't exist)});
    {
        _chdir('corpus/dist5');

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], undef, '_main() returns undef' );
        ok( scalar @result == 0, '... and nothing else' );

        my @expected = (
            q{Versions for all modules listed in cpanfile:},
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

        _chdir($basedir);
    }

    note(q{corpus/dist6: complicated file)});
    {
        _chdir('corpus/dist6');

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], undef, '_main() returns undef' );
        ok( scalar @result == 0, '... and nothing else' );

        my @expected = (
            q{Versions for all modules listed in cpanfile:},
            q{},
            q{=== Configure Requires ===},
            q{},
            q{    Module                    Want    Have},
            q{    ------------------------- ---- -------},
            q{    Local::Zeta                any   6.6.6},
            q{    Local::Zeta::DoesNotExist  any missing},
            q{},
            q{=== Build Requires ===},
            q{},
            q{    Module                       Want    Have},
            q{    ---------------------------- ---- -------},
            q{    Local::Epsilon                any     5.5},
            q{    Local::Epsilon::DoesNotExist  any missing},
            q{},
            q{=== Test Requires ===},
            q{},
            q{    Module                   Want     Have},
            q{    ------------------------ ---- --------},
            q{    Local::Eta                any 7.000007},
            q{    Local::Eta::DoesNotExist  any  missing},
            q{},
            q{=== Runtime Requires ===},
            q{},
            q{    Module                     Want    Have},
            q{    -------------------------- ---- -------},
            q{    Local::Alpha                any    1.11},
            q{    Local::Alpha::DoesNotExist  any missing},
            q{},
            q{=== Runtime Recommends ===},
            q{},
            q{    Module                    Want        Have},
            q{    ------------------------- ---- -----------},
            q{    Local::Beta               1.12 v2018.06.02},
            q{    Local::Beta::DoesNotExist  any     missing},
            q{},
            q{=== Runtime Suggests ===},
            q{},
            q{    Module                     Want    Have},
            q{    -------------------------- ---- -------},
            q{    Local::Gamma                any   0.003},
            q{    Local::Gamma::DoesNotExist  any missing},
            q{},
            q{=== Runtime Conflicts ===},
            q{},
            q{    Module                     Want    Have},
            q{    -------------------------- ---- -------},
            q{    Local::Delta                any      v4},
            q{    Local::Delta::DoesNotExist  any missing},
            q{},
            q{},
            q{*** WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ***},
            q{},
            q{The following REQUIRED prerequisites were not satisfied:},
            q{},
            q{Local::Zeta::DoesNotExist is not installed (any version required)},
            q{Local::Epsilon::DoesNotExist is not installed (any version required)},
            q{Local::Eta::DoesNotExist is not installed (any version required)},
            q{Local::Alpha::DoesNotExist is not installed (any version required)},
        );
        is_deeply( [ split /\n/, $stdout ], [@expected], '... prints correct report to STDOUT' );

        is( $stderr, q{}, '... prints nothing to STDERR' );

        _chdir($basedir);
    }

    note(q{corpus/dist6: complicated file (with develop dependencies))});
    {
        local @ARGV = ('--with-develop');

        _chdir('corpus/dist6');

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], undef, '_main() returns undef' );
        ok( scalar @result == 0, '... and nothing else' );

        my @expected = (
            q{Versions for all modules listed in cpanfile:},
            q{},
            q{=== Configure Requires ===},
            q{},
            q{    Module                    Want    Have},
            q{    ------------------------- ---- -------},
            q{    Local::Zeta                any   6.6.6},
            q{    Local::Zeta::DoesNotExist  any missing},
            q{},
            q{=== Build Requires ===},
            q{},
            q{    Module                       Want    Have},
            q{    ---------------------------- ---- -------},
            q{    Local::Epsilon                any     5.5},
            q{    Local::Epsilon::DoesNotExist  any missing},
            q{},
            q{=== Test Requires ===},
            q{},
            q{    Module                   Want     Have},
            q{    ------------------------ ---- --------},
            q{    Local::Eta                any 7.000007},
            q{    Local::Eta::DoesNotExist  any  missing},
            q{},
            q{=== Runtime Requires ===},
            q{},
            q{    Module                     Want    Have},
            q{    -------------------------- ---- -------},
            q{    Local::Alpha                any    1.11},
            q{    Local::Alpha::DoesNotExist  any missing},
            q{},
            q{=== Runtime Recommends ===},
            q{},
            q{    Module                    Want        Have},
            q{    ------------------------- ---- -----------},
            q{    Local::Beta               1.12 v2018.06.02},
            q{    Local::Beta::DoesNotExist  any     missing},
            q{},
            q{=== Runtime Suggests ===},
            q{},
            q{    Module                     Want    Have},
            q{    -------------------------- ---- -------},
            q{    Local::Gamma                any   0.003},
            q{    Local::Gamma::DoesNotExist  any missing},
            q{},
            q{=== Runtime Conflicts ===},
            q{},
            q{    Module                     Want    Have},
            q{    -------------------------- ---- -------},
            q{    Local::Delta                any      v4},
            q{    Local::Delta::DoesNotExist  any missing},
            q{},
            q{=== Develop Requires ===},
            q{},
            q{    Module                     Want    Have},
            q{    -------------------------- ---- -------},
            q{    Local::Theta                any    0.88},
            q{    Local::Theta::DoesNotExist  any missing},
            q{},
            q{},
            q{*** WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ***},
            q{},
            q{The following REQUIRED prerequisites were not satisfied:},
            q{},
            q{Local::Zeta::DoesNotExist is not installed (any version required)},
            q{Local::Epsilon::DoesNotExist is not installed (any version required)},
            q{Local::Eta::DoesNotExist is not installed (any version required)},
            q{Local::Alpha::DoesNotExist is not installed (any version required)},
            q{Local::Theta::DoesNotExist is not installed (any version required)},
        );
        is_deeply( [ split /\n/, $stdout ], [@expected], '... prints correct report to STDOUT' );

        is( $stderr, q{}, '... prints nothing to STDERR' );

        _chdir($basedir);
    }

    note('corpus/dist6: invalid feature');
    {
        local @ARGV = qw(--with-feature no-such-feature);

        _chdir('corpus/dist6');

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], 1, '_main() returns 1' );
        ok( scalar @result == 1, '... and nothing else' );
        is( $stdout, q{}, '... prints nothing to STDOUT' );
        ok( length($stderr), q{... prints an error to STDERR (error is from Module::CPANfile, we don't test what the error is)} );

        _chdir($basedir);
    }

    note(q{corpus/dist6: complicated file (with develop dependencies, with feature))});
    {
        local @ARGV = qw(--with-develop --with-feature omega);

        _chdir('corpus/dist6');

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], undef, '_main() returns undef' );
        ok( scalar @result == 0, '... and nothing else' );

        my @expected = (
            q{Versions for all modules listed in cpanfile:},
            q{},
            q{=== Configure Requires ===},
            q{},
            q{    Module                    Want    Have},
            q{    ------------------------- ---- -------},
            q{    Local::Zeta                any   6.6.6},
            q{    Local::Zeta::DoesNotExist  any missing},
            q{},
            q{=== Build Requires ===},
            q{},
            q{    Module                       Want    Have},
            q{    ---------------------------- ---- -------},
            q{    Local::Epsilon                any     5.5},
            q{    Local::Epsilon::DoesNotExist  any missing},
            q{    Local::Psi::DoesNotExist      any missing},
            q{},
            q{=== Test Requires ===},
            q{},
            q{    Module                   Want     Have},
            q{    ------------------------ ---- --------},
            q{    Local::Chi::DoesNotExist  any  missing},
            q{    Local::Eta                any 7.000007},
            q{    Local::Eta::DoesNotExist  any  missing},
            q{},
            q{=== Runtime Requires ===},
            q{},
            q{    Module                     Want    Have},
            q{    -------------------------- ---- -------},
            q{    Local::Alpha                any    1.11},
            q{    Local::Alpha::DoesNotExist  any missing},
            q{},
            q{=== Runtime Recommends ===},
            q{},
            q{    Module                    Want        Have},
            q{    ------------------------- ---- -----------},
            q{    Local::Beta               1.12 v2018.06.02},
            q{    Local::Beta::DoesNotExist  any     missing},
            q{},
            q{=== Runtime Suggests ===},
            q{},
            q{    Module                     Want    Have},
            q{    -------------------------- ---- -------},
            q{    Local::Gamma                any   0.003},
            q{    Local::Gamma::DoesNotExist  any missing},
            q{},
            q{=== Runtime Conflicts ===},
            q{},
            q{    Module                     Want    Have},
            q{    -------------------------- ---- -------},
            q{    Local::Delta                any      v4},
            q{    Local::Delta::DoesNotExist  any missing},
            q{},
            q{=== Develop Requires ===},
            q{},
            q{    Module                     Want    Have},
            q{    -------------------------- ---- -------},
            q{    Local::Omega::DoesNotExist  any missing},
            q{    Local::Theta                any    0.88},
            q{    Local::Theta::DoesNotExist  any missing},
            q{},
            q{},
            q{*** WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ***},
            q{},
            q{The following REQUIRED prerequisites were not satisfied:},
            q{},
            q{Local::Zeta::DoesNotExist is not installed (any version required)},
            q{Local::Epsilon::DoesNotExist is not installed (any version required)},
            q{Local::Psi::DoesNotExist is not installed (any version required)},
            q{Local::Chi::DoesNotExist is not installed (any version required)},
            q{Local::Eta::DoesNotExist is not installed (any version required)},
            q{Local::Alpha::DoesNotExist is not installed (any version required)},
            q{Local::Omega::DoesNotExist is not installed (any version required)},
            q{Local::Theta::DoesNotExist is not installed (any version required)},
        );
        is_deeply( [ split /\n/, $stdout ], [@expected], '... prints correct report to STDOUT' );

        is( $stderr, q{}, '... prints nothing to STDERR' );

        _chdir($basedir);
    }

    note('corpus/dist7: only Local::Omega in cpanfile');
    {
        _chdir('corpus/dist7');

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], undef, '_main() returns undef' );
        ok( scalar @result == 0, '... and nothing else' );

        my @expected = (
            q{Versions for all modules listed in cpanfile:},
            q{},
            q{=== Runtime Requires ===},
            q{},
            q{    Module       Want  Have},
            q{    ------------ ---- -----},
            q{    Local::Omega  any undef},
            q{},
            q{},
            q{*** WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ***},
            q{},
            q{The following REQUIRED prerequisites were not satisfied:},
            q{},
            q{Local::Omega version unknown (any version required)},
        );
        is_deeply( [ split /\n/, $stdout ], [@expected], '... prints correct report to STDOUT' );

        is( $stderr, q{}, '... prints nothing to STDERR' );

        _chdir($basedir);
    }

    note('corpus/dist8: only Local::Psi in cpanfile');
    {
        _chdir('corpus/dist8');

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], undef, '_main() returns undef' );
        ok( scalar @result == 0, '... and nothing else' );

        my @expected = (
            q{Versions for all modules listed in cpanfile:},
            q{},
            q{=== Runtime Requires ===},
            q{},
            q{    Module     Want                  Have},
            q{    ---------- ---- ---------------------},
            q{    Local::Psi  any this_is_not_a_version},
            q{},
            q{},
            q{*** WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ***},
            q{},
            q{The following REQUIRED prerequisites were not satisfied:},
            q{},
            q{Local::Psi version 'this_is_not_a_version' cannot be parsed (any version required)},
        );
        is_deeply( [ split /\n/, $stdout ], [@expected], '... prints correct report to STDOUT' );

        is( $stderr, q{}, '... prints nothing to STDERR' );

        _chdir($basedir);
    }

    note('corpus/dist9: Local::Alpha with version mismatch in cpanfile');
    {
        _chdir('corpus/dist9');

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], undef, '_main() returns undef' );
        ok( scalar @result == 0, '... and nothing else' );

        my @expected = (
            q{Versions for all modules listed in cpanfile:},
            q{},
            q{=== Runtime Requires ===},
            q{},
            q{    Module       Want Have},
            q{    ------------ ---- ----},
            q{    Local::Alpha 1.12 1.11},
            q{},
            q{},
            q{*** WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ***},
            q{},
            q{The following REQUIRED prerequisites were not satisfied:},
            q{},
            q{Local::Alpha version '1.11' is not in required range '1.12'},
        );
        is_deeply( [ split /\n/, $stdout ], [@expected], '... prints correct report to STDOUT' );

        is( $stderr, q{}, '... prints nothing to STDERR' );

        _chdir($basedir);
    }

    note(q{download file from invalid url});
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
        $module->mock( 'get', sub { return $res; } );

        local @ARGV = ('http://no.such.url/cpanfile');

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], 1, '_main() returns 1' );
        ok( scalar @result == 1, '... and nothing else' );
        is( $stdout, q{},             '... prints nothing to STDOUT' );
        is( $stderr, $res->{content}, '... prints the error message from HTTP::Tiny' );

        _chdir($basedir);
    }

    note(q{download file from valid url});
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
        $module->mock( 'get', sub { return $res; } );

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

        _chdir($basedir);
    }

    #
    done_testing();

    exit 0;
}

sub _chdir {
    my ($dir) = @_;

    my $rc = chdir $dir;
    BAIL_OUT("chdir $dir: $!") if !$rc;
    return $rc;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
