#!/usr/bin/env perl
# execute(): run a shell command, returning exit code, stdout, stderr, or all.
#
# execute() takes a shell command line, so this test has to build one, which
# the rest of the suite never does.  Each command runs this perl ($^X) with a
# double-quoted -e program, which both sh and cmd.exe read the same way: no
# single quotes (cmd.exe does not treat them as quotes), no "$" inside the
# program (sh would interpolate it), and a backslash only before a letter,
# which sh leaves alone inside double quotes.
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Capture::Tiny 'capture';
use Cn::Util;

sub perl_cmd {
	my ($program) = @_;
	return qq{"$^X" -e "$program"};
}

is( execute(perl_cmd('exit 0')), 0, 'exit code of a passing command' );
is( execute(perl_cmd('print qq{hello}'), 'stdout'), 'hello', 'stdout is captured' );
is( execute(perl_cmd('print STDERR qq{oops}'), 'stderr'), 'oops', 'stderr is captured' );
SKIP: {
	# The child writes "\r\n" through a text-mode STDOUT on Windows, and chomp
	# removes only the "\n".
	skip "a newline is \"\\r\\n\" on $^O", 1 if $^O eq 'MSWin32';
	is( execute(perl_cmd('print qq{hello\n}'), 'stdout'), 'hello', 'stdout is chomped' );
}

my $all = execute(perl_cmd('print qq{out}; print STDERR qq{err}'), 'all');
is( ref $all, 'HASH', 'return => all yields a hashref' );
is( $all->{stdout}, 'out', 'all: stdout field' );
is( $all->{stderr}, 'err', 'all: stderr field' );
is( $all->{exit},   0,     'all: exit field' );

# A failing command with $die disabled returns the raw wait-status ($?),
# which for exit(1) is 256 (1 << 8).
my $code;
capture { $code = execute(perl_cmd('exit 1'), 'exit', 0) };
is( $code, 256, 'non-zero command with die disabled returns raw wait status' );

# $die defaults to 1: a failing command is fatal.
throws_ok { capture { execute(perl_cmd('exit 1')) } } qr/failed/,
	'failing command dies by default';

# Invalid $return value is rejected up front.
throws_ok { execute(perl_cmd('exit 0'), 'nonsense') }
	qr/only accepts/, 'rejects an unknown return mode';
# 0.023 matched with ^...$, so "exit\n" ran the command before dying.
throws_ok { execute(perl_cmd('exit 0'), "exit\n") }
	qr/only accepts/, 'rejects a return mode with a trailing newline';

# $die is a boolean: 0.023 compared it with == 1, so 'yes' died with
# "isn't numeric" and 2 meant "do not die".
throws_ok { capture { execute(perl_cmd('exit 1'), 'exit', 'yes') } } qr/failed/,
	'a true non-numeric $die is fatal';
throws_ok { capture { execute(perl_cmd('exit 1'), 'exit', 2) } } qr/failed/,
	'$die => 2 is fatal';

# --- fd 0 during and after the command ---
# STDIN is pointed at a pipe holding three lines, and is put back on the test's
# own standard input at the end.  Three short lines fit in any pipe buffer, so
# writing them all before reading cannot block.
open my $orig_stdin, '<&', \*STDIN or die "cannot save STDIN: $!";
pipe my $r, my $w or die "pipe: $!";
print {$w} "a\nb\nc\n";
close $w;
open STDIN, '<&', $r or die "cannot point STDIN at the pipe: $!";
close $r;

is( scalar <STDIN>, "a\n", 'first line read before execute' );
is( execute(perl_cmd('print defined(<STDIN>) ? qq{data} : qq{EOF}'), 'stdout'), 'EOF',
	'the command reads end-of-file, not the caller\'s input' );
# perl read all three lines into STDIN's buffer with the first.  0.023 put the
# null device on fd 0, and the flush before system()'s fork seeks fd 0 and
# discards the buffer when the seek succeeds, so "b" and "c" were lost.
is( scalar <STDIN>, "b\n", 'input perl had buffered survives execute' );
{
	no warnings 'redefine';
	local *Capture::Tiny::capture = sub { die "capture failed\n" };
	throws_ok { execute(perl_cmd('exit 0')) } qr/capture failed/,
		'an error from capture propagates';
}
is( scalar <STDIN>, "c\n", 'STDIN is restored when capture dies' );

SKIP: {
	require POSIX;
	close STDIN;
	# A module whose file is still held open (5.10.1 keeps a required file
	# open after __END__) can sit on fd 0 once STDIN is closed.
	skip 'fd 0 is in use with STDIN closed', 2 if defined POSIX::dup(0);
	is( execute(perl_cmd('exit 0')), 0, 'runs with STDIN closed' );
	ok( !defined POSIX::dup(0), 'fd 0 is closed again afterwards' );
}
open STDIN, '<&', $orig_stdin or die "cannot restore STDIN: $!";

done_testing;
