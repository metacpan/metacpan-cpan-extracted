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
        [ 'cpanfile',  File::Spec->catdir( 'corpus', 'dist5' ), ],
        [ 'META.json', File::Spec->catdir( q{..},    'dist6' ), qw(--meta), ],
        [ 'META.yml',  File::Spec->catdir( q{..},    'dist7' ), qw(--meta META.yml), ],
      )
    {
        my $filename = shift @{$i};

        note("4 modules in $filename (2 don't exist)");
        chdir shift @{$i} or skip "Test setup failed: Cannot chdir: $!";

        local @ARGV = @{$i};

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], undef, '_main() returns undef' );
        ok( scalar @result == 0, '... and nothing else' );

        my @expected = (
            "Versions for all modules listed in $filename:",
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
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
