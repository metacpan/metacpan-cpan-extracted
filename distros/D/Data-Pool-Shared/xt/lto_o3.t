use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Basename qw(dirname);
use Cwd qw(abs_path getcwd);
use Config;
use ExtUtils::Manifest qw(maniread manicopy);

# Rebuild with -O3 -flto. Aggressive inlining sometimes exposes missing
# atomic fences, strict-aliasing violations, or load/store reorderings
# that -O2 builds happen to mask.

plan skip_all => "set LTO=1 to run" unless $ENV{LTO};

my $src = dirname(dirname(abs_path(__FILE__)));
my $tmp = tempdir(CLEANUP => 1);
my $cwd = getcwd();
chdir $src or die $!;
manicopy(maniread(), $tmp, 'cp');
chdir $tmp or die $!;

diag "building with -O3 -flto in $tmp...";
my $rc = system($^X, 'Makefile.PL', 'OPTIMIZE=-O3 -flto -g',
    "LDDLFLAGS=$Config{lddlflags} -flto");
$rc ||= system('make', '-s');
is $rc, 0, "LTO build succeeded";

$rc = system('make', 'test');
is $rc, 0, "all tests pass under -O3 -flto";
chdir $cwd or die $!;

done_testing;
