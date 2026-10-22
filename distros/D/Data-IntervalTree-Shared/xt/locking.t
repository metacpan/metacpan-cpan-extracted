use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use Text::ParseWords qw(shellwords);

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'Linux with fork required' unless $^O eq 'linux' && $Config{d_fork};

my $root = dirname(dirname(abs_path(__FILE__)));
my $dir = tempdir(CLEANUP => 1);
my $bin = "$dir/locking";
system(shellwords($Config{cc}), '-std=c11', '-D_GNU_SOURCE', '-O2', '-pthread',
       "-I$root", "$root/xt/locking.c", '-o', $bin) == 0
    or BAIL_OUT('could not compile lock checks');

is system($bin, 'dead'), 0, 'recover an unreaped reader and writer killed while holding locks';
is system($bin, 'reclaim'), 0, 'reclaiming stale reader depth wakes a draining writer';
is system($bin, 'mixed'), 0, 'concurrent readers and writers agree without timeout stalls';
is system($bin, 'freeze', "$dir/frozen.it"), 0, 'read-only attach during freeze sees the completed tree';

done_testing;
