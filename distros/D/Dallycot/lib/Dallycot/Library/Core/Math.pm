package Dallycot::Library::Core::Math;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Core library of useful math functions

use strict;
use warnings;

use utf8;

use Dallycot::Library;

use Dallycot::Library::Core ();

use Promises qw(deferred collect);
use Math::BigInt::Random;

use List::Util qw(all);

use experimental qw(switch);

ns 'http://www.dallycot.net/ns/math/1.0#';

uses 'http://www.dallycot.net/ns/core/1.0#', 'http://www.dallycot.net/ns/loc/1.0#';

define
  'divisible-by?' => (
  hold    => 0,
  arity   => 2,
  options => {},
  ),
  sub {
  my ( $engine, $options, $x, $n ) = @_;

  my $d = deferred;

  if ( !$x->isa('Dallycot::Value::Numeric')
    || !$n->isa('Dallycot::Value::Numeric') )
  {
    $d->reject("divisible-by? expects numeric arguments");
  }
  else {
    my $xcopy = $x->value->copy();
    $xcopy->bmod( $n->value );
    $d->resolve( Dallycot::Value::Boolean->new( $xcopy->is_zero ) );
  }

  return $d->promise;
  };

define
  'even?' => (
  hold    => 0,
  arity   => 1,
  options => {}
  ),
  sub {
  my ( $engine, $options, $x ) = @_;

  my $d = deferred;

  if ( !$x->isa('Dallycot::Value::Numeric') ) {
    $d->reject("even? expects a numeric argument");
  }
  else {
    $d->resolve( Dallycot::Value::Boolean->new( $x->[0]->is_even ) );
  }

  return $d;
  };

define
  'odd?' => (
  hold    => 0,
  arity   => 1,
  options => {}
  ),
  sub {
  my ( $engine, $options, $x ) = @_;

  my $d = deferred;

  if ( !$x->isa('Dallycot::Value::Numeric') ) {
    $d->reject("odd? expects a numeric argument");
  }
  else {
    $d->resolve( Dallycot::Value::Boolean->new( $x->[0]->is_odd ) );
  }

  return $d->promise;
  };

define
  factorial => (
  hold    => 0,
  arity   => 1,
  options => {}
  ),
  sub {
  my ( $engine, $options, $x ) = @_;

  my $d = deferred;

  if ( !$x->isa('Dallycot::Value::Numeric') ) {
    $d->reject("factorial expects a numeric argument");
  }
  elsif ( $x->value->is_int ) {
    $d->resolve( Dallycot::Value::Numeric->new( $x->value->copy()->bfac() ) );
  }
  else {
    # TODO: handle non-integer arguments to gamma function
    $d->resolve( $engine->UNDEFINED );
  }

  return $d->promise;
  };

define
  ceil => (
  hold    => 0,
  arity   => 1,
  options => {}
  ),
  sub {
  my ( $engine, $options, $x ) = @_;

  my $d = deferred;

  if ( !$x->isa('Dallycot::Value::Numeric') ) {
    $d->reject("ceiling expects a numeric argument");
  }
  else {
    $d->resolve( Dallycot::Value::Numeric->new( $x->value->copy->bceil ) );
  }

  return $d->promise;
  };

define
  floor => (
  hold    => 0,
  arity   => 1,
  options => {}
  ),
  sub {
  my ( $engine, $options, $x ) = @_;

  my $d = deferred;

  if ( !$x->isa('Dallycot::Value::Numeric') ) {
    $d->reject("floor expects a numeric argument");
  }
  else {
    $d->resolve( Dallycot::Value::Numeric->new( $x->value->copy->bfloor ) );
  }

  return $d->promise;
  };

define
  abs => (
  hold    => 0,
  arity   => 1,
  options => {}
  ),
  sub {
  my ( $engine, $options, $x ) = @_;

  my $d = deferred;

  if ( !$x->isa('Dallycot::Value::Numeric') ) {
    $d->reject("abs expects a numeric argument");
  }
  else {
    $d->resolve( Dallycot::Value::Numeric->new( $x->value->copy->babs ) );
  }

  return $d->promise;
  };

define
  binomial => (
  hold    => 0,
  arity   => 2,
  options => {}
  ),
  sub {
  my ( $engine, $options, $x, $y ) = @_;

  my $d = deferred;

  if ( !$x->isa('Dallycot::Value::Numeric')
    || !$y->isa('Dallycot::Value::Numeric') )
  {
    $d->reject("binomial-coefficient expects numeric arguments");
  }
  else {
    $d->resolve( Dallycot::Value::Numeric->new( $x->value->copy->bnok( $y->value ) ) );
  }

  return $d->promise;
  };

define
  pi => (
  hold    => 0,
  arity   => [ 0, 1 ],
  options => {}
  ),
  sub {
  my ( $engine, $options, $accuracy ) = @_;

  my $d = deferred;

  if ( defined($accuracy) && !$accuracy->isa('Dallycot::Value::Numeric') ) {
    $d->reject("pi requires a numeric argument");
  }
  else {
    $accuracy = defined($accuracy) ? $accuracy->value->as_int : 40;
    my $pi = Math::BigFloat->bpi($accuracy);
    $d->resolve( Dallycot::Value::Numeric->new( Math::BigRat->new($pi) ) );
  }
  return $d->promise;
  };

define
  'golden-ratio' => (
  hold    => 0,
  arity   => [ 0, 1 ],
  options => {}
  ),
  sub {
  my ( $engine, $options, $accuracy ) = @_;

  my $d = deferred;

  if ( defined($accuracy) && !$accuracy->isa('Dallycot::Value::Numeric') ) {
    $d->reject("pi requires a numeric argument");
  }
  else {
    $accuracy = defined($accuracy) ? $accuracy->value->as_int : 40;
  }

  $d->resolve(
    Dallycot::Value::Numeric->new(
      Math::BigRat->new(
        ( ( 1 + Math::BigFloat->new(5)->bsqrt( $accuracy + 1 ) ) / 2 )->bround($accuracy)
      )
    )
  );

  return $d->promise;
  };

sub _simple_trig {
  my ( $name, $method, $engine, $options, $arg ) = @_;

  my $units;
  my $d = deferred;

  if ( $options->{'units'}->isa('Dallycot::Value::String') ) {
    $units = $options->{'units'}->value;
  }
  if ( !$options->{'accuracy'}->isa('Dallycot::Value::Numeric') ) {
    $d->reject("accuracy must be a numeric value");
    return $d->promise;
  }
  if ( !$arg->isa('Dallycot::Value::Numeric') ) {
    $d->reject("$name requires a numeric argument");
    return $d->promise;
  }
  my $accuracy = $options->{'accuracy'}->value->as_int;
  my $angle    = $arg->value->as_float( $accuracy + 10 );
  given ($units) {
    when ('degrees') {
      $angle = $angle * Math::BigFloat->bpi( $accuracy + 10 ) / 180;
    }
    when ('radians') { 
      $angle = $angle -> copy; 
    }
    when ('gradians') {
      $angle = $angle * Math::BigFloat->bpi( $accuracy + 10 ) / 200;
    }
    default {
      $d->reject("units must be 'degrees', 'radians', or 'gradians'");
      return $d;
    }
  }
  # Clamp angle to -2pi .. 2pi
  $angle->bmod(2 * Math::BigFloat -> bpi($accuracy));
  my $answer = $angle->$method($accuracy);
  $d->resolve( Dallycot::Value::Numeric->new( Math::BigRat->new($answer) ) );
  return $d;
}

define
  sin => (
  hold    => 0,
  arity   => 1,
  options => {
    units    => Dallycot::Value::String->new('degrees'),
    accuracy => Dallycot::Value::Numeric->new( Math::BigRat->new(40) ),
  }
  ),
  sub {
  my ( $engine, $options, $arg ) = @_;

  return _simple_trig( 'sin', 'bsin', $engine, $options, $arg );
  };

define
  cos => (
  hold    => 0,
  arity   => 1,
  options => {
    units    => Dallycot::Value::String->new('degrees'),
    accuracy => Dallycot::Value::Numeric->new( Math::BigRat->new(40) ),
  }
  ),
  sub {
  my ( $engine, $options, $arg ) = @_;

  return _simple_trig( 'cos', 'bcos', $engine, $options, $arg );
  };

define tan => <<'EOD';
  (angle, units -> "degrees", accuracy -> 40) :> (
    sin(angle, units -> units, accuracy -> accuracy) div
    cos(angle, units -> units, accuracy -> accuracy)
  )
EOD

define
  'arc-tan' => (
  hold    => 0,
  arity   => [ 1, 2 ],
  options => {
    units    => Dallycot::Value::String->new('degrees'),
    accuracy => Dallycot::Value::Numeric->new( Math::BigRat->new(40) ),
  }
  ),
  sub {
  my ( $engine, $options, $y, $x ) = @_;

  my $units;
  my $d = deferred;

  if ( $options->{'units'}->isa('Dallycot::Value::String') ) {
    $units = $options->{'units'}->value;
  }
  if ( !$options->{'accuracy'}->isa('Dallycot::Value::Numeric') ) {
    $d->reject("accuracy must be a numeric value");
    return $d->promise;
  }
  if ( !$y->isa('Dallycot::Value::Numeric') || defined($x) && !$x->isa('Dallycot::Value::Numeric') ) {
    $d->reject("arc-tan requires numeric arguments");
    return $d->promise;
  }
  my $accuracy = $options->{'accuracy'}->value->as_int;

  $y = $y->value->as_float( $accuracy + 10 );
  if ( defined $x ) {
    $x = $x->value->as_float( $accuracy + 10 );
  }

  my $angle;
  if ( defined($x) ) {
    my $key = 0;
    $key |= 0x04 if $x->is_pos && !$x->is_zero;
    $key |= 0x0c if $x->is_neg;
    $key |= 0x01 if $y->is_pos && !$y->is_zero;
    $key |= 0x03 if $y->is_neg;

    given ($key) {
      when ( [ 0x04, 0x05, 0x07 ] ) {    # $x > 0, $y anything
        $angle = $y->batan2( $x, $accuracy );
      }
      when (0x0d) {                      # $x < 0, $y > 0
        $angle = $y->batan2( $x, $accuracy + 1 ) + Math::BigFloat->bpi( $accuracy + 1 );
        $angle->bround($accuracy);
      }
      when (0x0f) {                      # $x < 0, $y < 0
        $angle = $y->batan2( $x, $accuracy + 1 ) - Math::BigFloat->bpi( $accuracy + 1 );
        $angle->bround($accuracy);
      }
      when (0x01) {                      # $x = 0, $y > 0
        $angle = Math::BigFloat->bpi( $accuracy + 1 ) / 2;
        $angle->bround($accuracy);
      }
      when (0x03) {                      # $x = 0, $y < 0
        $angle = -Math::BigFloat->bpi( $accuracy + 1 ) / 2;
        $angle->bround($accuracy);
      }
      default {
        $d->resolve( Dallycot::Value::Numeric->new( Math::BigRat->nan ) );
        return $d->promise;
      }
    }
  }
  else {
    $angle = $y->batan($accuracy);
  }

  given ($units) {
    when ('degrees') {
      $angle = $angle * 180 / Math::BigFloat->bpi($accuracy);
    }
    when ('radians') { }
    when ('gradians') {
      $angle = $angle * 200 / Math::BigFloat->bpi($accuracy);
    }
    default {
      $d->reject("units must be 'degrees', 'radians', or 'gradians'");
      return $d;
    }
  }
  $d->resolve( Dallycot::Value::Numeric->new( Math::BigRat->new($angle) ) );
  return $d;
  };

define
  gcd => (
  hold    => 0,
  arity   => [2],
  options => {}
  ),
  sub {
  my ( $engine, $options, @values ) = @_;

  my $d = deferred;

  if ( all { $_->isa('Dallycot::Value::Numeric') } @values ) {
    $d->resolve( Dallycot::Value::Numeric->new( Math::BigInt::bgcd( map { $_->value->as_int } @values ) ) );
  }
  else {
    $d->reject("gcd requires numeric values");
  }
  return $d->promise;
  };

define
  lcm => (
  hold    => 0,
  arity   => [2],
  options => {}
  ),
  sub {
  my ( $engine, $options, @values ) = @_;

  my $d = deferred;

  if ( all { $_->isa('Dallycot::Value::Numeric') } @values ) {
    $d->resolve( Dallycot::Value::Numeric->new( Math::BigInt::blcm( map { $_->value->as_int } @values ) ) );
  }
  else {
    $d->reject("gcd requires numeric values");
  }
  return $d->promise;
  };

define
  random => (
  hold    => 0,
  arity   => 1,
  options => { 'use-internet' => Dallycot::Value::Boolean->new(0), }
  ),
  sub {
  my ( $engine, $options, $spec ) = @_;

  my $d = deferred;
  my %bounds;

  if ( $options->{'use-internet'}->isa('Dallycot::Value::Boolean')
    && $options->{'use-internet'}->value )
  {
    $bounds{use_internet} = 1;
  }

  if ( $spec->isa('Dallycot::Value::Vector') ) {
    if ( @$spec != 2 ) {
      $d->reject("random requires min and max bounds with a vector argument");
      return $d->promise;
    }
    if ( all { $_->isa("Dallycot::Value::Numeric") } @$spec ) {
      $bounds{min} = $spec->[0]->value->as_int->bstr;
      $bounds{max} = $spec->[1]->value->as_int->bstr;
    }
    else {
      $d->reject("random requires numeric min/max bounds");
      return $d->promise;
    }
  }
  elsif ( $spec->isa('Dallycot::Value::Numeric') ) {
    $bounds{max} = $spec->value->as_int->bstr;
  }
  else {
    $d->reject("random requires a numeric bound");
    return $d->promise;
  }

  my $random = Math::BigInt::Random::random_bigint(%bounds);

  $d->resolve( Dallycot::Value::Numeric->new($random) );
  return $d->promise;
  };

define sum => 'foldl(0, { #1 + #2 }/2, _)';

define product => 'foldl(1, { #1 * #2 }/2, _)';

define min => <<'EOD';
  foldl1({(
    (#1 < #2) : #1
    (       ) : #2
  )}/2, _)
EOD

define max => <<'EOD';
  foldl1({(
    (#1 > #2) : #1
    (       ) : #2
  )}/2, _)
EOD

define 'weighted-count-and-sum' => <<'EOD';
  foldl( <0,0>, (
    (pad, element) :>
      <pad[1] + element[1], pad[2] + element[1] * element[2]>
  ), _)
EOD

define 'count-and-sum' => <<'EOD';
  foldl( <0,0>, (
    (pad, element) :>
      < pad[1] + 1, pad[2] + element >
  ), _)
EOD

define mean => <<'EOD';
  (s) :> ({ #[2] div #[1] } @ count-and-sum(s))
EOD

define differences => <<'EOD';
(stream, d = 1) :> (
  nest( y-combinator(
    (self, s) :> (
      (?(s') and ?(s...)) : [ s...' - s', self(self, s...) ]
      (?(s')            ) : [ -s' ]
      (                 ) : [    ]
    )
  ), d)(stream)
)
EOD

define 'make-evens' => '() :> ({ # * 2 } @ 1..)';

define 'make-odds' => '() :> ({ # * 2 + 1 } @ 0..)';

define evens => 'make-evens()';

define odds => 'make-odds()';

define primes => <<'EOD';
  sieve := y-combinator( (self, s) :> [ s', self(self, ~divisible-by?(_, s') % s...) ] );
  [ 1, 2, sieve(make-odds()...) ]
EOD

define 'prime-pairs' => 'primes Z primes...';

define 'twin-primes' => '{ #[2] - #[1] = 2 } % prime-pairs';

define factorials => 'factorial @ 1..';

define 'fibonacci-sequence' => <<'EOD';
  [ 1, 1, y-combinator((self, a, b) :> [ a + b, self(self, b, a+b) ])(1, 1) ]
EOD

define 'leonardo-sequence' => <<'EOD';
  [ 1, 1, y-combinator((self, a, b) :> [ a + b + 1, self(self, b, a + b + 1) ])(1, 1) ]
EOD

define prime     => '(n) :> primes[n]';
define fibonacci => '(n) :> fibonacci-sequence[n]';
define leonardo  => '(n) :> leonardo-sequence[n]';

1;
