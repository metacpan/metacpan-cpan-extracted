use strict;
use warnings;
use Test::More;
use Config;
use Text::ParseWords qw(shellwords);
use File::Temp qw(tempdir);

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};

my $dir = tempdir(CLEANUP => 1);
my $bin = "$dir/rwlock";
my @cc = shellwords($Config{cc});
is system(@cc, '-D_GNU_SOURCE', '-O2', '-pthread', '-I.', 'xt/rwlock.c', '-o', $bin),
   0, 'build rwlock stress test' or BAIL_OUT('rwlock test did not compile');
is system($bin), 0, 'no missed wakes; dead readers and writers recover';

done_testing;
