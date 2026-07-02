use strict;
use warnings;
use Test::More;
use Config;

plan skip_all => 'set TSAN=1 to run' unless $ENV{TSAN};

my $cc = $Config{cc} || 'cc';
my $tsan_lib = `$cc -print-file-name=libtsan.so 2>/dev/null`;
chomp $tsan_lib;
plan skip_all => 'libtsan not found' unless $tsan_lib && -f $tsan_lib;

my $build = `make clean 2>/dev/null; perl Makefile.PL OPTIMIZE='-O1 -g -fsanitize=thread -fno-omit-frame-pointer' 2>&1 && make 2>&1`;
like $build, qr/Shared\.o/, 'TSan build succeeded'
    or BAIL_OUT("TSan build failed:\n$build");

for my $t (sort glob "t/*.t") {
    (my $name = $t) =~ s{.*/}{};
    my $out = `LD_PRELOAD=$tsan_lib TSAN_OPTIONS='halt_on_error=1 second_deadlock_stack=1' $Config{perlpath} -Mblib $t 2>&1`;
    ok $? == 0, "tsan: $name" or diag $out;
}

diag "rebuilding without TSan...";
my $rebuild = `make clean 2>/dev/null; perl Makefile.PL 2>&1 && make 2>&1`;
diag "WARNING: cleanup rebuild failed; a later plain test run may use the still-instrumented .so:\n$rebuild"
    unless $? == 0;

done_testing;
