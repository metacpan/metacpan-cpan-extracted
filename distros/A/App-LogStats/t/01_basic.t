use strict;
use warnings;
use Test::More 0.88;

my $command = 'bin/stats';

{
    # version
    system(
        $^X, (map { "-I$_" } @INC),
        $command,
        '--version'
    );
    is $?, 256, '--version';
    system(
        $^X, (map { "-I$_" } @INC),
        $command,
        '-v'
    );
    is $?, 256, '-v';

    # help
    system(
        $^X, (map { "-I$_" } @INC),
        $command,
        '--help'
    );
    is $?, 256, '--help';
    system(
        $^X, (map { "-I$_" } @INC),
        $command,
        '-h'
    );
    is $?, 256, '-h';

    # invalid option
    system(
        $^X, (map { "-I$_" } @INC),
        $command,
        "--hoge"
    );
    is $?, 512, 'invalid option';
    system(
        $^X, (map { "-I$_" } @INC),
        $command,
        "-q 1"
    );
    is $?, 512, 'invalid option';
}

done_testing;
