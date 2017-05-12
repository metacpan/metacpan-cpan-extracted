# $Id: File.pm,v 1.19 2003/10/07 19:38:30 clajac Exp $

package CPANXR::Apache::File;
use CPANXR::Config;
use IO::File;
use File::Spec::Functions qw(rel2abs catdir catfile);

use strict;

sub show {
  my ($self, $r, $q) = @_;

  my $v = \&Foo'bar::cat;

  # Fetch id of file to show
  my $file_id = $q->param('id');
  my $files = CPANXR::Database->select_files(file_id => $file_id);

  if(@$files) {
    my $id = $files->[0]->[0];
    my $file_rel_path = $files->[0]->[2];
    my $dist_root = CPANXR::Config->get("XrRoot");
    my $file_abs_path = rel2abs($file_rel_path, $dist_root);

    $self->cat($r, $q, $file_abs_path, $file_rel_path,  $id);
  } else {
    $r->print("Can't find file\n");
  }
}

sub cat {
  my ($self, $r, $q, $path, $show_path, $file_id) = @_;

  my $hl = $q->param('hl');
  $hl = $hl =~ /^\d+$/ ? $hl : -1;

  my $hide_pod = $q->param('pod') || 0;
  my $connections = CPANXR::Database->select_connections(file_id => $file_id);

  my %lines;
  for(@$connections) {
    my ($symbol_id, $symbol, $line_no, $offset, $path, $file_id, $pkg_id) = @$_;

    $lines{$line_no} = [] unless(exists $lines{$line_no});
    push @{$lines{$line_no}}, [$symbol_id, $symbol, $offset, $pkg_id];
  }
  

  my $io = IO::File->new($path, "r") || return;

  $r->print("<b>Showing:</b> ");
  $r->print($show_path);
  $r->print("<br><br>\n");
  $r->print("<a href=\"graph?file=$file_id\">Visualize</a>&nbsp;&nbsp;|&nbsp;&nbsp;");

  $r->print("<a href=\"show?id=$file_id&pod=@{[!$hide_pod]}");
  if($hl >= 0) {
    $r->print("&hl=$hl#l$hl");
  }

  $r->print("\"><i>" . ($hide_pod ? "Show" : "Hide") . " POD sections</i></a><br>");
  
  $r->print("<pre>\n");

  my $line_no = 1;

  while(defined(my $line = <$io>)) {
    next if($hide_pod && $line =~ /^\=\w+/ .. $line =~ /^\=cut/);

    if(exists $lines{$line_no}) {
      my $offset = 0;
      for my $replace (sort { $a->[2] <=> $b->[2] } @{$lines{$line_no}}) {
	my $width = "<a href=\"find?symbol=$replace->[0]";
	$width .= "&pkg=$replace->[3]" if($replace->[3]);
	$width .= "\" class=\"sym\">$replace->[1]</a>";
	my $pos = $replace->[2] + $offset;
	substr($line, $pos, length($replace->[1])) = $width;
	$offset += length($width) - length($replace->[1]);
      }
    }

    # Fix bad stuff
    $line =~ s/</&lt;/g;
    $line =~ s/>/&gt;/g;
    $line =~ s/\&lt;(a href=\"find\?.*?\" class=\"sym\")\&gt;/<$1>/g;
    $line =~ s/\&lt;\/a\&gt;/<\/a>/g;

    
    my $pre = sprintf("<a name=\"l%s\"<i>% 6d:</i></a> ", $line_no, $line_no);
    chomp $line;

    if($hl == $line_no) {
      $r->print($pre);
      $r->print("<span style=\"background-color: #ccccff; font-weight: bold;\">");
      $r->print($line);
      $r->print("</span>\n");
    } else {
      $r->print($pre);
      $r->print($line);
      $r->print("\n");
      }
    

  } continue {
    $line_no++;
  }
  
  $r->print("</pre>");
    
  $io->close;
}

sub graph {
  my ($self, $r, $q) = @_;

  # Fetch id of file to show
  my $file_id = $q->param('file');
  my $type = $q->param('type') || 'svg';
  my $files = CPANXR::Database->select_files(file_id => $file_id);

  if(@$files) {
    my $path = $files->[0]->[2];
    $r->print("<b>Visualizing file</b>: $path as ");
    $r->print(qq{<a href="graph?file=$file_id&type=svg">SVG</a>&nbsp;|&nbsp;});
    $r->print(qq{<a href="graph?file=$file_id&type=png">PNG</a>});
    $r->print("\n<br><br>");

    if($type eq 'svg') {
      $r->print("Click on a edge label to switch to source mode.<br>\n");
    }

    $r->print("<blockquote>\n");
    if($type eq 'svg') {
      $r->print(qq{<embed border="1" src="visualize?file=$file_id&type=svg" type="image/svg-xml" pluginspace="http://www.adobe.com/svg/viewer/install/" width="640" height="480"></embed>});
    } elsif($type eq 'png') {
      $r->print(qq{<img border="1" src="visualize?file=$file_id&type=png">});
    }

    $r->print("</blockquote>\n");
  } else {
    $r->print("No such file\n");
  }
}

1;
