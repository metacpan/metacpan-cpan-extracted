#!perl -T

use strict;
use Test::More tests => 9;
use Chorus::Frame;
use Chorus::Collection::Filter qw($FILTER @_VFILTER);

diag("Testing Chorus::Collection::Filter $Chorus::Collection::Filter::VERSION, Perl $], $^X");

# node_test : retourne le label lbl d'un item
my $node_test = sub { my $item = shift; $item->{lbl} };

sub make_filter {
  my $f = Chorus::Frame->new(_ISA => $FILTER);
  $f->set_node_test($node_test);
  return $f;
}

sub make_items { map { Chorus::Frame->new(lbl => $_) } @_ }

# Test 1 : set_filter() découpe le motif en noeuds
{
  my $f = make_filter();
  $f->set_filter("a b c");
  is($f->length, 3, 'Test 1 - set_filter() creates one node per token');
}

# Test 2 : check() réussit sur une séquence correspondante
{
  my $f = make_filter();
  $f->set_filter("a b c");
  ok($f->check(make_items(qw(a b c))), 'Test 2 - check() matches exact sequence');
}

# Test 3 : check() échoue sur une séquence non correspondante
{
  my $f = make_filter();
  $f->set_filter("a x c");
  ok(!$f->check(make_items(qw(a b c))), 'Test 3 - check() rejects non-matching sequence');
}

# Test 4 : wildcard . correspond à n'importe quel élément
{
  my $f = make_filter();
  $f->set_filter("a . c");
  ok($f->check(make_items(qw(a b c))), 'Test 4 - wildcard (.) matches any item');
}

# Test 5 : négation !b refuse un élément interdit
{
  my $f = make_filter();
  $f->set_filter("a !b c");
  ok(!$f->check(make_items(qw(a b c))), 'Test 5 - negation (!b) rejects forbidden item');
}

# Test 6 : opérateur OR [a b] correspond à l'un ou l'autre
{
  my $f = make_filter();
  $f->set_filter("[a b] [b c]");
  ok($f->check(make_items(qw(b c))), 'Test 6 - OR operator ([a b]) matches either token');
}

# Test 7 : quantificateur + correspond à une ou plusieurs occurrences
{
  my $f = make_filter();
  $f->set_filter("a+");
  ok($f->check(make_items(qw(a a a))), 'Test 7 - quantifier (+) matches one or more');
}

# Test 8 : capture de variables (b+) dans a b b c
{
  my $f = make_filter();
  $f->set_filter("a (b+) c");
  my @seq = make_items(qw(a b b c));
  ok($f->check(@seq), 'Test 8 - capture group (b+) matches');
  is_deeply(
    [ map { $_->{lbl} } @{$_VFILTER[0]} ],
    ['b', 'b'],
    'Test 8b - captured variable contains matched items'
  );
}

done_testing();
