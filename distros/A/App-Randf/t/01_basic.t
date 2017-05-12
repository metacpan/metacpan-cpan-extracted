use strict;
use warnings;
use Test::More;
use Capture::Tiny qw/capture/;

use App::Randf;

{
    my $str = "\n" x 100;
    open my $IN, '<', \$str;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::Randf->run(50);
    };
    close $IN;
    note length($stdout);
    ok 1;
}

{
    ok App::Randf::_show_usage('NOEXIT');
}

{
    my $command = 'script/randf';

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
