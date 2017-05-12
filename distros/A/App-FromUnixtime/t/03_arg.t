use strict;
use warnings;
use Test::More;
use Capture::Tiny qw/ capture /;

use App::FromUnixtime;

no warnings 'redefine';
*App::FromUnixtime::RC = sub { +{} };

{
    my ($stdout, $strerr) = capture {
        App::FromUnixtime->run('1419702037');
    };
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/1419702037\([^\)]+\)/;
}

{
    my ($stdout, $strerr) = capture {
        App::FromUnixtime->run('1419702038', '1419702039');
    };
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/1419702038\([^\)]+\)/;
    like $stdout, qr/1419702039\([^\)]+\)/;
}

{
    my ($stdout, $strerr) = capture {
        App::FromUnixtime->run('1419702037', '--format' => '%Y');
    };
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/1419702037\(\d+\)/;
}

done_testing;
