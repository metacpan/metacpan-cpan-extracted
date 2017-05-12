use strict;
use warnings;
use Test::More;
use Capture::Tiny qw/ capture /;

use App::FromUnixtime;

no warnings 'redefine';
*App::FromUnixtime::RC = sub { +{} };

{
    open my $IN, '<', \<<'_INPUT_';
id          1
name        John
date        1419702037
_INPUT_
    local *STDIN = *$IN;
    my ($stdout, $strerr) = capture {
        App::FromUnixtime->run('--replace');
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/date\s+\([^\)]+\)/;
}

done_testing;
