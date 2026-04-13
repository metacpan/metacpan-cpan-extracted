use strict;
use warnings;
use Test::More;
use FindBin;

plan skip_all => 'set VALGRIND=1 to run' unless $ENV{VALGRIND};

my $valgrind = `which valgrind 2>/dev/null`;
chomp $valgrind;
plan skip_all => 'valgrind not found' unless $valgrind && -x $valgrind;

my @tests = glob("$FindBin::Bin/../t/*.t");
plan tests => scalar @tests;

for my $t (@tests) {
    my $out = `$valgrind --leak-check=full --error-exitcode=99 perl -Iblib/lib -Iblib/arch $t 2>&1`;
    my $rc = $? >> 8;
    my ($errs) = $out =~ /ERROR SUMMARY: (\d+)/;
    $errs //= -1;
    ok($rc != 99 && $errs == 0, "$t under valgrind")
        or diag "exit=$rc errors=$errs\n" . substr($out, -2000);
}
