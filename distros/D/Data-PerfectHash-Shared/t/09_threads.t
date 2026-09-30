use strict;
use warnings;
use Config;
use Test::More;
BEGIN { plan skip_all => 'needs a perl built with ithreads' unless $Config{useithreads} }
use threads;
use File::Temp qw(tempdir);
use Data::PerfectHash::Shared;

# A thread must not take the parent's handles with it when it exits.
my $f = tempdir(CLEANUP => 1) . '/t.phs';
Data::PerfectHash::Shared->build_int($f, [1 .. 1000]);
my $s = Data::PerfectHash::Shared->load($f);
threads->create(sub { 1 })->join;
ok eval { $s->has(5) }, 'the parent can still query its handle after a thread exits' or diag $@;
is eval { $s->count }, 1000, '  and it still holds every key';
done_testing;
