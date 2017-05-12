# $Id: Util.pm,v 1.2 2003/09/28 08:09:31 clajac Exp $

package CPANXR::Apache::Util;
use strict;

sub navigator {
  my ($pkg, $r, $page, $base) = @_;

  $r->print("<p><center>");

  if($page->previous_page) {
    $r->print("<a href=\"");
    $r->print($base);
    $r->print("&p=");
    $r->print($page->previous_page);
    $r->print("\">&lt;&lt;</a>&nbsp;")
  }
    
  for(1..$page->last_page) {
    $r->print("<a href=\"");
    $r->print($base);
    $r->print("&p=" . $_ . "\">");

    if($_ == $page->current_page) {
      $r->print("<font size=\"+1\">" . $_ . "</font>");
    } else {
      $r->print($_);
    }

    $r->print("</a>&nbsp;");
  }
    
  if($page->next_page) {
    $r->print("<a href=\"");
    $r->print($base);
    $r->print("&p=");
    $r->print($page->next_page);
    $r->print("\">&gt;&gt;</a>");
  }

  $r->print("</center>");
}

package CPANXR::Apache::Util::Table;

our @Colors = qw(eeeeee ffffff);

sub new {
  my ($pkg, $r, $columns, $width) = @_;
  $pkg = ref $pkg || $pkg;

  unless(ref $width eq 'ARRAY') {
    my $cw = int(100/$columns);
    @$width = map { $cw } 0..($columns - 1);
    $width->[-1] += (100 - $cw * $columns) unless($cw * $columns == 100);
    @$width = map { $_ . "%" } @$width;
  }

  return bless { r => $r,
		 columns => $columns,
		 row_num => 0,
		 width => $width }, $pkg;
}

sub begin {
  my $self = shift;
  $self->{r}->print("<table cellpadding=\"2\" cellspacing=\"0\" width=\"100%\">\n");
  1;
}

sub print {
  my ($self, @data) = @_;
  my $color = $self->{row_num} & 1;
  $self->{r}->print("<tr bgcolor=\"#$Colors[$color]\">");
  for(0..($self->{columns} - 1)) {
    $self->{r}->print("<td width=\"$self->{width}->[$_]\">");
    $self->{r}->print($data[$_] ? $data[$_] : "");
    $self->{r}->print("</td>");
  }
  $self->{r}->print("</tr>");
  $self->{row_num}++;
  1;
}

sub header {
  my ($self, @data) = @_;
  $self->{r}->print("<tr bgcolor=\"#dddddd\">");
  for(0..($self->{columns} - 1)) {
    $self->{r}->print("<td>");
    $self->{r}->print($data[$_] ? $data[$_] : "");
    $self->{r}->print("</td>");
  }
  $self->{r}->print("</tr>");
  $self->{row_num} = 1;
  1;
}
sub end {
  my $self = shift;
  $self->{r}->print("</table>");
}

1;
