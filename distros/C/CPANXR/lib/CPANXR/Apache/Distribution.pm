# $Id: Distribution.pm,v 1.11 2003/10/07 19:38:30 clajac Exp $

package CPANXR::Apache::Distribution;
use CPANXR::Database;
use CPANXR::Config;
use CPANXR::Apache::Util;
use File::Spec::Functions qw(catdir abs2rel);
use File::Find::Rule;
use Data::Page;
use strict;

sub find {
  my ($self, $r, $q) = @_;

  my %args;
  my $by_prefix = $q->param('c') || 'A';
  my $current = $q->param('p') || 1;
  
  $args{by_name} = $by_prefix . "%";

  my $result = CPANXR::Database->select_distributions(%args);
  
  for('A'..'Z') {
    $r->print("<a href=\"dists?c=$_\">");
    if($by_prefix eq $_) {
      $r->print("<b><font size=\"+1\">$_</font></b>");
    } else {
      $r->print($_);
    }
    $r->print("</a>&nbsp;\n");
  }

  my $page = Data::Page->new(scalar @$result, 10, $current);

  $r->print("<blockquote>\n");

  if(@$result) {
    $r->print("Found <b>" . $page->total_entries . "</b> distributions, ");
    $r->print("showing <b>" . $page->first . "</b> to <b>" . $page->last . "</b><br><br>\n");

    my $table = CPANXR::Apache::Util::Table->new($r, 1);
    $table->begin;
    $table->header("<b>Name:</b>");
    for($page->splice($result)) {
      my $name = $_->[1];
      $name =~ s/-[0-9_\.]+$//;
      $table->print("<a href=\"list?id=$_->[0]\">$name</a><br>\n");
    }
    
    $table->end;
    
    my $base = "dists?c=$by_prefix";
    CPANXR::Apache::Util->navigator($r, $page, $base);
  } else {
    $r->print("No distributions starting with <b>$by_prefix</b>\n");
  }

  $r->print("</blockquote>\n");
}

sub list {
  my ($self, $r, $q) = @_;

  my $id = $q->param('id');
  my $name = $q->param('name');
  my $show = $q->param('hide') || 0;
  
  my %args;
  $args{id} = $id if($id =~ /^\d+$/);
  $args{by_name} = "$name\%" if($name && !exists $args{id});

  # Select name from database
  my $result = CPANXR::Database->select_distributions(%args);
  
  if(@$result) {
    # Fetch files related to this dist that are cross-indexed
    my $db_files = CPANXR::Database->select_files(dist_id => $result->[0]->[0]);

    $r->print("<b>Contents of:</b> $result->[0]->[1]<br>");

    $r->print("<blockquote>\n");
    
    my $dist_root = CPANXR::Config->get("XrRoot");

    my $path = catdir($dist_root, $result->[0]->[1]);

    my @files = File::Find::Rule->file()->in($path);

    my %files;
    foreach(@$db_files) {
      $files{$_->[2]} = [$_->[0], $_->[4]];
    }
    
    my $table = CPANXR::Apache::Util::Table->new($r, 2, [qw(90% 10%)]); 
    $table->begin;
    $table->header("<b>Path:</b>", "<b>LOC:</b>");
    
    foreach my $file (@files) {
      $file = abs2rel($file, $dist_root);
      
      if(exists $files{$file}) {
	my $link = "<a href=\"show?id=" . $files{$file}->[0] . "\">" . $file . "</a>";
	$table->print($link, $files{$file}->[1]);
      } elsif($show) {
	$table->print("<font color=\"#666666\">" . $file . "</font>", "");
      }
    }
    
    $table->end;

    $r->print("</blockquote>\n");

    if($show) {
      $r->print("<i><a href=\"list?id=$id&hide=0\">Hide non-indexed files</a></i>");
    } else {
      $r->print("<i><a href=\"list?id=$id&hide=1\">Show all files</a></i>");
    }

    $r->print("<br>\n");


  }

}

1;
