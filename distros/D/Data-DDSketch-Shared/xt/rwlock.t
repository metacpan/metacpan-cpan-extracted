use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use Text::ParseWords qw(shellwords);

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
my $dir = tempdir('ddsketch-rwlock-XXXXXX', TMPDIR => 1, CLEANUP => 1);
my $root = abs_path('.');
my $status = system(shellwords($Config{cc}), '-D_GNU_SOURCE', '-O2', '-pthread',
    "-I$root", 'xt/rwlock.c', '-lm', '-o', "$dir/rwlock");
is $status, 0, 'native lock regression build' or BAIL_OUT('compile failed');
$status = system("$dir/rwlock");
is $status, 0, 'reader recovery, contention and allocation failure regressions';
done_testing;
