use strict;
use warnings;
use Test::More;
use Config;

# Run the real interpreter, not a wrapper script: where `perl` is a shim
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
    # PERL_DESTRUCT_LEVEL=2 makes perl free its arenas at exit; without it a C
    # allocation still owned by a never-freed SV reads as "still reachable" and
    # a real leak never trips --errors-for-leak-kinds=definite.
    my $out = `PERL_DESTRUCT_LEVEL=2 valgrind --leak-check=full --error-exitcode=42 --errors-for-leak-kinds=definite $PERL -Mblib $t 2>&1`;
    ok $? == 0, "valgrind: $name" or diag $out;
}
