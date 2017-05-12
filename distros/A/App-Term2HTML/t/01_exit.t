use strict;
use warnings;
use Test::More;

use App::Term2HTML;

{
    my $command = 'script/term2html';

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
}

done_testing;
