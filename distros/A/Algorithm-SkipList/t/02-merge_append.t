#-*- mode: perl;-*-

package NumericNode;

# use Carp::Assert;

our @ISA = qw( Algorithm::SkipList::Node );

sub validate_key {
  my $self = shift;
#  assert( UNIVERSAL::isa($self, "Algorithm::SkipList::Node") ), if DEBUG;

  my $key = shift;
  return ($key =~ /^\-?\d+$/); # make sure key is simple natural number
}

sub key_cmp {
  my $self = shift;
#   assert( UNIVERSAL::isa($self, "Algorithm::SkipList::Node") ), if DEBUG;

  my $left  = $self->key;
  my $right = shift;

  unless (defined $left) { return -1; }

  # Numeric Comparison

  return ($left <=> $right);
}

package main;

use Test::More tests => 264;
use Algorithm::SkipList 0.73;

# We build two lists and merge them

my $f = new Algorithm::SkipList( node_class => 'NumericNode' );
ok( ref($f) eq "Algorithm::SkipList");

foreach my $i (qw( 1 3 5 7 9 )) {
  my $finger = $f->insert($i, $i);
  ok($f->find($i, $finger) == $i);   # test return of fingers from insertion
}
ok($f->size == 5);

$f->merge($f);
ok($f->size == 5);

my $g = new Algorithm::SkipList( node_class => 'NumericNode' );
ok( ref($g) eq "Algorithm::SkipList");

foreach my $i (qw( 2 4 6 8 10 )) {
  $g->insert($i, $i);
}
ok($g->size == 5);

$f->merge($g);
ok($f->size == 10);

# $f->_debug;
# $g->_debug;

foreach my $i (1..10) {
  ok($f->find($i) == $i);
}



# redefine $g

foreach my $i (qw( 2 4 6 8 10 )) {
  $g->insert($i, -$i);
}
ok($g->size == 5);

$g->merge($g);
ok($g->size == 5);

# We want to test that mergine does not overwrite original values

$g->merge($f);
ok($g->size == 10);


foreach my $i (1..10) {
  ok($g->find($i) == (($i%2)?$i:-$i) );
}


{
  my ($k,$v) = $g->least;
  ok($k == 1);
  ok($v == 1);

  ($k, $v) = $g->greatest;
  ok($k == 10);
  ok($v == -10);
}

$f->clear;
ok($f->size == 0);


$f->append($g);
ok($f->size == $g->size);

$f->clear;
ok($f->size == 0);

$f->insert(-1, -1);
$f->insert(-2, 2);

ok($f->size == 2);


$f->append($g);

ok($f->size == 2+$g->size);

foreach my $i (-2..10) {
  ok($f->find($i) == (($i%2)?$i:-$i) ), if ($i);
}

{
  my ($k1,$v1) = $g->greatest;
  my ($k2,$v2) = $f->greatest;
  ok($k1 == $k2);
  ok($v1 == $v2);
}

my $z = $f->copy;
ok($z->size == $f->size);

# if ($z->size != $f->size) {
#   $z->_debug;
#   $f->_debug;
#   $g->_debug;
#   die;
# }

foreach my $i (-2..10) {
  ok($f->find($i) == (($i%2)?$i:-$i) ), if ($i);
  ok($z->find($i) == (($i%2)?$i:-$i) ), if ($i);
}

$z->clear;
ok($z->size == 0);


$z->append( $f->copy );
ok($z->size == $f->size);

foreach my $i (-2..10) {
  ok($z->find($i) == (($i%2)?$i:-$i) ), if ($i);
}

{
  my @keys = $g->keys;
  ok(scalar @keys == $g->size);

  foreach my $i (1..10) {
    ok($i == $keys[$i-1]); }

  ok(scalar $g->first_key == shift @keys);
  while (@keys) { ok($g->next_key == shift @keys); }


  my @vals = $g->values;
  ok(scalar @vals == $g->size);

  foreach my $i (1..10) {
    ok($g->find($i) == $vals[$i-1]); }
}


{
  my $g = new Algorithm::SkipList( node_class => 'NumericNode' );

  foreach (20..29) {
    $g->insert( $_, 1+$g->size );
  }
  
  my $count = $g->size;
  foreach my $key (20..29) {
    ok( defined $g->find($key), "verify key in g" );
    my $h = $g->copy( $key );
    ok( defined $h,           "verify h is defined" );

    ok( $h->size == $count,   "verify size of h" );
    ok( ($h->least)[0] == $key );
    ok( ($h->least)[1] == $g->find($key) );

    if ($key <= 28) {
      my $h = $g->copy( $key, undef, 28 );
      ok( defined $h, "verify h is defined" );

      ok( $h->size == ($count-1), "verify size of h" );
      ok( ($h->least)[0] == $key );
      ok( ($h->least)[1] == $g->find($key) );
    }

    $count--;
  }


  my $h = $g->copy(19);
  ok(! defined $h);

  $h = $g->copy(30);
  ok(! defined $h);
}

{
  foreach my $i (20..29) {
    my $g = new Algorithm::SkipList( node_class => 'NumericNode' );

    foreach (20..29) {
      $g->insert( $_, 1+$g->size );
    }

    my $size = $g->size;

    my $h = $g->truncate($i);
    ok(defined $h);
    ok($size == ($h->size + $g->size));

    my $gn = $g->_greatest_node;
    my $hn = $h->_first_node;

    ok( $hn->key_cmp($i) == 0 ), if ($h->size);

    unless ($gn->isa("Algorithm::SkipList::Header")) {
      ok( $hn->key_cmp($gn->key) == 1 ), if ($gn->key);
    }

    unless ($hn->isa("Algorithm::SkipList::Header")) {
      ok( $gn->key_cmp($hn->key) == -1 ), if ($hn->key);
    }
  }
  
}
