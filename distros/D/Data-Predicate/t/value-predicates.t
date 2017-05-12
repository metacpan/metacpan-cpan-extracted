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
  sub str {
    my ($self) = @_;
    return $self->{str} || 'hello';
  }
  sub num {
    my ($self) = @_;
    return $self->{num} || 1;
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
use Scalar::Util qw(blessed looks_like_number);
use Test::More tests => 41;
use Test::Exception;

use Data::Predicate::Predicates qw(:all);

my $type_decode = sub {
  my ($val) = @_;
  return ( !defined $val ) 
    ? 'undef'   : ( looks_like_number($val)) 
    ? $val  : (ref($val)) 
    ? ref($val) : "'$val'";
};

my $test_value_predicates = sub {
  my ($p, $fails, $successes) = @_;
  foreach my $fail (@{$fails}) {
    ok(!$p->apply($fail), 'We do not expect this to work with '.$type_decode->($fail));
  }
  foreach my $success (@{$successes}) {
    ok($p->apply($success), 'We expect this to work with '.$type_decode->($success));
  }
  return;
};

my $test_value_invoke_predicates = sub {
  my ($p, $fail, $pass, $exception) = @_;
  $test_value_predicates->($p, $fail, $pass);
  foreach my $ex (@{$exception}) {
    my $t = $type_decode->($ex);
    dies_ok { $p->apply($ex) } 'expecting to die because tested object '.$t.' cannot invoke the used method';
  }
  return;
};

diag 'p_string_equals()';
$test_value_predicates->(
  p_string_equals('hello'), 
  [undef, 1, [], ' hello'], 
  ['hello']
);
$test_value_invoke_predicates->(
  p_string_equals('hello', 'str'),
  [Two->new(str => 'boo')],
  [One->new()],
  [Tmp->new()]
);

diag 'p_numeric_equals()';
$test_value_predicates->(
  p_numeric_equals(10), 
  [undef, 1, [], 'hello'], 
  ['10', 10]
);
$test_value_invoke_predicates->(
  p_numeric_equals(1, 'num'),
  [Two->new(num => 2)],
  [One->new()],
  [Tmp->new()]
);

my $s_regex = qr/hel/;
diag 'p_regex() with '.$s_regex;
$test_value_predicates->(
  p_regex($s_regex), 
  [undef, 1, [], {}], 
  ['hello', ' hello', 'addasoudf hel efdlindfs']
);

my $n_regex = qr/^\d$/;
diag('Switch to '.$n_regex);
$test_value_predicates->(
  p_regex($n_regex), 
  [111111111], 
  [1,2,3]
);

$test_value_invoke_predicates->(
  p_regex(qr/he/, 'str'),
  [Two->new(str => 'boo')],
  [One->new()],
  [Tmp->new()]
);

my $substring = 'he';
diag 'p_substring() with '.$substring;
$test_value_predicates->(
  p_substring($substring), 
  [undef, 1, [], {}], 
  ['hello', ' hello', 'addasoudf hel efdlindfs']
);

$test_value_invoke_predicates->(
  p_substring($substring, 'str'),
  [Two->new(str => 'boo')],
  [One->new()],
  [Tmp->new()]
);