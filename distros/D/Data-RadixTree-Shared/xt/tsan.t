use strict;
use warnings;
use Test::More;
use Config;

my $cc = $Config{cc} || 'cc';
my $tsan_lib = `$cc -print-file-name=libtsan.so 2>/dev/null`;
chomp $tsan_lib;

plan skip_all => 'libtsan not found' unless $tsan_lib && -f $tsan_lib;
plan skip_all => 'set TSAN=1 to run' unless $ENV{TSAN};

my $build = `make clean 2>/dev/null; perl Makefile.PL OPTIMIZE='-O1 -g -fsanitize=thread -fno-omit-frame-pointer' 2>&1 && make 2>&1`;
like $build, qr/Shared\.o/, 'TSan build succeeded'
    or BAIL_OUT("TSan build failed:\n$build");

my @tests = sort glob("t/*.t");
for my $t (@tests) {
    (my $name = $t) =~ s{.*/}{};
    my $out = `LD_PRELOAD=$tsan_lib TSAN_OPTIONS='halt_on_error=1 second_deadlock_stack=1' perl -Mblib $t 2>&1`;
    my $ok = ($? == 0);
    ok $ok, "tsan: $name" or diag $out;
}

diag "rebuilding without TSan...";
`make clean 2>/dev/null; perl Makefile.PL 2>&1 && make 2>&1`;

done_testing;
