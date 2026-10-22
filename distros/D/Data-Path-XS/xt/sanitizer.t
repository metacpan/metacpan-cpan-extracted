use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(getcwd);

# Build a clean copy of the dist with ASan+UBSan and run the t/ tests.
# Skipped unless RELEASE_TESTING=1 (sanitizer build is slow).

plan skip_all => 'set RELEASE_TESTING=1 to enable'
    unless $ENV{RELEASE_TESTING};

# Need a working C compiler that supports -fsanitize=...
my $cc = $Config{cc} || 'cc';
my $cc_check = `$cc -x c -fsanitize=address,undefined -E - </dev/null 2>&1`;
plan skip_all => "$cc lacks -fsanitize=address,undefined support"
    if $? != 0;

# Need libasan/libubsan to LD_PRELOAD into the test perl.
my $asan_lib  = `gcc -print-file-name=libasan.so 2>/dev/null`;  chomp $asan_lib;
my $ubsan_lib = `gcc -print-file-name=libubsan.so 2>/dev/null`; chomp $ubsan_lib;
plan skip_all => 'libasan.so / libubsan.so not located'
    unless -f $asan_lib && -f $ubsan_lib;

my $cwd = getcwd;
END { chdir $cwd if defined $cwd }
my $tmp = tempdir(CLEANUP => 1);
system('cp', '-r', "$cwd/lib", "$cwd/XS.xs", "$cwd/Makefile.PL", "$tmp/") == 0
    or die "cp failed ($?)";
chdir $tmp or die "chdir $tmp: $!";

sub capture {
    my $pid = open my $pipe, '-|';
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        open STDERR, '>&', STDOUT or die "redirect stderr: $!";
        exec @_;
        die "exec: $!";
    }
    my $out = do { local $/; <$pipe> };
    close $pipe;
    return ($?, $out);
}

my $perl = $^X;
my @opts = ('OPTIMIZE=-O0 -g -fsanitize=address,undefined -fno-omit-frame-pointer',
            "LDDLFLAGS=$Config{lddlflags} -fsanitize=address,undefined");
my $rc;
my $out;

($rc, $out) = capture($perl, 'Makefile.PL', @opts);
ok($rc == 0, "Makefile.PL configured under sanitizer flags") or do { diag($out); done_testing; exit };

($rc, $out) = capture('make');
ok($rc == 0, "build under sanitizer flags") or do { diag($out); done_testing; exit };

local $ENV{LD_PRELOAD}    = "$asan_lib $ubsan_lib";
local $ENV{ASAN_OPTIONS}  = 'detect_leaks=1:halt_on_error=1';
local $ENV{UBSAN_OPTIONS} = 'print_stacktrace=1:halt_on_error=1';

($rc, $out) = capture($perl, '-S', 'prove', '-b', "$cwd/t/");
my $pass = $rc == 0;

ok($pass, "all tests pass under ASan/UBSan") or diag($out);
unlike($out, qr/(?:ERROR|SUMMARY): (?:AddressSanitizer|LeakSanitizer)|AddressSanitizer:DEADLYSIGNAL/, 'no ASan reports')
    or diag($out);
unlike($out, qr/runtime error:/, 'no UBSan reports')
    or diag($out);

chdir $cwd;
done_testing;
