#!/usr/bin/env perl
# Re-run the test suite under AddressSanitizer.
#
# LD_PRELOAD'ing libasan into an *uninstrumented* perl only gets you the
# malloc interceptors - heap overflows and use-after-free. Stack-buffer
# overflows, use-after-scope and globals need compiler-emitted redzones,
# so a real stack overflow in the decoder sat undetected under the
# preload-only version of this test. Build a second, instrumented copy
# and run against that; fall back to preload-only (loudly) if that build
# can't be produced.
#
# Skipped unless RELEASE_TESTING=1 and a usable libasan is found.

use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec;
use Cwd qw(getcwd abs_path);

plan skip_all => 'set RELEASE_TESTING=1 to run ASAN tests'
    unless $ENV{RELEASE_TESTING};

# Locate libasan.so via the host C compiler.
my $cc = $ENV{CC} // 'cc';
chomp(my $libasan = `$cc -print-file-name=libasan.so 2>/dev/null`);
plan skip_all => 'no usable libasan.so on this host'
    unless $libasan && -f $libasan;

my $perl = $^X;
$perl = $1 if $perl =~ m{^(.+plenv/versions/[^/]+/bin/perl[^/]*)$};

# Resolve any plenv shim to the underlying perl, since LD_PRELOAD doesn't
# survive an exec to another perl.
chomp(my $real = `$perl -e 'print \$^X'`);
$perl = $real if -x $real;

my $root = getcwd();

# --- build an instrumented copy ---------------------------------------
my $asan_dir = File::Temp->newdir('che-asan-XXXXXX', TMPDIR => 1);
my $instrumented;
{
    my @sources = (glob('*.c'), glob('*.h'), glob('*.xs'), 'Makefile.PL');
    my $ok = 1;
    for my $f (@sources, 'lib', 't') {
        $ok &&= (system('cp', '-r', $f, "$asan_dir/") == 0);
    }
    if ($ok) {
        my $flags = '-g -O0 -fsanitize=address -fno-omit-frame-pointer';
        my $build = "cd '$asan_dir' && "
                  . "'$perl' Makefile.PL OPTIMIZE='$flags' "
                  . "LDDLFLAGS='-shared -fsanitize=address' >/dev/null 2>&1 "
                  . "&& make >/dev/null 2>&1";
        $ok = (system($build) == 0)
            && -f "$asan_dir/blib/arch/auto/ClickHouse/Encoder/Encoder.so";
    }
    $instrumented = $ok;
}

if ($instrumented) {
    diag('running against an -fsanitize=address instrumented build');
} else {
    diag('WARNING: could not produce an instrumented build; falling back '
       . 'to LD_PRELOAD only. Stack-buffer overflows and use-after-scope '
       . 'will NOT be detected in this mode.');
}

my $test_root = $instrumented ? "$asan_dir" : $root;
my @tests = sort glob("$test_root/t/*.t");
plan tests => scalar @tests;

for my $t (@tests) {
    my $name = $t;
    $name =~ s{^\Q$test_root\E/}{};
    # halt_on_error keeps the first report as the process exit status;
    # detect_leaks is off because perl's interpreter teardown is noisy.
    my $cmd = "cd '$test_root' && "
            . "LD_PRELOAD='$libasan' "
            . "ASAN_OPTIONS='detect_leaks=0:abort_on_error=0:halt_on_error=1' "
            . "'$perl' -Mblib '$name' 2>&1";
    my $output = `$cmd`;
    my $rc     = $? >> 8;
    if ($rc != 0) {
        diag("ASAN output for $name:\n$output");
    }
    is($rc, 0, "$name passes under ASAN");
}
