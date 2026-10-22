use strict;
use warnings;
use Config;
use Test::More;
BEGIN { plan skip_all => 'needs a perl built with ithreads' unless $Config{useithreads} }
use threads;
use threads::shared;
use File::Temp qw(tempdir);
use Data::PerfectHash::Shared;

# A thread must not take the parent's handles with it when it exits.
my $dir = tempdir(CLEANUP => 1);
my $f = "$dir/t.phs";
Data::PerfectHash::Shared->build_int($f, [1 .. 1000]);
my $s = Data::PerfectHash::Shared->load($f);
my $b = Data::PerfectHash::Shared->new_builder;
$b->add_many([1 .. 10]);
threads->create(sub { 1 })->join;
ok eval { $s->has(5) }, 'the parent can still query its handle after a thread exits' or diag $@;
is eval { $s->count }, 1000, '  and it still holds every key';
is $b->count, 10, 'the parent builder survives thread exit';

my $go :shared = 0;
my @workers = map {
    my $worker = $_;
    threads->create(sub {
        { lock $go; cond_wait($go) until $go }
        for my $type (qw(int str)) {
            my @keys = map { $type eq 'int' ? $_ * 3 + $worker * 10_000
                : "$worker:$_:" . ('x' x ($_ % 41)) } 1 .. 500 + $worker * 137;
            my $method = "build_$type";
            for (1 .. 3) {
                my $path = "$dir/worker-$worker-$type.phs";
                Data::PerfectHash::Shared->$method($path, \@keys);
                my $set = Data::PerfectHash::Shared->load($path);
                die 'wrong count' unless $set->count == @keys;
                die 'missing member' if grep { !$set->has($_) } @keys;
                die 'false positive' if $set->has($type eq 'int' ? -1 : 'absent');
            }
        }
        return 1;
    });
} 1 .. 4;
{ lock $go; $go = 1; cond_broadcast($go) }
ok $_->join, 'concurrent integer and string builds remain exact' for @workers;
is $b->count, 10, 'concurrent builders leave the parent builder intact';
ok $s->has(5), 'concurrent builders leave the parent mapping intact';
done_testing;
