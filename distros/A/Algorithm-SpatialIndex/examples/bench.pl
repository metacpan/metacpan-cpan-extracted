use strict;
use warnings;
use lib 'lib';
use Algorithm::SpatialIndex;
use Algorithm::QuadTree;
use Benchmark qw(cmpthese timethese);

# ordered or random or concentrated_random
#my $item_mode = 'ordered';
#my $item_mode = 'random';
my $item_mode = 'concentrated_random';

my $use_dbi = 0;
if ($use_dbi) {
  eval "use DBI; use DBD::SQLite;";
  unlink 't.sqlite';
  $use_dbi = DBI->connect("dbi:SQLite:dbname=t.sqlite", "", "");
}
my $use_median_qtree = eval {
  use Algorithm::SpatialIndex::Strategy::MedianQuadTree;
  1;
};

my $bucks = 100;
my $scale = 15;
my $depth = 10;
my @limits = qw(-10 -10 10 10);
my @si_opt = (
  strategy => 'QuadTree',
  storage  => 'Memory',
  limit_x_low => $limits[0],
  limit_y_low => $limits[1],
  limit_x_up  => $limits[2],
  limit_y_up  => $limits[3],
  bucket_size => $bucks,
);
my @si_opt_dbi = (
  strategy => 'QuadTree',
  storage  => 'DBI',
  limit_x_low => $limits[0],
  limit_y_low => $limits[1],
  limit_x_up  => $limits[2],
  limit_y_up  => $limits[3],
  bucket_size => $bucks,
  dbh_rw => $use_dbi,
);
my @si_opt_m = @si_opt;
$si_opt_m[1] = 'MedianQuadTree';
my @qt_opt = (
  -xmin  => $limits[0],
  -ymin  => $limits[1],
  -xmax  => $limits[2],
  -ymax  => $limits[3],
  -depth => $depth,
);

my $xrange = $limits[2]-$limits[0];
my $yrange = $limits[3]-$limits[1];
my $concx  = $limits[0] + $xrange/3;
my $concy  = $limits[1] + $yrange*2/3;
my $conc_rx = $xrange/30;
my $conc_ry = $xrange/20;

my @items;

if ($item_mode eq 'ordered') {
  foreach my $x (map {$_/$scale} $limits[0]*$scale..$limits[2]*$scale) {
    foreach my $y (map {$_/$scale} $limits[1]*$scale..$limits[3]*$scale) {
      push @items, [scalar(@items), $x, $y];
    }
  }
}
elsif ($item_mode eq 'random') {
  foreach my $x (map {$_/$scale} $limits[0]*$scale..$limits[2]*$scale) {
    foreach my $y (map {$_/$scale} $limits[1]*$scale..$limits[3]*$scale) {
      push @items, [scalar(@items), $limits[0]+rand($xrange), $limits[1]+rand($yrange)];
    }
  }
}
else {
  foreach my $x (map {$_/$scale} $limits[0]*$scale..$limits[2]*$scale) {
    foreach my $y (map {$_/$scale} $limits[1]*$scale..$limits[3]*$scale) {
      push @items, [scalar(@items), $limits[0]+rand($xrange), $limits[1]+rand($yrange)];
    }
  }
  my $conc_items = int(@items*1);
  for (1..$conc_items) {
    push @items, [scalar(@items), $concx-$conc_rx/2+rand($conc_rx), $concy-$conc_ry/2+rand($conc_ry)];
  }
}
warn "Number of items: " . @items;

=pod

cmpthese(
  -2,
  {
    ($use_dbi ? (si_insert_dbi => sub {
      my $idx = Algorithm::SpatialIndex->new(@si_opt_dbi);
      $idx->insert(@$_) for @items;
    }):()),
    ($use_median_qtree ? (si_insert_mqt => sub {
      my $idx = Algorithm::SpatialIndex->new(@si_opt_m);
      $idx->insert(@$_) for @items;
    }):()),
    si_insert => sub {
      my $idx = Algorithm::SpatialIndex->new(@si_opt);
      $idx->insert(@$_) for @items;
    },
    qt_insert => sub {
      my $qt = Algorithm::QuadTree->new(@qt_opt);
      $qt->add(@$_, @{$_}[1,2]) for @items;
    },
  }
);

=cut

my $idx = Algorithm::SpatialIndex->new(@si_opt);
my $idx_dbi;
$idx_dbi = Algorithm::SpatialIndex->new(@si_opt_dbi) if $use_dbi;
my $idx_mqt;
$idx_mqt = Algorithm::SpatialIndex->new(@si_opt_m) if $use_median_qtree;
my $qt = Algorithm::QuadTree->new(@qt_opt);
$idx->insert(@$_) for @items;
if ($use_median_qtree) {$idx_mqt->insert(@$_) for @items;}
if ($use_dbi) {$idx_dbi->insert(@$_) for @items;}
$qt->add(@$_, @{$_}[1,2]) for @items;

my @rect_small     = ($limits[0]+$xrange*1/3, $limits[1]+$xrange*2/3, $limits[0]+$xrange*1/3+0.01, $limits[1]+$xrange*2/3+0.01);
my @rect_small_off = ($limits[0]+$xrange*2/3, $limits[1]+$xrange*1/3, $limits[0]+$xrange*2/3+0.01, $limits[1]+$xrange*1/3+0.01);
my @rect_med       = (-1.5, -1.4, -0.2, -0.1);
my @rect_big       = (-5, -5, 7, 8);
my $benches = {
    si_poll_small => sub {
      my @o = $idx->get_items_in_rect(@rect_small_off);
    },
    qt_poll_small => sub {
      my @r = @rect_small_off;
      my @o = grep {
        $_->[1] >= $r[0] && $_->[1] <= $r[2] &&
        $_->[2] >= $r[1] && $_->[2] <= $r[3]
      }
      map {$items[$_]}
      @{ $qt->getEnclosedObjects(@r) };
    },
    si_poll_med   => sub {
      my @o = $idx->get_items_in_rect(@rect_med);
    },
    #qt_poll_med => sub {
    #  my @r = @rect_med;
    #  my @o = grep {
    #    $_->[1] >= $r[0] && $_->[1] <= $r[2] &&
    #    $_->[2] >= $r[1] && $_->[2] <= $r[3]
    #  }
    #  map {$items[$_]}
    #  @{ $qt->getEnclosedObjects(@r) };
    #},
    #si_poll_big   => sub {
    #  my @o = $idx->get_items_in_rect(@rect_big);
    #},
    #qt_poll_big => sub {
    #  my @r = @rect_big;
    #  my @o = grep {
    #    $_->[1] >= $r[0] && $_->[1] <= $r[2] &&
    #    $_->[2] >= $r[1] && $_->[2] <= $r[3]
    #  }
    #  map {$items[$_]}
    #  @{ $qt->getEnclosedObjects(@r) };
    #},
    prim_poll_small => sub {
      my @r = @rect_small_off;
      my @o = grep {
        $_->[1] >= $r[0] && $_->[1] <= $r[2] &&
        $_->[2] >= $r[1] && $_->[2] <= $r[3]
      } @items;
    },
    #prim_poll_med   => sub {
    #  my @r = @rect_med;
    #  my @o = grep {
    #    $_->[1] >= $r[0] && $_->[1] <= $r[2] &&
    #    $_->[2] >= $r[1] && $_->[2] <= $r[3]
    #  } @items;
    #},
    #prim_poll_big   => sub {
    #  my @r = @rect_med;
    #  my @o = grep {
    #    $_->[1] >= $r[0] && $_->[1] <= $r[2] &&
    #    $_->[2] >= $r[1] && $_->[2] <= $r[3]
    #  } @items;
    #},
};
if ($use_dbi) {
  $benches->{si_poll_small_dbi} = sub {
    my @o = $idx_dbi->get_items_in_rect(@rect_small_off);
  };
}
if ($use_median_qtree) {
  $benches->{si_mqt_poll_small} = sub {
    my @o = $idx_mqt->get_items_in_rect(@rect_small_off);
  };
  $benches->{si_mqt_poll_med} = sub {
    my @o = $idx_mqt->get_items_in_rect(@rect_med);
  };
  if ($item_mode eq 'concentrated_random') {
    $benches->{si_mqt_poll_small_conc} = sub {
      my @o = $idx_mqt->get_items_in_rect(@rect_small);
    };
    $benches->{si_poll_small_conc} = sub {
      my @o = $idx->get_items_in_rect(@rect_small);
    };
    $benches->{qt_poll_small_conc} = sub {
      my @r = @rect_small;
      my @o = grep {
        $_->[1] >= $r[0] && $_->[1] <= $r[2] &&
        $_->[2] >= $r[1] && $_->[2] <= $r[3]
      }
      map {$items[$_]}
      @{ $qt->getEnclosedObjects(@r) };
    };
  }
}
my $res = timethese(
  -3,
  $benches
);

cmpthese($res);
