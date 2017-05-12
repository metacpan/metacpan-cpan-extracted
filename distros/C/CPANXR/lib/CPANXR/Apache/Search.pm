# $Id: Search.pm,v 1.7 2003/10/04 10:22:08 clajac Exp $

package CPANXR::Apache::Search;
use CPANXR::Apache::Util;
use CPANXR::Database;
use Data::Page;
use strict;

sub search {
  my ($self, $r, $q) = @_;

  my $symbol = $q->param('symbol');
  my $case = $q->param('casing');
  my $current = $q->param('p') || 1;

  unless($symbol) {
    $r->print("Empty <b>symbol</b>");
    return;
  }

  unless($symbol =~ /^[A-Za-z_][A-Za-z0-9_]*(?:(?:\:\:|\')[A-Za-z0-9_]*)*$/) {
    $r->print("Symbol <b>$symbol</b> is invalid");
    return;
  }

  my $result = CPANXR::Database->select_symbol_by_name($symbol . "%", $case);
  unless(@$result) {
    $r->print("Sorry, I can't find <b>$symbol</b>");
    return;
  }
  
  $r->print("Looking for <b>$symbol</b> and found:<br>");
  $r->print("<blockquote>\n");

  my $table = CPANXR::Apache::Util::Table->new($r, 2, [qw(80% 20%)]);
  $table->begin;
  $table->header("<b>Symbol:</b>", "<b>ID:</b>");

  my $page = Data::Page->new(scalar @$result, 10, $current);
  
  for($page->splice($result)) {
    my $url = qq{<a href="find?symbol=$_->[0]">$_->[1]</a>};
    $table->print($url, $_->[0]);
  }

  $table->end;

  # Write navigation
  my $base = "search?symbol=$symbol&casing=$case";

  CPANXR::Apache::Util->navigator($r, $page, $base);
  $r->print("</blockquote>");
}

1;
