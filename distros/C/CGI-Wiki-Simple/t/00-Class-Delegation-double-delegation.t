#!/usr/bin/perl -w

# Class::Delegations INIT{} block dosen't work with 5.004
require 5.006;

use vars qw( $called );

package Delegation::Base;

sub new {
  my ($class) = @_;
  my $self = {};
  bless $self, $class;
  $self;
};

sub frob {
  $::called = 1;
};

package Delegation::Test::Delegator1;
use Class::Delegation
  send => 'frob',
  to   => 'frobnicator';

sub new {
  my ($class) = @_;
  my $self = {
    frobnicator => Delegation::Base->new(),
  };
  bless $self, $class;
  $self;
};

package Delegation::Test::Delegator2;
use Class::Delegation
  send => 'frob',
  to   => 'delegator1';

sub new {
  my ($class) = @_;
  my $self = {
    delegator1 => Delegation::Test::Delegator1->new(),
  };
  bless $self, $class;
  $self;
};

package main;
use Test::More tests => 3;

my $delegator2 = Delegation::Test::Delegator2->new();
ok( ! UNIVERSAL::can( $delegator2, "frob" ), "delegator2->frob is not autoloaded" );
eval { $delegator2->frob() };
is($@,"","Calling delegator2->frob() works");
if ($@) {
  diag "This is most likely caused by a bug in Class::Delegation";
  diag "Class::Delegation checks whether an object can() a method,";
  diag "which prevents inherited autoloaded methods. Please change";
  diag "line 94 from";
  diag '  return unless eval { $target->can($as) };';
  diag "to";
  diag '  #return unless eval { $target->can($as) };';
  diag "Yes, this bug has already been reported, but I haven't heard";
  diag "back yet, please bear with me.";
};
is($called,1,"Delegation::Base->frob() was called");
