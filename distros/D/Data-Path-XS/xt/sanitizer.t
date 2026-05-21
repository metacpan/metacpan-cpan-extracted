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
my $tmp = tempdir(CLEANUP => 1);
chdir $tmp or die "chdir $tmp: $!";

my $perl = $Config{perlpath} || 'perl';
my $opts = q{OPTIMIZE=-O0 -g -fsanitize=address,undefined -fno-omit-frame-pointer};

# Build out-of-tree, pointing back to the source.
local $ENV{PERL_MM_OPT} = $opts;
local $ENV{LD} = "cc -fsanitize=address,undefined";
my $rc;

$rc = system("$perl $cwd/Makefile.PL >/dev/null 2>&1");
ok($rc == 0, "Makefile.PL configured under sanitizer flags") or do { chdir $cwd; done_testing; exit };

$rc = system("make CCFLAGS_AS_NEEDED= LD='cc -fsanitize=address,undefined' >/dev/null 2>&1");
ok($rc == 0, "build under sanitizer flags") or do { chdir $cwd; done_testing; exit };

local $ENV{LD_PRELOAD}    = "$asan_lib $ubsan_lib";
local $ENV{ASAN_OPTIONS}  = 'detect_leaks=1:abort_on_error=0:halt_on_error=0';
local $ENV{UBSAN_OPTIONS} = 'print_stacktrace=1:halt_on_error=0';

my $out = `prove -b $cwd/t/ 2>&1`;
$rc = $? >> 8;
my $pass = $rc == 0;

ok($pass, "all tests pass under ASan/UBSan");
unlike($out, qr/AddressSanitizer:.*\bDataPath/i,  'no ASan reports rooted in Data::Path::XS')
    or diag($out);
unlike($out, qr/runtime error:.*\bXS\.xs/,         'no UBSan reports rooted in XS.xs')
    or diag($out);

chdir $cwd;
done_testing;
