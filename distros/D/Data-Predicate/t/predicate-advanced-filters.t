package One;
use strict;
use warnings;
sub new {
  my ($class) = @_;
  return bless({}, $class);
}

package main;

use strict;
use warnings;
use Data::Predicate::Predicates qw(:all);

use Test::More tests => 6;

my $p = p_and( p_defined(), p_is_number());

my @list = ('a', 1, 'b', undef, 2, 3, One->new());
my $numbers = $p->filter(\@list);
is_deeply($numbers, [1,2,3], 'Checking the filter system works');

$numbers = $p->filter_transform(\@list, sub { return $_[0]*2 });
is_deeply($numbers, [2,4,6], 'Checking the filter transform system works');

ok(!$p->all_true(\@list), 'All items in array are not true');
ok(!$p->all_false(\@list), 'All items in array are not false');

ok($p->all_true([1,2,3,4,5]), 'All items in array are true');
ok($p->all_false([undef, 'a', One->new(), [], {}]), 'All items in array are false');
