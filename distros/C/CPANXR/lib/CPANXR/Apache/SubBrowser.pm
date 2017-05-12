# $Id: SubBrowser.pm,v 1.1 2003/10/03 12:08:19 clajac Exp $

package CPANXR::Apache::SubBrowser;
use CPANXR::Parser qw(:constants);
use strict;

sub graph {
  my ($self, $r, $q) = @_;
  
  # Fetch sub id
  my $sub = $q->param('sub');
  my ($sub_id, $pkg_id) = split/_/,$sub,2;

  my $sub_name = CPANXR::Database->select_symbol($sub_id)->[0]->[0];
  my $package = CPANXR::Database->select_symbol($pkg_id)->[0]->[0];

  # Fetch type
  my $type = $q->param('type') || 'svg';

  if($sub_id && $pkg_id) {
    $r->print("<b>Visualizing subroutine</b>: ${package}::${sub_name} as ");
    $r->print(qq{<a href="graph?sub=${sub}&type=svg">SVG</a>&nbsp;|&nbsp;});
    $r->print(qq{<a href="graph?sub=${sub}&type=png">PNG</a>});
    $r->print("\n<br><br>");

    $r->print("<blockquote>\n");
    if($type eq 'svg') {
      $r->print(qq{<embed border="1" src="visualize?sub=${sub}&type=svg" type="image/svg-xml" pluginspace="http://www.adobe.com/svg/viewer/install/" width="640" height="480"></embed>});
    } elsif($type eq 'png') {
      $r->print(qq{<img border="1" src="visualize?sub=${sub}&type=png">});
    }

    $r->print("</blockquote>\n");
  } else {
    $r->print("No such package\n");
  }
}

1;
