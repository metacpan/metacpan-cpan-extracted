#!/usr/bin/perl -w
#
# This is an example of using the (so far undocumented) as_graph
# method, which returns a Graph object. This can then be used to draw
# images yourself, as this simple example demonstrates. This doesn't
# work terribly well yet: for example, the edges don't quite go to the
# nodes (where the arrows should be), and it doesn't work for
# undirected graphs, but it's a proof of concept so far...

use strict;
use lib '../lib';
use GraphViz;
use Image::Imlib2;

my $font = 'maian';

my $g = GraphViz->new();

# Let's build a simple graph
$g->add_node('London');
$g->add_node('Paris', label => 'City of\nlurve');
$g->add_node('NewYork');
$g->add_node('Amsterdam');

$g->add_edge('London' => 'Paris');
$g->add_edge('London' => 'NewYork', label => 'Far');
$g->add_edge('Paris' => 'London');
$g->add_edge('Paris' => 'Amsterdam');
$g->add_edge('London' => 'Amsterdam');

my $g2 = GraphViz->new({directed => 0});

foreach my $i (1..16) {
  my $used = 0;
  $used = 1 if $i >= 2 and $i <= 4;
  foreach my $j (2..4) {
    if ($i != $j && $i % $j == 0) {
      $g2->add_edge({from => $i, to => $j});
      $used = 1;
    }
  }
  $g2->add_node({ name => $i}) if $used;
}


my $graph = $g->as_graph;

my($iw, $ih) = (162, 150);
my $image = Image::Imlib2->new($iw, $ih);
$image->add_font_path("./");
$image->load_font("$font/12");

$image->set_color(255, 127, 0, 255);

my @edges = $graph->edges;
while (@edges > 0) {
  my ($from, $to) = splice(@edges, 0, 2);
  my %attributes = $graph->get_attributes($from, $to);
  my $bezier = $attributes{bezier};
#  warn "doing edge $from -> $to...$bezier\n";
  my @points = $bezier->curve(20);

  my ($oldx, $oldy) = splice(@points, 0, 2);
  $oldx *= $iw;
  $oldy *= $ih;

  while (@points) {
    my ($x, $y) = splice(@points, 0, 2);
    $x *= $iw;
    $y *= $ih;
    $image->draw_line($oldx, $oldy, $x, $y);
    ($oldx, $oldy) = ($x, $y);
  }

  my ($firstx, $firsty) = $bezier->point(0);
  $firstx *= $iw;
  $firsty *= $ih;

  my ($lastx, $lasty) = $bezier->point(1);
  $lastx *= $iw;
  $lasty *= $ih;

  my($tox, $toy) = ($graph->get_attribute('x', $to), $graph->get_attribute('y', $to));
  $tox *= $iw;
  $toy *= $ih;

  my $firstdiff = (($tox - $firstx) ** 2) + (($toy - $firsty) ** 2);
  my $lastdiff = (($tox - $lastx) ** 2) + (($toy - $lasty) ** 2);

  my($x, $y);

  if ($firstdiff < $lastdiff) {
    ($x, $y) = ($firstx, $firsty);
  } else {
    ($x, $y) = ($lastx, $lasty);
  }

}

foreach my $v ($graph->vertices) {
  my %attributes = $graph->get_attributes($v);
  my $x = $attributes{x} * $iw;
  my $y = $attributes{y} * $ih;
  my $w = $attributes{w} * $iw;
  my $h = $attributes{h} * $ih;
  $w /= 2;
  $h /= 2;
#  warn "doing $v...($x, $y, $w, $h)\n";

#  $image->fill_ellipse($x, $y, $w, $h);
  $image->draw_ellipse($x, $y, $w, $h);

  my $size = 4;

  # Pick a good size
  foreach my $newsize (5..100) {
    $image->load_font("$font/$newsize");
    my($tw, $th) = $image->get_text_size($v);
    last if $tw > $w * 1.6;
    last if $th > $h * 1.6;
    $size = $newsize;
  }

  $image->load_font("$font/$size");
  my($tw, $th) = $image->get_text_size($v);

  $x -= $tw / 2;
  $y -= $th / 2;

  $image->draw_text($x, $y, $v);
}


# save out
$image->save('imlib.png');
