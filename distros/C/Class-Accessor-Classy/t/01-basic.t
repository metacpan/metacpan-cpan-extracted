#!/usr/bin/perl

use warnings;
use strict;

use Test::More 'no_plan';
my @exports;
BEGIN {
  eval {require Class::Accessor::Classy};
  ok(!$@);

  can_ok('Class::Accessor::Classy', 'exports');
  @exports = keys(%{{Class::Accessor::Classy->exports}});
  ok(@exports);
};

{
  package Bar;
  use Class::Accessor::Classy;
}
ok(! Bar->isa('Bar::--accessors'), 'safe to use()');

# basic usage:
{
  package Foo;
  use Class::Accessor::Classy;
  ro qw(fee fie foe);
  rw qw(foo bar baz);
  no  Class::Accessor::Classy;
}
ok(Foo->isa('Foo::--accessors'), 'isa Foo::--accessors');
can_ok('Foo',
  map({$_, 'get_' . $_} qw(fee fie foe foo bar baz)),
  map({'set_' . $_} qw(foo bar baz))
);
ok(! Foo->can("set_$_"), "do not want set_$_") for qw(fee fie foe);

# "no" is compile-time
BEGIN {ok(! Foo->can($_), "do not want $_") for(@exports)};

# later usage
{
  package Deal;
  use Class::Accessor::Classy;
  ro qw(a b c);
  rw qw(d e f);
}

ok(Deal->isa('Deal::--accessors'), 'isa Deal::--accessors');
can_ok('Deal',
  map({$_, 'get_' . $_} qw(a b c d e f)),
  map({'set_' . $_} qw(d e f))
);
ok(! Deal->can("set_$_"), "do not want set_$_") for qw(a b c);

# I didn't say "no" above"
BEGIN {ok(Deal->can($_), "still have $_") for(@exports)};

# now check unimport
{
  package Deal; 
  no Class::Accessor::Classy;
}
BEGIN {ok(! Deal->can($_), "no more $_") for(@exports)};


{
  package Deal;
  use Class::Accessor::Classy;
  rs g => \(my $set_g);
  my $set_h = rs 'h';
  my ($set_i, $set_j) = rs 'i', 'j';
  no  Class::Accessor::Classy;
  main::is($set_g, '--set_g');
  main::is($set_h, '--set_h');
  main::is($set_i, '--set_i');
  main::is($set_j, '--set_j');
}

{
  {
    package Make;
    use Class::Accessor::Classy;
    with 'new';
    ro 'q';
    rw 's';
    no  Class::Accessor::Classy;
  }
  can_ok('Make', 'new');
  can_ok('Make', 'q');
  can_ok('Make', 'get_q');
  can_ok('Make', 's');
  can_ok('Make', 'get_s');
  can_ok('Make', 'set_s');
  ok(! Make->can('set_q'), 'do not want set_q');
  my $make = Make->new(q => 5, s => 2);
  is($make->q, 5, 'getter ok');
  is($make->s, 2, 'getter ok');
  is($make->set_s(3), 3);
  is($make->s, 3,     'setter ok');
  is($make->get_s, 3, 'setter ok');
  eval {Make->new({q => 4})};
  ok($@, 'oops');
  like($@, qr/odd number/, 'message');
}
{
  {
    package Baz;
    use Class::Accessor::Classy;
    with 'new';
    ro 'q';
    ri 's';
    no  Class::Accessor::Classy;
  }
  can_ok('Baz', 'new');
  can_ok('Baz', 'q');
  can_ok('Baz', 'get_q');
  can_ok('Baz', 's');
  can_ok('Baz', 'get_s');
  can_ok('Baz', 'set_s');
  ok(! Baz->can('set_q'), 'do not want set_q');
  my $baz = Baz->new(q => 5, s => 2);
  is($baz->q, 5, 'getter ok');
  is($baz->s, 2, 'getter ok');
  eval {$baz->set_s(3)};
  my $err = $@;
  ok($err, 'slap');
  like($err, qr/is immutable/, 'message');
  is($baz->s, 2,     'immutable ok');
  is($baz->get_s, 2,     'immutable ok');
  delete($baz->{s});
  is($baz->set_s(3), 3);
  is($baz->s, 3,     'setter ok');
  is($baz->get_s, 3, 'setter ok');
}

# vi:ts=2:sw=2:et:sta
