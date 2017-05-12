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
        App::FromUnixtime->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/date\s+1419702037\([^\)]+\)/;
}

{
    open my $IN, '<', \<<'_INPUT_';
id          1
name        John
created_on  1419692400
_INPUT_
    local *STDIN = *$IN;
    my ($stdout, $strerr) = capture {
        App::FromUnixtime->run('--format' => '%Y-%m-%d %H:%M:%S');
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/created_on\s+1419692400\(\d+-\d+-\d+ \d+:\d+:\d+\)/;
}

{
    open my $IN, '<', \<<'_INPUT_';
id          1
name        John
date        2147483648
_INPUT_
    local *STDIN = *$IN;
    my ($stdout, $strerr) = capture {
        App::FromUnixtime->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/date\s+2147483648[^\(]/;
}

{
    open my $IN, '<', \<<'_INPUT_';
id          1
name        John
created_on  1419692400
_INPUT_
    local *STDIN = *$IN;
    my ($stdout, $strerr) = capture {
        App::FromUnixtime->run('--start-bracket' => '[', '--end-bracket' => ']');
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/created_on\s+1419692400\[.+\]/;
}

{
    open my $IN, '<', \<<'_INPUT_';
id          1
name        John
value       1419692400
_INPUT_
    local *STDIN = *$IN;
    my ($stdout, $strerr) = capture {
        App::FromUnixtime->run('--re' => 'value');
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/value\s+1419692400\(.+\)/;
}

{
    open my $IN, '<', \<<'_INPUT_';
id          1
name        John
created_on  1419692400
_INPUT_
    local *STDIN = *$IN;
    my ($stdout, $strerr) = capture {
        App::FromUnixtime->run('--no-re' => 'created');
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/created_on\s+1419692400[^\(]/;
}

{
    open my $IN, '<', \<<'_INPUT_';
1419692400
_INPUT_
    local *STDIN = *$IN;
    my ($stdout, $strerr) = capture {
        App::FromUnixtime->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/1419692400\(.+\)/;
}

{
    no warnings 'redefine';
    *App::FromUnixtime::RC = sub { +{ re => 'value'} };
    open my $IN, '<', \<<'_INPUT_';
id          1
name        John
value       1419692400
_INPUT_
    local *STDIN = *$IN;
    my ($stdout, $strerr) = capture {
        App::FromUnixtime->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/value\s+1419692400\(.+\)/;
    *App::FromUnixtime::RC = sub { +{} };
}

{
    no warnings 'redefine';
    *App::FromUnixtime::RC = sub { +{ re => ['foobar', 'value'] } };
    open my $IN, '<', \<<'_INPUT_';
id          1
name        John
value       1419692400
_INPUT_
    local *STDIN = *$IN;
    my ($stdout, $strerr) = capture {
        App::FromUnixtime->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/value\s+1419692400\(.+\)/;
    *App::FromUnixtime::RC = sub { +{} };
}

{
    open my $IN, '<', \<<'_INPUT_';
id          1
foo_date2   1419692400
_INPUT_
    local *STDIN = *$IN;
    my ($stdout, $strerr) = capture {
        App::FromUnixtime->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/foo_date2\s+1419692400\(.+\)/;
}

{
    open my $IN, '<', \<<'_INPUT_';
id          1
foo_date2   419692400
_INPUT_
    local *STDIN = *$IN;
    my ($stdout, $strerr) = capture {
        App::FromUnixtime->run('--min-time' => 1000000000);
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/foo_date2\s+419692400[^\(]/;
}

{
    open my $IN, '<', \<<'_INPUT_';
id          1
expired_at  1419692400
_INPUT_
    local *STDIN = *$IN;
    my ($stdout, $strerr) = capture {
        App::FromUnixtime->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/expired_at\s+1419692400\(.+\)/;
}

done_testing;
