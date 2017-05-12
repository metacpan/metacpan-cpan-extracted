package One;
use strict;
use warnings;
sub new {
  my($class,%args) = @_;
  my $self = bless({},$class);
  %{$self} = %args;
  return $self;
}
sub val {
  my ($self, $val) = @_;
  $self->{val} = $val if defined $val;
  return $self->{val};
}
package Two;
use strict;
use warnings;
use base qw(One);

package main;

use strict;
use warnings;
use Test::More tests => 18;
use Data::Predicate::Predicates qw(:all);

{
  my $p = p_and( p_defined(), p_is_number());
  ok($p->apply(1), 'Checking the predicate understands a number');
  ok(!$p->apply('hello'), 'Checking the predicate understands a string');
  ok(!$p->apply(undef), 'Checking the predicate understands an undefined number');
}

ok(p_undef()->apply(undef), 'Checking undef');
ok(!p_undef()->apply(''), 'Checking giving undef a def');

ok(p_always_true()->apply(), 'Checking always true');
ok(p_not(p_always_false())->apply(), 'Checking reverse of always false is true');

ok(!p_always_false()->apply(), 'Checking always false');
ok(!p_not(p_always_true())->apply(), 'Checking reverse of always true is false');

ok(p_ref_type('ARRAY')->apply([]), 'Checking is_ref_type is okay for arrays');

ok(p_isa('One')->apply(Two->new()), 'Checking our Object inherits correctly using isa');
ok(!p_isa('EGUtils')->apply([]), 'Checking our isa predicate does not evaluate an unblessed ref');
ok(!p_isa('EGUtils')->apply(undef), 'Checking our isa predicate does not evaluate an undef');

{
  #Or code
  my $p_or = p_or(p_is_number(), p_ref_type('ARRAY'));
  ok($p_or->apply(1), 'Checks out in or as a number');
  ok($p_or->apply([]), 'Checks out in or as an ARRAY');
  ok(!$p_or->apply(undef), 'Fail because value is undef');
  ok(!$p_or->apply(''), 'Fail because value is a String');
  ok(!$p_or->apply({}), 'Fail because value is a HashRef');
}