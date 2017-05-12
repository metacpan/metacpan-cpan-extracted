#-*- mode: perl;-*-

package IntegerNode;

require Algorithm::SkipList::Node;

our @ISA = qw( Algorithm::SkipList::Node );

sub key_cmp {
  my ($self, $right) = @_;
  my $left  = $self->key;

  unless (defined $left) { return -1; }

  return ($left <=> $right);
}

package main;

use Test::More tests => 73;

use_ok("Algorithm::SkipList");

for my $i (-1..1) {
  $n = new IntegerNode($i, 10-$i);
  ok($n->isa("IntegerNode"));
  ok($n->isa("Algorithm::SkipList::Node"));

  ok($n->key == $i);
  ok($n->key_cmp($i) == 0,    "key_cmp(i)");
  ok($n->key_cmp($i+1) == -1, "key_cmp(i+1)");
  ok($n->key_cmp($i-1) == 1,  "key_cmp(i-1)");

  ok(IntegerNode->new($i)->key_cmp($i) == 0, "Node->new(i)->key_cmp(i)");

  ok($n->key($i+1) != $i+1,   "read-only key");

  ok($n->value == 10-$i);
  ok($i == $n->value($i));
  ok($n->value == $i);

  my $hdr = $n->header;
  ok( ref($hdr) eq 'ARRAY' );
  ok( !$n->level );
}


sub succ {
  my $char  = shift;
  unless (length($char)==1) {
    die "only a signle character is acceptable";
  }
  my $count = shift;
  unless (defined $count) {
    $count =1;
  }
  return pack "C", (unpack "C", $char)+$count;
}

sub pred {
  my $char  = shift;
  unless (length($char)==1) {
    die "only a single character is acceptable";
  }
  my $count = shift;
  unless (defined $count) {
    $count =1;
  }
  return pack "C", (unpack "C", $char)-$count;
}


my $c = 0;
for my $i ('A'..'C') {
  $n = new Algorithm::SkipList::Node($i, ++$c);
  ok($n->isa("Algorithm::SkipList::Node"));

  ok($n->key eq $i);
  ok($n->key_cmp($i) == 0,    "key_cmp(i)");
  ok($n->key_cmp(succ($i)) == -1, "key_cmp(i+1)");
  ok($n->key_cmp(pred($i)) == 1,  "key_cmp(i-1)");

  ok($n->key(succ($i)) ne succ($i),   "read-only key");

  ok($n->value == $c);
  ok($i eq $n->value($i));
  ok($n->value eq $i);

  my $hdr = $n->header;
  ok( ref($hdr) eq 'ARRAY' );
  ok( !$n->level );
}

