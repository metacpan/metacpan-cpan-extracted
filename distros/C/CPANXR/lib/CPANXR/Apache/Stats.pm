# $Id: Stats.pm,v 1.3 2003/09/28 08:09:31 clajac Exp $

package CPANXR::Apache::Stats;
use CPANXR::Database;
use strict;

sub stats {
  my ($self, $r, $q) = @_;

  my $Dbh = CPANXR::Database->connection();

  $r->print("<b>Statistics</b><br>\n");
  $r->print("<blockquote>\n");
  # Get indexed files
  {
    my @types = (".xs", ".pm");

    my $result = $Dbh->selectall_arrayref("SELECT type, count(*), sum(loc) FROM files GROUP BY type");
    $r->print("<b>File information:</b><br>\n");
    $r->print("<pre>\n");

    my $sum = 0;
    my $loc = 0;

    $r->print("Type        Count        LOC\n");
    $r->print(("-" x 28) . "\n");
    foreach(@$result) {
      $r->print(sprintf("%s      % 8d   % 8d\n", $types[$_->[0] - 1], $_->[1], $_->[2]));
      $sum += $_->[1];
      $loc += $_->[2];
    }
    $r->print(("-" x 28) . "\n");
    $r->print(sprintf("Sum:     % 8d   % 8d\n", $sum, $loc));
    $r->print("</pre><br><br>\n");
  }

  # Symbols and connections
  {
    $r->print("<b>Reference information:</b><br>\n");
    $r->print("<pre>\n");
    
    $r->print("Type                   Count\n");
    $r->print(("-" x 28) . "\n");

    {
      my $decl = $Dbh->selectall_arrayref("SELECT count(*) FROM declarations");
      my $sym  = $Dbh->selectall_arrayref("SELECT count(id) FROM symbols");
      my $pkg  = $Dbh->selectall_arrayref("SELECT count(distinct symbol_id) FROM packages");
      my $conn = $Dbh->selectall_arrayref("SELECT count(*) FROM connections");
      $r->print(sprintf("Barewords           % 8d\n", $sym->[0]->[0]));
      $r->print(sprintf("Packages            % 8d\n", $pkg->[0]->[0]));
      $r->print(sprintf("Declarations        % 8d\n", $decl->[0]->[0]));
      $r->print(sprintf("Connections         % 8d\n", $conn->[0]->[0]));
    }
  }
}

1;
