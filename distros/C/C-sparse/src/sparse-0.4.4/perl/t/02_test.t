#!/usr/bin/perl -w
use C::sparse qw(:all);
use Test::More tests => 2;

my $s0 = C::sparse::sparse("t/test_ptrs.c");

my @typedefs = $s0->symbols($typ = (C::sparse::NS_STRUCT));
my $idx = 0;
print("typ: $typ\n");
foreach my $t (@typedefs) {
  my $struct = $t->totype;
  my $p0 = $t->position;
  my $p1 = $t->endpos;
  
  print ($idx.":".$struct->n.":".$struct."\n");
  print ("unfolded:".join(",",$p0->list($p1))."\n");
  print ("unfolded:".join(",",$p0->fold($p1))."\n");
  
  foreach my $l ($struct->l) {
      my @p = $l->p;
      print (' ' x scalar(@p));
      print (" l:".$l->n.":".$l.":".$l->typename."\n");
  }
  
  $idx++;
}



ok( 1 );
ok( 1 );



