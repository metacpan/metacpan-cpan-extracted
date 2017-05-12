#!/usr/bin/perl

package InsideOut;

use strict;
use warnings;

eval "use Class::Accessor;";

use Class::Tie::InsideOut;

our @ISA = qw( Class::Tie::InsideOut Class::Accessor );

our %GoodKey;

InsideOut->mk_accessors(qw( GoodKey ) );

sub set {
  my ($self, $key, $value) = @_;
  return $self->{$key} = $value;
}

sub get {
  my ($self, $key) = @_;
  return $self->{$key};
}

package main;

use strict;
use warnings;

use Test::More skip_all => "Class::Accessor fails tests";

eval "use Class::Accessor;";
plan skip_all => "Class::Accessor is not installed" if ($@);

plan tests => 3;

my $obj = InsideOut->new();
ok($obj->isa("InsideOut"));
ok($obj->isa("Class::Tie::InsideOut"));

$obj->GoodKey(1);
ok($obj->GoodKey == 1, "set/get");

