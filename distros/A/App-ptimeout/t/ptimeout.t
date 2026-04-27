use strict;
use warnings;

use Capture::Tiny qw(capture);
use Config;
use IPC::Open3;
use Symbol qw(gensym);
use Test::Differences;
use Test::More;

my @perl = (
    $Config{perlpath},
    (map { ('-I', $_) } @INC),
    '-MApp::ptimeout',
    '-e',
    'App::ptimeout::_run(@ARGV)',
);

sub _run_with_stdin {
    my(%args) = @_;

    my $stderr = gensym;
    my $pid = open3(my $stdin, my $stdout, $stderr, @{$args{command}});

    if(exists($args{input})) {
        print {$stdin} $args{input};
    } elsif($args{wait_before_close}) {
        sleep $args{wait_before_close};
    }
    close $stdin;

    my $stdout_text = do { local $/; <$stdout> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid($pid, 0);

    return ($stdout_text, $stderr_text, $? >> 8);
}

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

($stdout, $stderr, $status) = _run_with_stdin(
    command => [
        @perl,
        1,
        $Config{perlpath},
        '-e',
        'my $line = <STDIN>; print "got input\n" if defined $line;',
    ],
    wait_before_close => 2,
);
eq_or_diff(
    [$status, $stderr, $stdout],
    [124,     "timed out\n", ""],
    "interactive programs time out while waiting for input"
);

($stdout, $stderr, $status) = _run_with_stdin(
    command => [
        @perl,
        5,
        $Config{perlpath},
        '-e',
        'my $line = <STDIN>; print "got input\n" if defined $line;',
    ],
    input => "\n",
);
eq_or_diff(
    [$status, $stderr, $stdout],
    [0,       '',      "got input\n"],
    "interactive programs exit normally once input arrives"
);

done_testing;
