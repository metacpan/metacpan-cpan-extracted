use strict;
use warnings;
use Test::More;
use Config;

my $cc = $Config{cc} || 'cc';
my $asan_lib = `$cc -print-file-name=libasan.so 2>/dev/null`;
chomp $asan_lib;

plan skip_all => 'libasan not found' unless $asan_lib && -f $asan_lib;
plan skip_all => 'set ASAN=1 to run' unless $ENV{ASAN};

# Rebuild with ASAN flags in-place
my $build = `make clean 2>/dev/null; perl Makefile.PL OPTIMIZE='-O0 -g -fsanitize=address -fno-omit-frame-pointer' 2>&1 && make 2>&1`;
like $build, qr/Shared\.o/, 'ASAN build succeeded'
    or BAIL_OUT("ASAN build failed:\n$build");

my @tests = sort glob("t/*.t");
for my $t (@tests) {
    (my $name = $t) =~ s{.*/}{};
    my $out = `LD_PRELOAD=$asan_lib ASAN_OPTIONS=detect_leaks=0 perl -Mblib $t 2>&1`;
    my $ok = ($? == 0);
    ok $ok, "asan: $name" or diag $out;
}

diag "rebuilding without ASAN...";
`make clean 2>/dev/null; perl Makefile.PL 2>&1 && make 2>&1`;

done_testing;
