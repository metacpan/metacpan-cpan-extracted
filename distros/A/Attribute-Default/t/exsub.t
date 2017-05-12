# exsub.t
#
# Tests out expanding subroutines.
#
# $Revision$
#

use strict;
use diagnostics;

########################

use Test::More tests => 9;
use Attribute::Default;

{
  package Attribute::Default::TestExpand;
  use Attribute::Default 'exsub';
  use base qw(Attribute::Default);
  use UNIVERSAL;
  use Data::Dumper;


  sub single_sub : Default(exsub { return "3" } ) {
    return "Should be three: $_[0]";
  }

  sub exp_hash :Default({foo => exsub { my %args = @_; return $args{'bar'} * 7 }, bar => 2 }) {
    my %args = @_;
    return "foo: $args{'foo'} bar: $args{'bar'}";
  }

  sub new { my $self = [3]; bless $self; }

  sub exp_meth_hash :method :Default({foo => exsub { _check_and_mult($_[0], 4); } }) {
    my $self = shift;
    unless (@_ % 2 == 0) {
      no warnings 'uninitialized';
      Test::More::diag("Wrong number of arguments to 'exp_meth_hash'");
      Test::More::diag(Dumper(\@_));
      Test::More::diag("\$self: $self");
      return;
    }
    my %args = @_;
    return $args{'foo'};
  }

  sub exp_meth_array :method :Default(exsub{ _check_and_mult($_[0], 2) }) {
    return $_[1];
  }

  sub exp_meth_array_multip :method :Default('first', exsub { _check_and_mult($_[0], 2) } ) {
    no warnings 'uninitialized';
    return "$_[1] $_[2]";
  }

  sub exp_meth_array_multip2 :method :Default(exsub { _check_and_mult($_[0], 2) }, "second" ) {
    no warnings 'uninitialized';
    return "$_[1] $_[2]";
  }


  # Defaults to 64*2=128
  sub defaults_interref_expansion :Defaults({foo => 23, bar => 64}, [ 2, exsub { $_[0]{'bar'} * $_[1][0]}], 3)
    {
      return $_[1][1];
    }

  # Defaults to 3*6=18
  sub defaults_interref_expansion_meth :method :Defaults({op1 => exsub { _check_and_mult($_[0], $_[3]{'baz'})}, op2 => 0}, 22, { baz => 6, bap => 33 }) {
    return $_[1]{'op1'};
  }

  sub _check_and_mult {
    my $self = shift;
    my ($factor) = @_;
    
    unless (@_ == 1) {
      Test::More::diag("Expanded sub got wrong number of arguments: @{[ scalar @_ ]}");
      return;
    }
    unless (UNIVERSAL::isa($self, __PACKAGE__)) {
      Test::More::diag("Expanded sub got wrong kind of type for \$self: $self");
      return;
    }
    return $self->[0] * $factor;
  }
}
  
is(Attribute::Default::TestExpand::single_sub(), 'Should be three: 3', 'Single-arg subroutine with exsub');
is(Attribute::Default::TestExpand::single_sub(4), 'Should be three: 4', 'Single-arg subroutine with exsub, overridden value');
is(Attribute::Default::TestExpand::exp_hash(), "foo: 14 bar: 2", 'Default hash with exsub');
is(Attribute::Default::TestExpand::exp_hash(bar => 3), "foo: 21 bar: 3", 'Default hash with exsub referring to overridden');
is(Attribute::Default::TestExpand::exp_hash(bar => 4, foo => 'mangel-wurzel'), 'foo: mangel-wurzel bar: 4', 'Default hash with exsub overridden');
{
  my $testobj = Attribute::Default::TestExpand->new();
  is($testobj->exp_meth_hash(), 12, "Expand sub in hash for method");
  is($testobj->exp_meth_array(), 6, "Expand sub in array for method");
  is($testobj->exp_meth_array_multip(), "first 6", "Expand sub in array for method with two arguments");
  is($testobj->exp_meth_array_multip2(), "6 second", "Expand sub in array for method with exp as second arg");
}
