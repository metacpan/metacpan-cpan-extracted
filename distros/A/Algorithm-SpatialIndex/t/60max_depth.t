use strict;
use warnings;
use Test::More tests => 2;
use Algorithm::SpatialIndex;

my $tlibpath;
BEGIN {
  $tlibpath = -d "t" ? "t/lib" : "lib";
}
use lib $tlibpath;

my @limits = qw(0 0 1 1);
my $index = Algorithm::SpatialIndex->new(
  strategy => 'QuadTree',
  storage  => 'Memory',
  limit_x_low => $limits[0],
  limit_y_low => $limits[1],
  limit_x_up  => $limits[2],
  limit_y_up  => $limits[3],
  bucket_size => 2,
  max_depth   => 2,
);

isa_ok($index, 'Algorithm::SpatialIndex');

$index->insert($_, 0.2123123123, 0.1111111111111) for 1..10;

my $s = $index->storage;

# WARNING: This breaking encapsulation
my $buckets = $s->{buckets};

ok((grep {defined $_ and @{$_->items} > 2} @$buckets), "bucket_size ignored in favour of max_depth");

