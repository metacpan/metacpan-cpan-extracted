use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Basename qw(dirname);
use Cwd qw(abs_path getcwd);
use Config;
use ExtUtils::Manifest qw(maniread manicopy);

# Rebuild with -fsanitize=undefined and run the test suite. Catches
# signed overflow, unaligned loads, shift-by-width, and other UB that
# optimizer can otherwise silently fold into working (but fragile) code.

plan skip_all => "set UBSAN=1 to run" unless $ENV{UBSAN};

my $src = dirname(dirname(abs_path(__FILE__)));
my $tmp = tempdir(CLEANUP => 1);
my $cwd = getcwd();
chdir $src or die $!;
manicopy(maniread(), $tmp, 'cp');
chdir $tmp or die $!;

diag "building in $tmp with UBSAN...";
my $rc = system($^X, 'Makefile.PL',
    'OPTIMIZE=-O1 -g -fsanitize=undefined -fno-sanitize-recover=undefined',
    "LDDLFLAGS=$Config{lddlflags} -fsanitize=undefined");
$rc ||= system('make', '-s');
is $rc, 0, "UBSAN build succeeded";

$rc = system('make', 'test');
is $rc, 0, "UBSAN test pass — no undefined behavior detected";
chdir $cwd or die $!;

done_testing;
