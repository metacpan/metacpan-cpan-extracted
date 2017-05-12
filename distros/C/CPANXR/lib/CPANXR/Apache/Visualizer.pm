# $Id: Visualizer.pm,v 1.6 2003/10/03 12:01:13 clajac Exp $

package CPANXR::Apache::Visualizer;
use CPANXR::Visualize::Graph;
use CPANXR::Apache::File;
use CPANXR::Apache::ClassBrowser;
use CPANXR::Apache::SubBrowser;
use strict;

sub graph {
  my ($self, $r, $q) = @_;

  if($q->param('file')) {
    CPANXR::Apache::File->graph($r, $q);
  } elsif($q->param('class')) {
    CPANXR::Apache::ClassBrowser->graph($r, $q);
  } elsif($q->param('sub')) {
    CPANXR::Apache::SubBrowser->graph($r, $q);
  }
}

sub visualize {
  my ($self, $r, $q) = @_;

  my $file = $q->param('file') || 0;
  my $class = $q->param('class') || 0;
  my $sub = $q->param('sub') || 0;

  my $type = $q->param('type') || 'svg';

  my $graph = undef;

  if($file) {
    $graph = CPANXR::Visualize::Graph->file($file);
  } elsif($class) {
    $graph = CPANXR::Visualize::Graph->class($class);
  } elsif($sub) {
    $graph = CPANXR::Visualize::Graph->subroutine($sub);
  } else {
    $graph = CPANXR::Visualize::Graph->none();
  }
 
  if($graph) {
    if($type eq 'svg') {
      $r->send_http_header("image/svg-xml");
      $r->print($graph->as_svg);
    } elsif($type eq 'png') {
      $r->send_http_header("image/png");
      print STDERR "Exporting as png\n";
      $r->print($graph->as_png);
    }
  }
}

1;
