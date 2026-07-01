use strict;
use warnings;
use Test::More;
use Config;

plan skip_all => 'set VALGRIND=1 to run' unless $ENV{VALGRIND};

my $vg = `which valgrind 2>/dev/null`;
chomp $vg;
plan skip_all => 'valgrind not found' unless $vg && -x $vg;

for my $t (sort glob "t/*.t") {
    my $name = $t; $name =~ s{.*/}{};
    my $out = `valgrind --leak-check=full --error-exitcode=42 --errors-for-leak-kinds=definite $Config{perlpath} -Mblib $t 2>&1`;
    my $ok = ($? == 0);
    ok $ok, "valgrind: $name" or do {
        my @lines = grep { /ERROR SUMMARY|definitely lost|Invalid/ } split /\n/, $out;
        diag join("\n", @lines);
    };
}

done_testing;
