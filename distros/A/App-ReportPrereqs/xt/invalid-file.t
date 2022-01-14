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

require_ok('bin/report-prereqs') or BAIL_OUT();

SKIP:
{

    for my $i (
        [ 'cpanfile',  File::Spec->catdir( 'corpus', 'dist2' ), ],
        [ 'META.json', File::Spec->catdir( q{..},    'dist3' ), qw(--meta META.json), ],
        [ 'META.yml',  File::Spec->catdir( q{..},    'dist4' ), qw(--meta META.yml), ],
      )
    {

        my $filename = shift @{$i};
        note("invalid $filename");
        chdir shift @{$i} or skip "Test setup failed: Cannot chdir: $!";

        local @ARGV = @{$i};

        my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
        is( $result[0], 1, '_main() returns 1' );
        ok( scalar @result == 1, '... and nothing else' );
        is( $stdout, q{}, '... prints nothing to STDOUT' );
        ok( length($stderr), q{... prints an error to STDERR (error is from Module::CPANfile/CPAN::Meta, we don't test what the error is)} );
    }
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
