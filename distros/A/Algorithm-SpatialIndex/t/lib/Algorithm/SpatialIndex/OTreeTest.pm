package Algorithm::SpatialIndex::OTreeTest;
use strict;
use warnings;
use Test::More;
use Algorithm::SpatialIndex::Strategy::OctTree;

sub run {
  my $class = shift;
  my $storage = shift;
  
  my @limits = qw(12 -2 -10 15 7 -5);
  my $index = Algorithm::SpatialIndex->new(
    strategy => 'OctTree',
    storage  => $storage,
    limit_x_low => $limits[0],
    limit_y_low => $limits[1],
    limit_z_low => $limits[2],
    limit_x_up  => $limits[3],
    limit_y_up  => $limits[4],
    limit_z_up  => $limits[5],
    bucket_size => 5,
    @_,
  );

  isa_ok($index, 'Algorithm::SpatialIndex');

  my $strategy = $index->strategy;
  isa_ok($strategy, 'Algorithm::SpatialIndex::Strategy::OctTree');

  is($strategy->no_of_subnodes, 8, 'OctTree has four subnodes');
  is_deeply([$strategy->coord_types], [qw(double double double double double double double double double)], 'OctTree has six coordinates');

  # this is unit testing:
  SCOPE: {
    my ($x, $y, $z) = $strategy->_node_split_coords(undef, undef, [2, -3, 1, 5, 4, 1]);
    my $eps = 1.e-6;
    cmp_ok($x, '<=', 3.5+$eps);
    cmp_ok($x, '>=', 3.5-$eps);
    cmp_ok($y, '<=', 0.5+$eps);
    cmp_ok($y, '>=', 0.5-$eps);
    cmp_ok($z, '<=', 1.0+$eps);
    cmp_ok($z, '>=', 1.0-$eps);

    # assert that we have a top node whatever comes
    ok(defined($strategy->top_node_id), 'Have a top node id');
    my $top_node = $index->storage->fetch_node($strategy->top_node_id);
    isa_ok($top_node, 'Algorithm::SpatialIndex::Node');
    is($top_node->id, $strategy->top_node_id, 'Top node has top_node_id...');
    my $xy = $top_node->coords;

    for (0..5) {
      cmp_ok($xy->[$_], '<=', $limits[$_]+$eps, "Top node coordinate $_ okay (LE)");
      cmp_ok($xy->[$_], '>=', $limits[$_]-$eps, "Top node coordinate $_ okay (GE)");
    }
  }

  my $scale = 1;
  my $item_id = 0;
  foreach my $x (map {$_/$scale} $limits[0]*$scale..$limits[3]*$scale) {
    foreach my $y (map {$_/$scale} $limits[1]*$scale..$limits[4]*$scale) {
      foreach my $z (map {$_/$scale} $limits[2]*$scale..$limits[5]*$scale) {
        $index->insert($item_id++, $x, $y, $z);
      }
    }
  }
  #diag("Inserted $i nodes");

  foreach my $coords ([0, 0, 0],
                      [100, 100, -6],
                      [-12, 14, -9])
  {
    ok(!defined($strategy->find_node_for(@$coords)), 'Coords outside index have no node');
  }


  #my @limits = qw(12 -2 -10 15 7 -5);
  foreach my $coords ([12, -2, -6],
                      [12, 7, -5.1],
                      [15, -2, -10],
                      [15, 7, -7.5],
                      [14.123, 4.09, -5.1],
                      [13.123, -1.09, -5],
                      [13, 0, -7])
  {
    my $node = $strategy->find_node_for(@$coords);
    # This test is using internal info about the strategy's coordinates
    my $node_coords = $node->coords;
    cmp_ok($node_coords->[Algorithm::SpatialIndex::Strategy::OctTree::XLOW()],
           '<=', $coords->[0], 'Node lower x boundary okay');
    cmp_ok($node_coords->[Algorithm::SpatialIndex::Strategy::OctTree::YLOW()],
           '<=', $coords->[1], 'Node lower y boundary okay');
    cmp_ok($node_coords->[Algorithm::SpatialIndex::Strategy::OctTree::ZLOW()],
           '<=', $coords->[2], 'Node lower z boundary okay');
    cmp_ok($node_coords->[Algorithm::SpatialIndex::Strategy::OctTree::XUP()],
           '>=', $coords->[0], 'Node upper x boundary okay');
    cmp_ok($node_coords->[Algorithm::SpatialIndex::Strategy::OctTree::YUP()],
           '>=', $coords->[1], 'Node upper y boundary okay');
    cmp_ok($node_coords->[Algorithm::SpatialIndex::Strategy::OctTree::ZUP()],
           '>=', $coords->[2], 'Node upper z boundary okay');

    ok(defined($index->storage->fetch_bucket($node->id)), 'Node has bucket == leaf');
    ok($index->storage->fetch_bucket($node->id)->isa($index->storage->bucket_class), 'bucket is of bucket_class');
  }


  #my @limits = qw(12 -2 -10 15 7 -5);
  foreach my $coords (\@limits,
                      [10, -5, -7, 19, 9, -5],
                      [13, -5, -10, 14, 9, -9.5],
                      [12.1, 0.1, -7.5, 13.05, 0.5, -7.7],
                      )
  {
    my @nodes = $strategy->find_nodes_for(@$coords);
    ok(
      ( 0 == grep {!defined($index->storage->fetch_bucket($_->id))} @nodes ),
      'Node has bucket == leaf'
    );
  }

  #my @limits = qw(12 -2 -10 15 7 -5);
  foreach my $coords (\@limits,
                      [10, -5, -100, 19, 9, 12],
                      )
  {
    my @items = $index->get_items_in_rect(@$coords);
    is(scalar(@items), $item_id, 'Encompassing coords get all elems');
  }
} # end run

1;
