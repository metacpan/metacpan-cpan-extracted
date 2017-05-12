#!/usr/bin/perl

use warnings;
use strict;

use Test::More 'no_plan';
my @exports;
BEGIN {
  eval {require Class::Accessor::Classy};
  ok(!$@);
};

{
  {
    package Foo;
    use Class::Accessor::Classy;
    with 'new';
    lo 'things';
    no  Class::Accessor::Classy;
  }
  ok(Foo->isa('Foo::--accessors'), 'isa Foo::--accessors');
  can_ok('Foo', 'things');
  my $foo = Foo->new(things => [qw(a b c)]);
  is_deeply([$foo->things], [qw(a b c)]);
}

{
  {
    package Deal;
    use Class::Accessor::Classy;
    with 'new';
    lw 'these';
    no  Class::Accessor::Classy;
  }
  can_ok('Deal',
    'these', map({$_ . '_these'} qw(set add)),
  );
  my $deal = Deal->new;
  eval{$deal->add_these('foo')};
  my $err = $@;
  ok($err, 'slap');
  like($err, qr/list is empty/) or die $err;
  $deal->set_these();
  is(scalar($deal->these), 0);
  ok($deal->add_these('foo'));
  is(scalar($deal->these), 1);
  is($deal->add_these(qw(bar baz)), 3);
  is_deeply([$deal->these], [qw(foo bar baz)]);
  is(scalar($deal->set_these(qw(baz bar foo))), 3);
  is_deeply([$deal->these], [qw(baz bar foo)]);
}

{
  my ($set_g, $set_h, $add_h);
  {
    package This;
    use Class::Accessor::Classy;
    with 'new';
    ls g => \$set_g;
    ls h => \$set_h, add => \$add_h;
    no  Class::Accessor::Classy;
  }
  is($set_g, '--set_g');
  is($set_h, '--set_h');
  is($add_h, '--add_h');
  my $this = This->new;
  eval{$this->$add_h('foo')};
  my $err = $@;
  ok($err, 'slap');
  like($err, qr/list is empty/) or die $err;

  is(scalar($this->$set_g(qw(foo bar baz))), 3);
  is(scalar($this->$set_h(qw(bop boo bot))), 3);
  is_deeply([$this->g], [qw(foo bar baz)]);
  is_deeply([$this->h], [qw(bop boo bot)]);
}

# vi:ts=2:sw=2:et:sta
