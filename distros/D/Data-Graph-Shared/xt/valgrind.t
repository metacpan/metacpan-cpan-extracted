use strict;
use warnings;
use Test::More;
use Config;

# Run the REAL interpreter, not a wrapper script: where `perl` is a shim
# (plenv, perlbrew) valgrind traces the shell and never sees the XS code, so
# every test passes whatever the module does.
my $PERL = $Config{perlpath};

plan skip_all => 'set VALGRIND=1 to run' unless $ENV{VALGRIND};

my $vg = `which valgrind 2>/dev/null`;
chomp $vg;
plan skip_all => 'valgrind not found' unless $vg && -x $vg;

my @tests = glob("t/*.t");
plan tests => scalar @tests;

for my $t (sort @tests) {
    my $name = $t; $name =~ s{.*/}{};
    my $out = `valgrind --leak-check=full --error-exitcode=42 --errors-for-leak-kinds=definite $PERL -Mblib $t 2>&1`;
    my $exit = $? >> 8;
    my $ok = ($exit != 42);
    ok $ok, "valgrind: $name" or do {
        my @lines = grep { /ERROR SUMMARY|definitely lost|Invalid/ } split /\n/, $out;
        diag join("\n", @lines);
    };
}
