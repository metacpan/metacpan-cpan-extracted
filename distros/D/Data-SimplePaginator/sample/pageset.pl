#!/usr/bin/perl -w
use Data::SimplePaginator;

$paginator->data( $paginator->data, 1..4, map { lc } A..Z, 5..8 );
my $pageset = Data::SimplePaginator->new(3, 1..$paginator->pages);
foreach my $setnum ( 1..$pageset->pages ) {
  print "pageset $setnum\n";
  foreach my $page ( $pageset->page($setnum) ) {
    print "  page $page: ". join(" ", $paginator->page($page)) . "\n";
  }
}
foreach my $setnum ( 1..$pageset->pages ) {
  print "pageset $setnum\n";
  foreach my $page ( 1..$pageset->page($setnum) ) {
    print "  page $page: ". join(" ", $paginator->page( ($pageset->page($setnum))[$page-1])) . "\n";
  }
}
