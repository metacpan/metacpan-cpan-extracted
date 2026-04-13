use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);

plan skip_all => 'set ASAN=1 to run' unless $ENV{ASAN};

my $cc = $ENV{CC} || 'cc';
my $asan_lib = `$cc -print-file-name=libasan.so`;
chomp $asan_lib;
plan skip_all => "cannot find libasan.so" unless $asan_lib && -f $asan_lib;

my $src = "$FindBin::Bin/..";
my $tmp = tempdir(CLEANUP => 1);

# rebuild with ASAN
chdir $tmp or die "chdir: $!";
system("cp -a $src/* .") == 0 or die "cp: $!";
system("perl Makefile.PL OPTIMIZE='-g -fsanitize=address -fno-omit-frame-pointer' 2>&1") == 0
    or plan skip_all => "Makefile.PL failed";
system("make clean 2>/dev/null; make 2>&1") == 0
    or plan skip_all => "make failed with ASAN flags";

# run each test under ASAN
my @tests = glob("t/*.t");
plan tests => scalar @tests;

for my $t (@tests) {
    my $out = `LD_PRELOAD=$asan_lib perl -Iblib/lib -Iblib/arch $t 2>&1`;
    my $rc = $? >> 8;
    my $asan_err = ($out =~ /ERROR: AddressSanitizer/);
    ok(!$asan_err && $rc == 0, "$t under ASAN")
        or diag substr($out, -2000);
}

chdir $src;
