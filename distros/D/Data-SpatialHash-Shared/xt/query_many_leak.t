use strict;
use warnings FATAL => 'numeric';
use Test::More;
use Data::SpatialHash::Shared;

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};

sub vm_size {
    open my $f, '<', '/proc/self/status' or die $!;
    while (<$f>) { return $1 if /^VmSize:\s+(\d+)/ }
    die 'VmSize missing';
}

my $s = Data::SpatialHash::Shared->new(undef, 16, 0, 1.0);
my $queries = [ ['invalid', 0, 1], map { [0, 0, 1] } 1 .. 999 ];
eval { $s->query_radius_many($queries) } for 1 .. 100;
my $before = vm_size();
eval { $s->query_radius_many($queries) } for 1 .. 5000;
cmp_ok vm_size() - $before, '<', 4096,
    'repeated batch conversion errors do not leak result arrays';

done_testing;
