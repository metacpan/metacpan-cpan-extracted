use strict;
use Benchmark qw(cmpthese);

use Data::Throttler;
use Data::Valve;

my $t = Data::Throttler->new(max_items => 5, interval => 10, db_file => "hoge.dat");
my $v = Data::Valve->new(max_items => 5, interval => 10,
    bucket_store => {
        module => "Memcached",
    }
);

cmpthese( 800, {
    throttler => sub { $t->try_push },
    valve     => sub { $v->try_push },
} );