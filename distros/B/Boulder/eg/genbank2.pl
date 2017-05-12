#!/usr/local/bin/perl

# This requires LWP to be installed.
use lib '.','..';

use Boulder::Genbank;
$gb = new Boulder::Genbank(-accessor=>'Entrez',-param=>[qw/M57939/]);

while (my $s = $gb->get) {
  print "<HTML><HEAD><TITLE>Test document</TITLE></HEAD><BODY><H1><Test document</H1>\n";
  print $s->asHTML(\&wrap_long_lines);
  print "</BODY></HTML>\n";
}

sub wrap_long_lines {
  my ($tag,$value) = @_;
  if ($tag =~ /Sequence|Translation/) {
    $value=~s/(.{10})/$1 /g;
    $value = "<TT>$value</TT>";
  }
  return ("<B>$tag</B>",qq{<FONT COLOR="blue">$value</FONT>});
}
