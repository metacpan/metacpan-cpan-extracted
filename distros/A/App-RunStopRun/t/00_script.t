use strict;
use warnings;
use Test::More;

use Capture::Tiny qw(capture);
use File::Spec::Functions qw(:ALL);

BEGIN { use_ok 'App::RunStopRun' }

my $script = catdir(
    catpath((splitpath(rel2abs(__FILE__)))[0, 1], ''), updir,
    'bin', 'run-stop-run'
);

my ($stdout, $stderr, $exit) = capture {
    system $^X, qw(-Ilib -c), $script;
};
is $exit >> 8, 0, 'script compiles';

($stdout, $stderr, $exit) = capture {
    system $^X, qw(-Ilib), $script, qw(-T), $^X, qw(-e), <<'    EOF';
    print STDERR "stderr\n";
    print STDOUT "stdout\n";
    EOF
};
is $exit >> 8, 0, 'script runs, without tty';
is $stdout, "stdout\n", 'stdout';
is $stderr, "stderr\n", 'stderr';

($stdout, $stderr, $exit) = capture {
    system $^X, qw(-Ilib), $script, qw(-t), $^X, qw(-e), <<'    EOF';
    print STDERR "stderr\n";
    print STDOUT "stdout\n";
    EOF
};
is $exit >> 8, 0, 'script runs, with tty';
is $stdout, "stdout\n", 'stdout';
is $stderr, "stderr\n", 'stderr';

SKIP: {
    ($stdout, $stderr, $exit) = capture {
        system $^X, qw(-Ilib), $script, qw(-v), $^X, qw(-e), <<'        EOF';
        kill(0   => $$) or die qq(Can't send signals to self\n);
        kill(INT => $$) or die qq(Signal not sent or ignored\n);
        sleep 2;
        EOF
    };
    # auto-reaped?
    skip q(parent didn't reap child) unless $stderr =~ /Reaped /;
    is $exit >> 8, 2, 'script exit value when child interrupted';
}

($stdout, $stderr, $exit) = capture {
    system $^X, qw(-Ilib), $script, $^X, qw(-e), <<'    EOF';
    kill(INT => getppid) or die qq(Signal not sent or ignored\n);
    sleep 2;
    EOF
};
is $exit & 127, 2, 'script reports signal when interrupted';

done_testing;
