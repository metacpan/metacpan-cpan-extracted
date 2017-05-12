{
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
    return $self->{val} || 'hello';
  }
  package Tmp;
  sub new { return bless([], 'Tmp');}
  sub val { my ($self) = @_; return $self->[0]; }
}

package main;

use strict;
use warnings;
use Test::More tests => 8;

use Data::Predicate::Predicates qw(:all);

my $p = p_can('val');

my $str = 'str';
ok(! $p->apply(undef), 'Cannot call can() on an undef value');
ok(! $p->apply($str), 'Cannot call can() on a Scalar');
ok(! $p->apply(\$str), 'Cannot call can() on a ScalarRef');
ok(! $p->apply([]), 'Cannot call can() on a ArrayRef');
ok(! $p->apply({}), 'Cannot call can() on a HashRef');

ok(! p_can('another')->apply(One->new()), 'Method another() is not defined for object One therefore should not respond to it');

ok($p->apply(One->new()), 'Object One has a method val() & can respond');
ok($p->apply(Tmp->new()), 'Object Tmp is a blessed array but has a method val() & can respond');