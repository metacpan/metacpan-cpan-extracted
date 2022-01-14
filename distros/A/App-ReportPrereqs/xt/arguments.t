#!perl

use 5.006;
use strict;
use warnings;

use Capture::Tiny qw(capture);

use Test::More 0.88;

use lib qw(.);

require_ok('bin/report-prereqs') or BAIL_OUT();

note('invalid parameter');
{
    local @ARGV = ('--no-such-option');

    my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
    is( $result[0], 2, '_main() returns 2' );
    ok( scalar @result == 1, '... and nothing else' );
    is( $stdout, q{}, '... prints nothing to STDOUT' );
    like( $stderr, qr{\Qusage: arguments.t\E}, '... prints usage to STDERR' );
}

note('to many arguments');
{
    local @ARGV = qw(hello world);

    my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
    is( $result[0], 2, '_main() returns 2' );
    ok( scalar @result == 1, '... and nothing else' );
    is( $stdout, q{}, '... prints nothing to STDOUT' );
    like( $stderr, qr{\Qusage: arguments.t\E}, '... prints usage to STDERR' );
}

note('--meta and --cpanfile');
{
    local @ARGV = qw(--meta META.json --cpanfile cpanfile);

    my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
    is( $result[0], 2, '_main() returns 2' );
    ok( scalar @result == 1, '... and nothing else' );
    is( $stdout, q{}, '... prints nothing to STDOUT' );
    like( $stderr, qr{\Qusage: arguments.t\E}, '... prints usage to STDERR' );
}

note('--meta and url');
{
    local @ARGV = qw(--meta META.json http://example.com);

    my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
    is( $result[0], 2, '_main() returns 2' );
    ok( scalar @result == 1, '... and nothing else' );
    is( $stdout, q{}, '... prints nothing to STDOUT' );
    like( $stderr, qr{\Qusage: arguments.t\E}, '... prints usage to STDERR' );
}

note('--cpanfile and url');
{
    local @ARGV = qw(--cpanfile cpanfile http://example.com);

    my ( $stdout, $stderr, @result ) = capture { App::ReportPrereqs::_main() };
    is( $result[0], 2, '_main() returns 2' );
    ok( scalar @result == 1, '... and nothing else' );
    is( $stdout, q{}, '... prints nothing to STDOUT' );
    like( $stderr, qr{\Qusage: arguments.t\E}, '... prints usage to STDERR' );
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
