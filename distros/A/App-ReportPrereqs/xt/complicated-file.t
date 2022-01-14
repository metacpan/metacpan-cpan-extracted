#!perl

use 5.006;
use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd            ();
use File::Basename ();
use File::Spec     ();

use Test::More 0.88;

use lib qw(.);
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), '../corpus/lib' );

require_ok('bin/report-prereqs') or BAIL_OUT();

SKIP:
{
    for my $i (
        [ 'cpanfile',  File::Spec->catdir( 'corpus', 'dist6' ), ],
        [ 'META.json', File::Spec->catdir( q{..},    'dist7' ), qw(--meta), ],
      )
    {
        my $filename = shift @{$i};

        note("complicated $filename file");

        chdir shift @{$i} or skip "Test setup failed: Cannot chdir: $!";

        {

            local @ARGV = @{$i};

            my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
            is( $result[0], undef, '_main() returns undef' );
            ok( scalar @result == 0, '... and nothing else' );

            my @expected = (
                "Versions for all modules listed in $filename:",
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
        }

        note(q{complicated file (with develop dependencies))});
        {
            local @ARGV = ( @{$i}, '--with-develop' );

            my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
            is( $result[0], undef, '_main() returns undef' );
            ok( scalar @result == 0, '... and nothing else' );

            my @expected = (
                "Versions for all modules listed in $filename:",
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
        }

        note('invalid feature');
        {
            local @ARGV = ( @{$i}, qw(--with-feature no-such-feature) );

            my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
            is( $result[0], 1, '_main() returns 1' );
            ok( scalar @result == 1, '... and nothing else' );
            is( $stdout, q{}, '... prints nothing to STDOUT' );
            ok( length($stderr), q{... prints an error to STDERR (error is from Module::CPANfile/CPAN::Meta, we don't test what the error is)} );
        }

        note(q{complicated file (with develop dependencies, with feature))});
        {
            local @ARGV = ( @{$i}, qw(--with-develop --with-feature omega) );

            my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
            is( $result[0], undef, '_main() returns undef' );
            ok( scalar @result == 0, '... and nothing else' );

            my @expected = (
                "Versions for all modules listed in $filename:",
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
        }
    }
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
