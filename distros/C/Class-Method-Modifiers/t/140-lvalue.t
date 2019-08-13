use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;

{
  package WithLvalue;
  my $f;
  sub lvalue_method :lvalue { $f }

  sub other_method { 1 }

  my @array;
  sub array_lvalue :lvalue { @array }
}

{
  package Around;
  use Class::Method::Modifiers;
  our @ISA = qw(WithLvalue);

  around lvalue_method => sub :lvalue {
    my $orig = shift;
    $orig->(@_);
  };

  my $d;
  around other_method => sub :lvalue {
    $d;
  };

  around array_lvalue => sub :lvalue {
    $_[0]->(@_[1..$#_]);
  };
}

Around->lvalue_method = 1;
is(Around->lvalue_method, 1, 'around on an lvalue attribute is maintained');

Around->other_method = 2;
is(Around->other_method, 2, 'around adding an lvalue attribute works');

(Around->array_lvalue) = (1,2);
is_deeply([WithLvalue->array_lvalue], [1,2], 'around on array lvalue attribute works');

{
  package Before;
  use Class::Method::Modifiers;
  our @ISA = qw(WithLvalue);

  before lvalue_method => sub {};
}

Before->lvalue_method = 3;
is(Before->lvalue_method, 3, 'before maintains lvalue attribute');

{
  package After;
  use Class::Method::Modifiers;
  our @ISA = qw(WithLvalue);

  after lvalue_method => sub {};

  after array_lvalue => sub {};
}

After->lvalue_method = 4;
is(After->lvalue_method, 4, 'after maintains lvalue attribute');

{
  local $TODO = "can't apply after to array lvalue method";
  is exception { (After->array_lvalue) = (3,4) }, undef,
    'assigning to array lvalue attribute causes no errors';
  is_deeply([After->array_lvalue], [3,4],
    'after array lvalue attribute sets values');
}

{
  package LvalueWithProto;
  use Class::Method::Modifiers;

  my $f;
  sub lvalue_proto_method ($) :lvalue { $f }

  local $SIG{__WARN__} = sub {};
  after lvalue_proto_method => sub {};
}

is exception { LvalueWithProto->lvalue_proto_method = 4 }, undef,
  'after maintains lvalue attribute with prototype present';
is(LvalueWithProto->lvalue_proto_method, 4,
  'after with lvalue and prototype correctly assigns');

done_testing;
