# $Id: ClassBrowser.pm,v 1.2 2003/09/30 20:49:02 clajac Exp $

package CPANXR::Apache::ClassBrowser;
use CPANXR::Parser qw(:constants);
use strict;

sub browse {
  my ($self, $r, $q) = @_;

  my $current = $q->param('p') || 1;

  my $classes = CPANXR::Database->select_connections(limit_types => [CONN_ISA]);

  my %classes = map { $_->[1] => $_->[0] } @$classes;
  my @classes = sort { lc($a) cmp lc($b) } keys %classes;

  $r->print("<blockquote>\n");
  my $table = CPANXR::Apache::Util::Table->new($r, 2, [qw(80% 20%)]);
  $table->begin;
  $table->header("<b>Class:</b>", "<b>ID:</b>");

  my $page = Data::Page->new(scalar @classes, 10, $current);
  
  for($page->splice(\@classes)) {
    my $url = qq{<a href="graph?class=$classes{$_}">$_</a>};
    $table->print($url, $classes{$_});
  }

  $table->end;
  # Write navigation
  my $base = "classes?a=1";
  CPANXR::Apache::Util->navigator($r, $page, $base);

  $r->print("</blockquote>");
}

sub graph {
  my ($self, $r, $q) = @_;

  # Fetch id of file to show
  my $class_id = $q->param('class');
  my $type = $q->param('type') || 'svg';
  my $class = CPANXR::Database->select_symbol($class_id)->[0]->[0];

  if($class) {
    $r->print("<b>Visualizing package</b>: $class as ");
    $r->print(qq{<a href="graph?class=$class_id&type=svg">SVG</a>&nbsp;|&nbsp;});
    $r->print(qq{<a href="graph?class=$class_id&type=png">PNG</a>});
    $r->print("\n<br><br>");

    $r->print("<blockquote>\n");
    if($type eq 'svg') {
      $r->print(qq{<embed border="1" src="visualize?class=$class_id&type=svg" type="image/svg-xml" pluginspace="http://www.adobe.com/svg/viewer/install/" width="640" height="480"></embed>});
    } elsif($type eq 'png') {
      $r->print(qq{<img border="1" src="visualize?class=$class_id&type=png">});
    }

    $r->print("</blockquote>\n");
  } else {
    $r->print("No such package\n");
  }
}

1;
