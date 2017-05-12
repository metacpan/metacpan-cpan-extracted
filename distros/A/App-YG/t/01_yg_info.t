use strict;
use Test::More;

my $command = 'bin/yg';

ok 1;

if ($ENV{YG_ALL_TEST}) {
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
        "--parsar apache-common"
    );
    is $?, 512, 'invalid option';
    system(
        $^X, (map { "-I$_" } @INC),
        $command,
        "-q apache-common"
    );
    is $?, 512, 'invalid option';
}

done_testing;
