package Instrumented;
use strict;
use warnings;
use Config;
use Cwd qw(abs_path);
use ExtUtils::Manifest qw(maniread);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Test::More;
use Text::ParseWords qw(shellwords);

sub capture {
    my @cmd = @_;
    my $pid = open my $fh, '-|';
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        open STDERR, '>&', STDOUT or die $!;
        exec @cmd;
        die "exec $cmd[0]: $!";
    }
    local $/;
    my $out = <$fh> // '';
    close $fh;
    return ($?, $out);
}

sub run {
    my ($kind, $switch) = @_;
    plan skip_all => "set $switch=1 to run" unless $ENV{$switch};
    my @cc = shellwords($Config{cc});
    open my $probe, '-|', @cc, "-print-file-name=lib$kind.so" or die $!;
    chomp(my $runtime = <$probe> // '');
    close $probe;
    plan skip_all => "lib$kind not found" unless -f $runtime;

    my $src = dirname(dirname(dirname(abs_path(__FILE__))));
    my $tmp = tempdir("phs-$kind-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    for my $file (keys %{maniread("$src/MANIFEST")}) {
        make_path(dirname("$tmp/$file"));
        copy("$src/$file", "$tmp/$file") or die "copy $file: $!";
    }
    my $cwd = abs_path('.');
    chdir $tmp or die "chdir $tmp: $!";
    my %sanitizer = (asan => 'address', ubsan => 'undefined', tsan => 'thread');
    my $flags = "-fsanitize=$sanitizer{$kind}";
    $flags .= ' -fno-sanitize-recover=undefined' if $kind eq 'ubsan';
    my ($rc, $out) = capture($^X, 'Makefile.PL', "OPTIMIZE=-O1 -g $flags -fno-omit-frame-pointer",
                            "LDDLFLAGS=$Config{lddlflags} $flags");
    ($rc, $out) = capture($Config{make}, '-s') if $rc == 0;
    is $rc, 0, "$switch build succeeds" or diag $out;
    if ($rc == 0) {
        local $ENV{LD_PRELOAD} = join ' ', $runtime, grep { length } ($ENV{LD_PRELOAD} // '');
        local $ENV{ASAN_OPTIONS} = 'detect_leaks=0:halt_on_error=1';
        local $ENV{UBSAN_OPTIONS} = 'print_stacktrace=1:halt_on_error=1';
        local $ENV{TSAN_OPTIONS} = 'halt_on_error=1:second_deadlock_stack=1';
        for my $test (sort glob 't/*.t') {
            my ($status, $output) = capture($^X, '-Mblib', $test);
            is $status, 0, "$switch: $test" or diag $output;
        }
    }
    chdir $cwd or die "chdir $cwd: $!";
    done_testing;
}

1;
