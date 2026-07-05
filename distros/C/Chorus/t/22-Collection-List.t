#!perl -T

use strict;
use Test::More tests => 15;
use Chorus::Frame;
use Chorus::Collection::List qw($LIST);

diag("Testing Chorus::Collection::List $Chorus::Collection::List::VERSION, Perl $], $^X");

sub make_list  { Chorus::Frame->new(_ISA => $LIST) }
sub make_items { map { Chorus::Frame->new() } 1 .. shift }

# Test 1 : build() initialise _ITEMS avec les éléments fournis
{
  my $list = make_list();
  my @items = make_items(3);
  $list->build(@items);
  is($list->length, 3, 'Test 1 - build() sets length');
}

# Test 2 : build() fixe le container sur chaque élément
{
  my $list = make_list();
  my ($a) = make_items(1);
  $list->build($a);
  is($a->_CONTAINER, $list, 'Test 2 - build() sets _CONTAINER on items');
}

# Test 3 : first_item() retourne le premier élément
{
  my $list = make_list();
  my @items = make_items(3);
  $list->build(@items);
  is($list->first_item, $items[0], 'Test 3 - first_item() returns first element');
}

# Test 4 : last_item() retourne le dernier élément
{
  my $list = make_list();
  my @items = make_items(3);
  $list->build(@items);
  is($list->last_item, $items[2], 'Test 4 - last_item() returns last element');
}

# Test 5 : push_items() ajoute des éléments à droite
{
  my $list = make_list();
  my @items = make_items(2);
  $list->build();
  $list->push_items(@items);
  is($list->length, 2, 'Test 5 - push_items() increases length');
  is($list->last_item, $items[1], 'Test 5b - push_items() appends at right');
}

# Test 6 : unshift_items() ajoute des éléments à gauche
{
  my $list = make_list();
  my ($a, $b) = make_items(2);
  $list->build($b);
  $list->unshift_items($a);
  is($list->first_item, $a, 'Test 6 - unshift_items() prepends at left');
}

# Test 7 : merge_left() déplace les éléments d'une liste à gauche + vide la source
{
  my ($l1, $l2) = (make_list(), make_list());
  my ($a, $b, $c) = make_items(3);
  $l1->build($b, $c);
  $l2->build($a);
  $l1->merge_left($l2);
  is($l1->length, 3,          'Test 7 - merge_left() grows target');
  is($l1->first_item, $a,     'Test 7b - merge_left() prepends source items');
  is($l2->length, 0,          'Test 7c - merge_left() empties source list');
  is($a->_CONTAINER, $l1,     'Test 7d - merge_left() updates container of moved items');
}

# Test 8 : merge_right() déplace les éléments d'une liste à droite + vide la source
{
  my ($l1, $l2) = (make_list(), make_list());
  my ($a, $b) = make_items(2);
  $l1->build($a);
  $l2->build($b);
  $l1->merge_right($l2);
  is($l1->last_item, $b, 'Test 8 - merge_right() appends source items');
  is($l2->length, 0,     'Test 8b - merge_right() empties source list');
}

# Test 9 : connect_left() établit le double chainage prev/succ
{
  my ($a, $b) = map { Chorus::Frame->new(_ISA => $LIST) } 1..2;
  $b->connect_left($a);
  is($b->prev, $a, 'Test 9 - connect_left() sets prev on self');
  is($a->succ, $b, 'Test 9b - connect_left() sets succ on target');
}

done_testing();
