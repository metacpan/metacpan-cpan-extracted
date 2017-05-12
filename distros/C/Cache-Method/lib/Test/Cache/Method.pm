package Test::Cache::Method;
use strict;
use warnings;
use Cache::Method;

Cache::Method->new->set('sum');

sub new {
  my $class = shift;
  bless {}, $class;
}

sub sum {
  my $class = shift;
  my $sum = 0;
  map { $sum += $_ } @_;
  sleep 1;
  return $sum;
}

1;
