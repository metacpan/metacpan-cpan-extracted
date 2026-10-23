use strict;
use warnings;
use Test::Most;
use Capture::Tiny qw(capture);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use App::Actions::Process;

# Child programs are written to files rather than passed with -e: Win32 Perl
# does not round-trip "-e" code containing double quotes through system(), and
# mangles it into a different program.
sub write_program {
    my ($contents, %options) = @_;

    my $directory = $options{directory} || tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($directory, 'program.pl');

    open my $handle, '>', $path or die $!;
    binmode $handle;
    print {$handle} $contents;
    close $handle;

    return $path;
}

# Windows writes CRLF when output is redirected to a file.
sub useful_text {
    my ($text) = @_;
    return '' unless defined $text;
    $text =~ s/\r\n/\n/g;
    return $text;
}

is(App::Actions::Process::exit_code(0), 0, 'a zero status is success');
is(App::Actions::Process::exit_code(3 << 8), 3, 'an exit code is decoded');
is(App::Actions::Process::exit_code((15 << 8) | 9), 128 + 9,
    'a signal is reported as 128 + signal');
isnt(App::Actions::Process::exit_code(-1), 0,
    'a command that cannot be started is a failure');

# Windows command-line quoting.  These are the rules the C runtime uses to
# split a command line, so the quoted argument has to parse back to the
# original; Perl's own quoting skips any argument containing a double quote.
is(App::Actions::Process::quote_win32('plain'), 'plain',
    'an argument without spaces or quotes is left alone');
is(App::Actions::Process::quote_win32('two words'), '"two words"',
    'spaces force quotes');
is(App::Actions::Process::quote_win32(''), '""',
    'an empty argument is quoted');
is(App::Actions::Process::quote_win32('say "hi"'), '"say \"hi\""',
    'an embedded double quote is escaped');
is(App::Actions::Process::quote_win32('a\\b c'), '"a\\b c"',
    'a backslash away from a quote is kept');
is(App::Actions::Process::quote_win32('a\\"b'), '"a' . ('\\' x 3) . '"b"',
    'a backslash before a quote is doubled');
is(
    App::Actions::Process::quote_win32('trailing ' . '\\'),
    '"trailing ' . ('\\' x 2) . '"',
    'a trailing backslash is doubled so it cannot escape the closing quote',
);
is(App::Actions::Process::quote_win32('sh -c printf %s "$PATH"'),
    '"sh -c printf %s \"$PATH\""',
    'a shell command is quoted as one argument');

my $hello = write_program("print \"hello\\n\";\n");
my ($output, $status) = App::Actions::Process::capture([ $^X, $hello ]);
is($status, 0, 'capture reports success');
is($output, "hello\n", 'capture returns standard output');

my $both = write_program("print \"out\\n\";\nprint STDERR \"noise\\n\";\n");
($output, $status) = App::Actions::Process::capture(
    [ $^X, $both ],
    quiet_stderr => 1,
);
is($output, "out\n", 'quiet_stderr still captures standard output');
is($status, 0, 'quiet_stderr reports success');

# A caller that builds a message from a command's output wants the child's
# standard error in it too, in the order the child wrote it and without
# escaping to the caller's own streams.
my $both_streams = write_program(
    "\$| = 1;\nprint \"out\\n\";\nprint STDERR \"err\\n\";\n"
);
my ($merged_out, $merged_status);
my ($unexpected) = capture {
    ($merged_out, $merged_status) = App::Actions::Process::capture(
        [ $^X, $both_streams ],
        merge_stderr => 1,
    );
};
is($merged_status, 0, 'merge_stderr reports success');
is($merged_out, "out\nerr\n", 'merge_stderr captures both streams in the order written');
is($unexpected, '', 'the merged streams do not also reach the caller');

my $crlf = write_program("binmode STDOUT;\nprint \"a\\r\\nb\\r\\n\";\n");
($output, $status) = App::Actions::Process::capture([ $^X, $crlf ]);
is($output, "a\nb\n", 'CRLF output is normalised on every platform');

my $failing = write_program("exit 7;\n");
($output, $status) = App::Actions::Process::capture([ $^X, $failing ]);
is($status, 7, 'the exit code is reported');

# Arguments that need quoting have to arrive unchanged, on Windows as well as
# on Unix.  Win32 Perl splits them at their spaces otherwise.
my $echo_args = write_program("print join('|', \@ARGV), \"\\n\";\n");
($output, $status) = App::Actions::Process::capture(
    [ $^X, $echo_args, 'two words', 'say "hi"', 'a\\b c' ],
);
is($status, 0, 'a command with quoted arguments runs');
is($output, 'two words|say "hi"|a\\b c' . "\n",
    'arguments with spaces and quotes reach the command unchanged');

my $quiet = write_program("print \"quiet\\n\";\nexit 4;\n");
is(
    App::Actions::Process::run_quiet([ $^X, $quiet ]),
    4,
    'run_quiet discards the output and reports the status',
);

my $streamed = write_program("print \"streamed\\n\";\nexit 5;\n");
my $stream_status;
my ($stream_out) = capture {
    $stream_status = App::Actions::Process::stream([ $^X, $streamed ]);
};
is($stream_status, 5, 'stream reports the exit code');
is($stream_out, "streamed\n", 'stream passes the output through');

my (undef, $missing) = App::Actions::Process::capture(
    [ 'app-actions-no-such-command' ],
);
isnt($missing, 0, 'a missing command is reported');

# Paths with spaces are common on Windows and must reach the child intact.
my $spaced_dir = File::Spec->catdir(tempdir(CLEANUP => 1), 'with space');
make_path($spaced_dir);
my $spaced = write_program("print \"spaced\\n\";\n", directory => $spaced_dir);
my ($spaced_out, $spaced_status) = App::Actions::Process::capture([ $^X, $spaced ]);
is($spaced_status, 0, 'a script below a path with spaces runs');
is($spaced_out, "spaced\n", 'the output of a script below a path with spaces is captured');

# Capturing must not disturb an enclosing Capture::Tiny, and output buffered
# before the command has to be flushed first so that the order is preserved.
my $inner = write_program("print \"inner\\n\";\n");
my ($stdout, $stderr) = capture {
    print "before\n";
    my ($inner_out) = App::Actions::Process::capture([ $^X, $inner ]);
    is($inner_out, "inner\n", 'the command output is captured inside Capture::Tiny');
    print "after\n";
};

is($stdout, "before\nafter\n", 'the enclosing capture keeps its output in order');
is($stderr, '', 'standard error is left alone');

# Several commands can run together.  Their results keep the order of the
# commands even when a later one finishes first, and their output goes
# straight to the caller's streams.
my $marks = File::Spec->catfile(tempdir(CLEANUP => 1), 'marks.txt');
my $timed = write_program(<<'PERL');
use Time::HiRes qw(time sleep);
my ($marks, $name, $delay, $status) = @ARGV;
print "$name\n";
for my $phase ('start', 'end') {
    open my $log, '>>', $marks or die $!;
    printf {$log} "%s %s %.6f\n", $phase, $name, time;
    close $log;
    sleep $delay if $phase eq 'start';
}
exit $status;
PERL

my $codes;
my ($together) = capture {
    $codes = App::Actions::Process::run_parallel(
        [
            [ $^X, $timed, $marks, 'slow', 0.3, 0 ],
            [ $^X, $timed, $marks, 'fast', 0.05, 3 ],
        ],
        concurrency => 2,
    );
};

is_deeply($codes, [ 0, 3 ],
    'the exit codes come back in the order of the commands');
like($together, qr/^(?:slow|fast)\n/m, 'the commands write to the caller streams');

my %when;
open my $mark_handle, '<', $marks or die $!;
while (my $line = <$mark_handle>) {
    my ($phase, $name, $at) = split ' ', $line;
    $when{$name}{$phase} = $at;
}
close $mark_handle;

is(scalar keys %when, 2, 'both commands ran');

is_deeply(App::Actions::Process::run_parallel([]), [],
    'no commands means no results');

my $single = App::Actions::Process::run_parallel([ [ $^X, $failing ] ]);
is_deeply($single, [7], 'a single command still reports its exit code');

# Output can be kept away from the caller's streams, which is how a report is
# built without a command's noise ending up in it.
my $redirected;
my ($leaked) = capture {
    $redirected = App::Actions::Process::run_parallel(
        [
            [ $^X, $timed, $marks, 'quiet-one', 0.05, 0 ],
            [ $^X, $timed, $marks, 'quiet-two', 0.05, 4 ],
        ],
        concurrency => 2,
        stdout      => File::Spec->devnull,
        stderr      => File::Spec->devnull,
    );
};
is_deeply($redirected, [ 0, 4 ], 'redirected commands still report their status');
is($leaked, '', 'redirected output does not reach the caller streams');

SKIP: {
    skip 'commands run one at a time where fork() is not used', 3
        if $^O eq 'MSWin32';

    ok(
        $when{slow}{start} < $when{fast}{end}
            && $when{fast}{start} < $when{slow}{end},
        'the commands overlap instead of running one after another',
    );

    my $serial = App::Actions::Process::run_parallel(
        [
            [ $^X, $timed, $marks, 'first', 0.2, 0 ],
            [ $^X, $timed, $marks, 'second', 0.2, 0 ],
        ],
        concurrency => 1,
    );
    is_deeply($serial, [ 0, 0 ], 'one at a time still runs every command');

    my $broken;
    capture {
        $broken = App::Actions::Process::run_parallel(
            [ [ 'app-actions-no-such-command' ] ],
            concurrency => 2,
        );
    };
    isnt($broken->[0], 0,
        'a command that cannot be started is still a failure');
}

my $noise = write_program("print STDERR \"noise\\n\";\n");
my (undef, $passthrough) = capture {
    App::Actions::Process::capture([ $^X, $noise ]);
};
is(useful_text($passthrough), "noise\n", 'standard error is passed through by default');

# The default for --parallel: a machine that cannot say how many processors it
# has still runs one job at a time rather than none.
my $cores = App::Actions::Process::cpu_count();
like($cores, qr/\A[1-9][0-9]*\z/, 'the processor count is a positive integer');
ok($cores >= 1, 'the processor count is at least one');

done_testing;
