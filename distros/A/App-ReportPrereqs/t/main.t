#!perl

use 5.006;
use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(cwd);

use Test::More 0.88;

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
        like( $stderr, qr{.+\n\Qusage: main.t [--with-develop]\E}, '... prints usage to STDERR' );
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
