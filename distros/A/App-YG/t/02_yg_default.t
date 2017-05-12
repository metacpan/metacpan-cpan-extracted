use strict;
use Test::More;

my $command = 'bin/yg';

ok 1;

if ($ENV{YG_ALL_TEST}) {
    system(
        $^X, (map { "-I$_" } @INC),
        $command,
        'share/log'
    );

    is $?, 0, 'default';
}

done_testing;
