use strict;
use warnings;

use Capture::Tiny qw(capture);
use Config;
use Test::Differences;
use Test::More;

my @perl = (
    $Config{perlpath},
    (map { ('-I', $_) } @INC),
    '-MApp::ptimeout',
    '-e',
    'App::ptimeout::_run(@ARGV)',
);

my($stdout, $stderr, $status) = capture(sub {
    system(
        @perl,
        20,
        q{
            sh -c "
                sh -c 'echo starting; sleep 1; echo slept'&
                wait
            "
        }
    ) >> 8;
});
eq_or_diff(
    [$status, $stderr, $stdout],
    [0,       '',      "starting\nslept\n"],
    "correct status and output when there's no timeout"
);

($stdout, $stderr, $status) = capture(sub {
    my $status = system(
        @perl,
        1,
        q{
            sh -c "
                sh -c 'echo starting; sleep 10; echo slept'&
                wait
            "
        }
    ) >> 8;
    # keep capturing output until the sub-process would have finished
    # were it not killed
    sleep 15;
    $status;
});
eq_or_diff(
    [$status, $stderr,       $stdout],
    [124,     "timed out\n", "starting\n"],
    "correct status and output when there's a timeout"
);

($stdout, $stderr, $status) = capture(sub {
    system(
        @perl,
        20,
        q{
            sh -c "echo starting;exit 3"
        }
    ) >> 8;
});
eq_or_diff(
    [$status, $stderr, $stdout],
    [3,       '',      "starting\n"],
    "correct status and output when there's a funky exit status and no timeout"
);

done_testing;
