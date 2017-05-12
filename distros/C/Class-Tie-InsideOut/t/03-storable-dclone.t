#!/usr/bin/perl

package InsideOut;

use strict;
use warnings;

use Class::Tie::InsideOut;

our @ISA = qw( Class::Tie::InsideOut );

our @METHODS;

BEGIN {
  @METHODS = ('a'..'j');
  foreach my $method (@METHODS) {
    no strict 'refs';
    *$method = { };
    *$method = sub {
      my $self = shift;
      if (@_) { $self->{$method} = shift; }
      else { $self->{$method}; }
    };
  }
  eval "use Storable qw( dclone );";
}

sub clone {
  my $self = shift;
  my $clone = dclone($self);
  return $clone;
}

package InsideOut::Inherited;

our @ISA = qw( InsideOut );

our @METHODS;

BEGIN {
  @METHODS = ('a'..'j');
  foreach my $method (@METHODS) {
    no strict 'refs';
    *$method = { };
    *{"in_$method"} = sub {
      my $self = shift;
      if (@_) { $self->{$method} = shift; }
      else { $self->{$method}; }
    };
    *{"ou_$method"} = { };
    *{"ou_$method"} = sub {
      my $self = shift;
      if (@_) { $self->{"ou_$method"} = shift; }
      else { $self->{"ou_$method"}; }
    };
  }
}

package main;

use strict;
use warnings;

use Test::More;

eval "use Storable;";

plan skip_all => "Storable is not installed" if ($@);

plan tests => 6 + (4 * scalar(@InsideOut::METHODS)) + (4 * scalar(@InsideOut::Inherited::METHODS));

{
  my $obj = InsideOut->new();
  ok($obj->isa("InsideOut"));

  my $count = 0;
  foreach my $method (@InsideOut::METHODS) {
    $obj->$method(++$count);
    ok($obj->$method == $count);
  }

  my $clone = $obj->clone;
  ok($clone->isa("InsideOut"));
  foreach my $method (@InsideOut::METHODS) {
    ok($obj->$method == $clone->$method);
  }
}

{
  my $obj = InsideOut::Inherited->new();
  ok($obj->isa("InsideOut"));
  ok($obj->isa("InsideOut::Inherited"));

  my $count = 0;
  foreach my $method (@InsideOut::METHODS) {
    $obj->$method(++$count);
    ok($obj->$method == $count);
  }
  foreach my $method (@InsideOut::Inherited::METHODS) {
    my $in_method = "in_$method";
    $obj->$in_method(++$count);
    ok($obj->$in_method == $count);
    my $ou_method = "ou_$method";
    $obj->$ou_method(++$count);
    ok($obj->$ou_method == $count);
  }

  my $clone = $obj->clone;
  ok($clone->isa("InsideOut"));
  ok($clone->isa("InsideOut::Inherited"));
  foreach my $method (@InsideOut::METHODS) {
    ok($obj->$method == $clone->$method);
  }
  foreach my $method (@InsideOut::Inherited::METHODS) {
    my $in_method = "in_$method";
    ok($obj->$in_method == $clone->$in_method);
    my $ou_method = "ou_$method";
    ok($obj->$ou_method == $clone->$ou_method);
  }
}
