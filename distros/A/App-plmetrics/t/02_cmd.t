use strict;
use Test::More;

my $command = 'script/plmetrics';

ok 1;

if ($ENV{AUTHOR_TEST} || ($ENV{CI} && $ENV{TRAVIS})) {
    system(
        $^X, (map { "-I$_" } @INC),
        $command,
        '--version'
    );
    is $?, 0, '--version';
}

done_testing;
