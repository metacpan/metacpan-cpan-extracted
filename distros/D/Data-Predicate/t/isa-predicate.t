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
    return $self->{val};
  }
  package Two;
  use strict;
  use warnings;
  use base qw(One);
  package Tmp;
  sub new { return bless([], 'Tmp');}
  sub val { my ($self) = @_; return $self->[0]; }
}

package main;

use strict;
use warnings;
use Test::More tests => 8;

use Data::Predicate::Predicates qw(:all);

my $p = p_isa('One');

my $str = 'str';
ok(! $p->apply(undef), 'Cannot call isa() on an undef value');
ok(! $p->apply($str), 'Cannot call isa() on a Scalar');
ok(! $p->apply(\$str), 'Cannot call isa() on a ScalarRef');
ok(! $p->apply([]), 'Cannot call isa() on a ArrayRef');
ok(! $p->apply({}), 'Cannot call isa() on a HashRef');

ok($p->apply(One->new()), 'Object One isa One');
ok($p->apply(Two->new()), 'Object Two isa One');
ok(!$p->apply(Tmp->new()), 'Object Tmp is blessed but is not a One');