package Algorithm::SpatialIndex::Strategy::OctTree;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

use parent 'Algorithm::SpatialIndex::Strategy::3D';

# Note that the subnode indexes are as follows:
# (like octants, http://en.wikipedia.org/wiki/Octant)
# After wikipedia:
#
#  0) first octant (+, +, +)
#  1) top-back-right (−, +, +)
#  2) top-back-left (−, −, +)
#  3) top-front-left (+, −, +)
#  4) bottom-front-left (+, −, −)
#  5) bottom-back-left (−, −, −)
#  6) bottom-back-right (−, +, −)
#  7) bottom-front-right (+, +, −)


use constant {
  XI       => 1, # item X coord index
  YI       => 2, # item Y coord index
  ZI       => 3, # item Z coord index

  XLOW     => 0, # for access to node coords
  YLOW     => 1,
  ZLOW     => 2,
  XUP      => 3,
  YUP      => 4,
  ZUP      => 5,
  XSPLIT   => 6,
  YSPLIT   => 7,
  ZSPLIT   => 8,

  PPP_NODE => 0,
  MPP_NODE => 1,
  MMP_NODE => 2,
  PMP_NODE => 3,
  PMM_NODE => 4,
  MMM_NODE => 5,
  MPM_NODE => 6,
  PPM_NODE => 7,
};

use Exporter 'import';
our @EXPORT_OK = qw(
  XI
  YI
  ZI

  XLOW
  YLOW
  ZLOW
  XUP
  YUP
  ZUP
  XSPLIT
  YSPLIT
  ZSPLIT

  PPP_NODE
  MPP_NODE
  MMP_NODE
  PMP_NODE
  PMM_NODE
  MMM_NODE
  MPM_NODE
  PPM_NODE
);
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);

use Class::XSAccessor {
  getters => [qw(
    top_node_id
    bucket_size
    max_depth
    total_width
  )],
};

sub coord_types { qw(double double double double double double double double double) } # 9 doubles

sub init {}

sub init_storage {
  my $self = shift;
  my $index   = $self->index;
  my $storage = $self->storage;

  # stored bucket_size for persistent indexes
  $self->{bucket_size} = $storage->get_option('bucket_size');
  $self->{max_depth}   = $storage->get_option('max_depth');
  # or use configured one
  $self->{bucket_size} = $index->bucket_size if not defined $self->bucket_size;
  $self->{max_depth}   = $index->max_depth   if not defined $self->max_depth;

  $self->{top_node_id} = $storage->get_option('top_node_id');
  if (not defined $self->top_node_id) {
    # create a new top node and its bucket
    my $node = Algorithm::SpatialIndex::Node->new(
      coords => [
        $index->limit_x_low, $index->limit_y_low, $index->limit_z_low,
        $index->limit_x_up, $index->limit_y_up, $index->limit_z_up,
        undef, undef, undef,
      ],
      subnode_ids => [],
    );
    $self->{top_node_id} = $storage->store_node($node);
    $self->_make_bucket_for_node($node, $storage);
  }

  $self->{total_width} = $index->limit_x_up - $index->limit_x_low;
}

sub insert {
  my ($self, $id, $x, $y, $z) = @_;
  my $storage = $self->{storage}; # hash access due to hot path
  my $top_node = $storage->fetch_node($self->{top_node_id}); # hash access due to hot path
  return $self->_insert($id, $x, $y, $z, $top_node, $storage);
}

SCOPE: {
  no warnings 'recursion';
  sub _insert {
    my ($self, $id, $x, $y, $z, $node, $storage) = @_;
    my $nxyz = $node->coords;
    my $subnodes = $node->subnode_ids;

    # If we have a bucket, we are the last level of nodes
    SCOPE: {
      my $bucket = $storage->fetch_bucket($node->id);
      if (defined $bucket) {
        my $items = $bucket->items;
        if (@$items < $self->{bucket_size}) {
          # sufficient space in bucket. Insert and return
          push @{$items}, [$id, $x, $y, $z];
          $storage->store_bucket($bucket);
          return();
        }
        # check whether we've reached the maximum depth of the tree
        # and ignore bucket size if necessary
        # ( total width / local width ) = 2^( depth )
        elsif ($nxyz->[XUP] - $nxyz->[XLOW] <= 0.
               or log($self->total_width / ($nxyz->[XUP]-$nxyz->[XLOW])) / log(2) >= $self->max_depth)
        {
          # bucket at the maximum depth. Insert and return
          push @{$items}, [$id, $x, $y];
          $storage->store_bucket($bucket);
          return();
        }
        else {
          # bucket full, need to add new layer of nodes and split the bucket
          $self->_split_node($node, $bucket);
          # refresh data that will have changed:
          $node = $storage->fetch_node($node->id); # has updated subnode ids
          $subnodes = $node->subnode_ids;
          # Now we just continue with the normal subnode checking below:
        }
      }
    } # end scope

    my $subnode_index;
    if ($x <= $nxyz->[XSPLIT]) {
      if ($y <= $nxyz->[YSPLIT]) {
        if ($z <= $nxyz->[ZSPLIT]) { $subnode_index = MMM_NODE }
        else                       { $subnode_index = MMP_NODE }
      }
      else { # $y > ysplit
        if ($z <= $nxyz->[ZSPLIT]) { $subnode_index = MPM_NODE }
        else                       { $subnode_index = MPP_NODE }
      }
    }
    else { # $x > xsplit
      if ($y <= $nxyz->[YSPLIT]) {
        if ($z <= $nxyz->[ZSPLIT]) { $subnode_index = PMM_NODE }
        else                       { $subnode_index = PMP_NODE }
      }
      else { # $y > ysplit
        if ($z <= $nxyz->[ZSPLIT]) { $subnode_index = PPM_NODE }
        else                       { $subnode_index = PPP_NODE }
      }
    }

    if (not defined $subnodes->[$subnode_index]) {
      die("Cannot find subnode $subnode_index if node id=".$node->id);
    }
    else {
      my $subnode = $storage->fetch_node($subnodes->[$subnode_index]);
      die("Need node '" .$subnodes->[$subnode_index] . '", but it is not in storage!')
        if not defined $subnode;
      return $self->_insert($id, $x, $y, $z, $subnode, $storage);
    }
  }
} # end SCOPE

sub _node_split_coords {
  # args: $self, $node, $bucket, $coords
  my $c = $_[3];
  return(
    ($c->[XLOW]+$c->[XUP])/2,
    ($c->[YLOW]+$c->[YUP])/2,
    ($c->[ZLOW]+$c->[ZUP])/2,
  );
}


# Splits the given node into four new nodes of equal
# size and assigns the items
sub _split_node {
  my $self        = shift;
  my $parent_node = shift;
  my $bucket      = shift; # just for speed, can be taken from parent_node

  my $storage = $self->storage;
  my $parent_node_id = $parent_node->id;
  $bucket = $storage->fetch_bucket($parent_node_id) if not defined $bucket;

  my $coords = $parent_node->coords;
  my ($splitx, $splity, $splitz) = $self->_node_split_coords($parent_node, $bucket, $coords);
  @$coords[XSPLIT, YSPLIT, ZSPLIT] = ($splitx, $splity, $splitz); # stored below
  my @child_nodes;

  # PPP_NODE
  push @child_nodes, Algorithm::SpatialIndex::Node->new(
    coords      => [$splitx, $splity, $splitz,
                    $coords->[XUP], $coords->[YUP], $coords->[ZUP],
                    undef, undef, undef],
    subnode_ids => [],
  );
  # MPP_NODE
  push @child_nodes, Algorithm::SpatialIndex::Node->new(
    coords      => [$coords->[XLOW], $splity, $splitz,
                    $splitx, $coords->[YUP], $coords->[ZUP],
                    undef, undef, undef],
    subnode_ids => [],
  );
  # MMP_NODE
  push @child_nodes, Algorithm::SpatialIndex::Node->new(
    coords      => [$coords->[XLOW], $coords->[YLOW], $splitz,
                    $splitx, $splity, $coords->[ZUP],
                    undef, undef, undef],
    subnode_ids => [],
  );
  # PMP_NODE
  push @child_nodes, Algorithm::SpatialIndex::Node->new(
    coords      => [$splitx, $coords->[YLOW], $splitz,
                    $coords->[XUP], $splity, $coords->[ZUP],
                    undef, undef, undef],
    subnode_ids => [],
  );
  # PMM_NODE
  push @child_nodes, Algorithm::SpatialIndex::Node->new(
    coords      => [$splitx, $coords->[YLOW], $coords->[ZLOW],
                    $coords->[XUP], $splity, $splitz,
                    undef, undef, undef],
    subnode_ids => [],
  );
  # MMM_NODE
  push @child_nodes, Algorithm::SpatialIndex::Node->new(
    coords      => [$coords->[XLOW], $coords->[YLOW], $coords->[ZLOW],
                    $splitx, $splity, $splitz,
                    undef, undef, undef],
    subnode_ids => [],
  );
  # MPM_NODE
  push @child_nodes, Algorithm::SpatialIndex::Node->new(
    coords      => [$coords->[XLOW], $splity, $coords->[ZLOW],
                    $splitx, $coords->[YUP], $splitz,
                    undef, undef, undef],
    subnode_ids => [],
  );
  # PPM_NODE
  push @child_nodes, Algorithm::SpatialIndex::Node->new(
    coords      => [$splitx, $splity, $coords->[ZLOW],
                    $coords->[XUP], $coords->[YUP], $splitz,
                    undef, undef, undef],
    subnode_ids => [],
  );

  # save nodes
  my $snode_ids = $parent_node->subnode_ids;
  foreach my $cnode (@child_nodes) {
    push @{$snode_ids}, $storage->store_node($cnode);
  }
  $storage->store_node($parent_node);

  # split bucket
  my $items = $bucket->items;
  my @child_items = ( map [], @child_nodes );
  foreach my $item (@$items) {
    if ($item->[XI] <= $splitx) {
      if ($item->[YI] <= $splity) {
        if ($item->[ZI] <= $splitz) { push @{$child_items[MMM_NODE]}, $item }
        else                        { push @{$child_items[MMP_NODE]}, $item }
      }
      else { # $item->[YI] > ysplit
        if ($item->[ZI] <= $splitz) { push @{$child_items[MPM_NODE]}, $item }
        else                        { push @{$child_items[MPP_NODE]}, $item }
      }
    }
    else { # $item->[XI] > xsplit
      if ($item->[YI] <= $splity) {
        if ($item->[ZI] <= $splitz) { push @{$child_items[PMM_NODE]}, $item }
        else                        { push @{$child_items[PMP_NODE]}, $item }
      }
      else { # $item->[YI] > ysplit
        if ($item->[ZI] <= $splitz) { push @{$child_items[PPM_NODE]}, $item }
        else                        { push @{$child_items[PPP_NODE]}, $item }
      }
    }
  }
  
  # generate buckets
  foreach my $subnode_idx (0..$#child_nodes) {
    $self->_make_bucket_for_node(
      $child_nodes[$subnode_idx],
      $storage,
      $child_items[$subnode_idx]
    );
  }

  # remove the parent node's bucket
  $storage->delete_bucket($bucket);
}

sub _make_bucket_for_node {
  my $self = shift;
  my $node_id = shift;
  my $storage = shift || $self->storage;
  my $items = shift || [];
  $node_id = $node_id->id if ref $node_id;

  my $b = $storage->bucket_class->new(
    node_id => $node_id,
    items   => $items,
  );
  $storage->store_bucket($b);
}


sub find_node_for {
  my ($self, $x, $y, $z) = @_;
  my $storage = $self->storage;
  my $topnode = $storage->fetch_node($self->top_node_id);
  my $coords  = $topnode->coords;

  # boundary check
  if ($x < $coords->[XLOW]
      or $x > $coords->[XUP]
      or $y < $coords->[YLOW]
      or $y > $coords->[YUP]
      or $z < $coords->[ZLOW]
      or $z > $coords->[ZUP])
  {
    return undef;
  }

  return $self->_find_node_for($x, $y, $z, $storage, $topnode);
}

# TODO: This is almost trivial to rewrite in non-recursive form
SCOPE: {
  no warnings 'recursion';
  sub _find_node_for {
    my ($self, $x, $y, $z, $storage, $node) = @_;

    my $snode_ids = $node->subnode_ids;
    return $node if not @$snode_ids;

    # find the right sub node
    my ($xsplit, $ysplit, $zsplit) = @{$node->coords}[XSPLIT, YSPLIT, ZSPLIT];
    my $subnode_id;
    if ($x <= $xsplit) {
      if ($y <= $ysplit) {
        if ($z <= $zsplit) { $subnode_id = $snode_ids->[MMM_NODE] }
        else               { $subnode_id = $snode_ids->[MMP_NODE] }
      }
      else { # $y > ysplit
        if ($z <= $zsplit) { $subnode_id = $snode_ids->[MPM_NODE] }
        else               { $subnode_id = $snode_ids->[MPP_NODE] }
      }
    }
    else { # $x > xsplit
      if ($y <= $ysplit) {
        if ($z <= $zsplit) { $subnode_id = $snode_ids->[PMM_NODE] }
        else               { $subnode_id = $snode_ids->[PMP_NODE] }
      }
      else { # $y > ysplit
        if ($z <= $zsplit) { $subnode_id = $snode_ids->[PPM_NODE] }
        else               { $subnode_id = $snode_ids->[PPP_NODE] }
      }
    }

    my $snode = $storage->fetch_node($subnode_id);
    return $self->_find_node_for($x, $y, $z, $storage, $snode);
  }
} # end SCOPE


sub find_nodes_for {
  my ($self, $x1, $y1, $z1, $x2, $y2, $z2) = @_;

  # normalize coords
  my ($xl, $xu) = $x1 < $x2 ? ($x1, $x2) : ($x2, $x1);
  my ($yl, $yu) = $y1 < $y2 ? ($y1, $y2) : ($y2, $y1);
  my ($zl, $zu) = $z1 < $z2 ? ($z1, $z2) : ($z2, $z1);

  my $storage = $self->storage;
  my $topnode = $storage->fetch_node($self->top_node_id);
  my $coords = $topnode->coords;

  my $rv = [];
  _find_nodes_for($self, $xl, $yl, $zl, $xu, $yu, $zu, $storage, $topnode, $rv);
  return @$rv;
}

sub _find_nodes_for {
  my ($self, $xl, $yl, $zl, $xu, $yu, $zu, $storage, $node, $rv) = @_;
  
  my $coords = $node->coords;

  # boundary check
  if (   $xu < $coords->[XLOW]
      or $xl > $coords->[XUP]
      or $yu < $coords->[YLOW]
      or $yl > $coords->[YUP]
      or $zu < $coords->[ZLOW]
      or $zl > $coords->[ZUP])
  {
    return;
  }

  my $snode_ids = $node->subnode_ids;
  if (not @$snode_ids) {
    # leaf
    push @$rv, $node;
    return;
  }

  # not a leaf
  foreach my $id (@$snode_ids) {
    $self->_find_nodes_for(
      $xl, $yl, $zl, $xu, $yu, $zu, $storage,
      $storage->fetch_node($id),
      $rv
    );
  }
}

# Returns the leaves for the given node
sub _get_all_leaf_nodes {
  my $self = shift;
  my $node = shift;
  my $storage = $self->storage;

  my @leaves;
  my @nodes = ($node);
  while (@nodes) {
    $node = shift @nodes;
    my $snode_ids = $node->subnode_ids;
    if (@$snode_ids) {
      push @nodes, map $storage->fetch_node($_), @$snode_ids;
    }
    else {
      push @leaves, $node;
    }
  }

  return @leaves;
}

1;
__END__

=head1 NAME

Algorithm::SpatialIndex::Strategy::OctTree - Basic OctTree strategy

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    strategy => 'OctTree',
  );

=head1 DESCRIPTION

An oct tree implementation.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
