#!/usr/bin/perl

use warnings;
use strict;

use Test::More 'no_plan';

{
  my %didget;
  my %didset;
  {
    package Foo;
    use Class::Accessor::Classy;
    with 'new';
    getter {
      my $self = shift;
      my ($k) = @_;
      $didget{$k} ||= 0;
      $didget{$k}++;
      return($self->{$k});
    };
    setter {
      my $self = shift;
      my ($k, $v) = @_;
      $didset{$k} ||= 0;
      $didset{$k}++;
      $self->{$k} = $v;
    };
    ro 'q';
    rw 's';
    no  Class::Accessor::Classy;
  }
  can_ok('Foo', 'new');
  can_ok('Foo', 'q');
  can_ok('Foo', 'get_q');
  can_ok('Foo', 's');
  can_ok('Foo', 'get_s');
  can_ok('Foo', 'set_s');
  ok(! Foo->can('set_q'), 'do not want set_q');
  my $make = Foo->new(q => 5, s => 2);
  is($make->q, 5, 'getter ok');
  is($make->s, 2, 'getter ok');
  is($make->set_s(3), 3);
  is($make->s, 3,     'setter ok');
  is($make->get_s, 3, 'setter ok');
  eval {Foo->new({q => 4})};
  ok($@, 'oops');
  like($@, qr/odd number/, 'message');
  is_deeply(\%didget, {
    q => 1,
    s => 3,
  }, 'getter counts');
  is_deeply(\%didset, {
    s => 1,
  }, 'getter counts');
}

# vi:ts=2:sw=2:et:sta
