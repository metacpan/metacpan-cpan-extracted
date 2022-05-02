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

done_testing;
