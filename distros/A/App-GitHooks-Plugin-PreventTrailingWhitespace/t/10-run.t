#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny;
use Test::Exception;
use Test::Git;
use Test::More;

use App::GitHooks::Test qw( ok_add_files ok_setup_repository );


## no critic (RegularExpressions::RequireExtendedFormatting)

# Require git.
has_git( '1.7.4.1' );

# List of tests to perform.
my $tests =
[
    {
        name     => 'Trailing tab at the end of a line.',
        files    =>
        {
            'test.pl' => "#!perl\n\nuse strict;\t\n1;\n",
        },
        expected => qr/x The file has no lines with trailing white space/,
    },
    {
        name     => 'Trailing space at the end of a line.',
        files    =>
        {
            'test.pl' => "#!perl\n\nuse strict; \n1;\n",
        },
        expected => qr/x The file has no lines with trailing white space/,
    },
    {
        name     => 'Empty line with spaces.',
        files    =>
        {
            'test.pl' => "#!perl\n\nuse strict;\n    \n1;\n",
        },
        expected => qr/x The file has no lines with trailing white space/,
    },
    {
        name     => 'File without trailing whitespace.',
        files    =>
        {
            'test.pl' => "#!perl\n\nuse strict;\n1;\n",
        },
        expected => qr/o The file has no lines with trailing white space/,
    },
];

# Bail out if Git isn't available.
has_git();
plan( tests => scalar( @$tests ) );

foreach my $test ( @$tests )
{
    subtest(
        $test->{'name'},
        sub
        {
            plan( tests => 4 );

            my $repository = ok_setup_repository(
                cleanup_test_repository => 1,
                config                  => $test->{'config'},
                hooks                   => [ 'pre-commit' ],
                plugins                 => [ 'App::GitHooks::Plugin::PreventTrailingWhitespace' ],
            );

            # Set up test files.
            ok_add_files(
                files      => $test->{'files'},
                repository => $repository,
            );

            # Try to commit.
            my $stderr;
            lives_ok(
                sub
                {
                    $stderr = Capture::Tiny::capture_stderr(
                        sub
                        {
                            $repository->run( 'commit', '-m', 'Test message.' );
                        }
                    );
                    note( $stderr );
                },
                'Commit the changes.',
            );

            like(
                $stderr,
                $test->{'expected'},
                "The output matches expected results.",
            );
        }
    );
}
