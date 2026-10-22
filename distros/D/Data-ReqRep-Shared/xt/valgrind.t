use strict;
use warnings;
use Test::More;
use Config;

# Run the real interpreter: where `perl` is a shim (plenv, perlbrew) valgrind traces the shell.
my $PERL = $Config{perlpath};

plan skip_all => 'set VALGRIND=1 to run' unless $ENV{VALGRIND};

my $vg = `which valgrind 2>/dev/null`;
chomp $vg;
plan skip_all => 'valgrind not found' unless $vg && -x $vg;

my @tests = glob("t/*.t");
plan tests => scalar @tests;

for my $t (sort @tests) {
    my $name = $t; $name =~ s{.*/}{};
    my $out = `PERL_DESTRUCT_LEVEL=2 valgrind --leak-check=full --error-exitcode=42 --errors-for-leak-kinds=definite $PERL -Mblib $t 2>&1`;
    ok $? == 0, "valgrind: $name" or diag $out;
}
