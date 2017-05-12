package Dallycot::Library::Core::Strings;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Core library of useful string functions

use strict;
use warnings;

use utf8;

use Dallycot::Library;

use Digest::MD5;
use Math::BaseCalc;

use experimental qw(switch);

use Carp qw(croak);
use Promises qw(deferred);

use Dallycot::Library::Core          ();
use Dallycot::Library::Core::Streams ();

ns 'http://www.dallycot.net/ns/strings/1.0#';

uses 'http://www.dallycot.net/ns/loc/1.0#',
     'http://www.dallycot.net/ns/core/1.0#',
     'http://www.dallycot.net/ns/streams/1.0#';

#====================================================================
#
# Basic string functions

define
  'string-contains?' => (
  hold => 0,
  arity => 2,
  options => {}
  ),
  sub {
  my ( $engine, $options, $string, $patt ) = @_;

  if ( !$string -> isa('Dallycot::Value::String') ) {
    croak 'The first argument of string-contains? must be a string';
  }
  if ( !$patt -> isa('Dallycot::Value::String') ) {
    croak 'The pattern for string-contains? must be a string';
  }

  return Dallycot::Value::Boolean -> new(
    index($string -> value, $patt -> value) != -1
  );
};

define
  'string-split' => (
  hold    => 0,
  arity   => [1,3],
  options => {}
  ),
  sub {
  my ( $engine, $options, $string, $patt, $max_count ) = @_;

  if ( !$string ) {
    return Dallycot::Value::EmptyStream->new;
  }
  my @bits;
  my $source = $string -> value;
  if(!$patt) {
    @bits = split( /\s+/, $source );
  }
  else {
    my $count;
    if($max_count) {
      if ( $max_count->isa('Dallycot::Value::Numeric') ) {
        $count = $max_count->value->numify;
      }
      else {
        croak 'Limit for string-split must be numeric';
      }
    }
    if($patt -> isa('Dallycot::Value::String')) {
      if($count) {
        @bits = split($patt -> value, $source, $count);
      }
      else {
        @bits = split($patt -> value, $source);
      }
    }
    else {
      croak 'Pattern for string-split must be a string';
    }
  }
  return Dallycot::Value::Vector->new(
    map {
      Dallycot::Value::String->new($_, $string->lang)
    } @bits
  );
};

define
  'string-take' => (
  hold    => 0,
  arity   => 2,
  options => {}
  ),
  sub {
  my ( $engine, $options, $string, $spec ) = @_;

  if ( !$string ) {
    my $d = deferred;
    $d->resolve( $engine->UNDEFINED );
    return $d->promise;
  }
  elsif ( !$spec ) {
    my $d = deferred;
    $d->resolve( $engine->UNDEFINED );
    return $d->promise;
  }
  else {
    if ( $spec->isa('Dallycot::Value::Numeric') ) {
      my $length = $spec->value->numify;
      return $string->take_range( $engine, 1, $length );
    }
    elsif ( $spec->isa('Dallycot::Value::Vector') ) {
      given ( scalar(@$spec) ) {
        when (1) {
          if ( $spec->[0]->isa('Dallycot::Value::Numeric') ) {
            my $offset = $spec->[0]->value->numify;
            return $string->value_at( $engine, $offset );
          }
          else {
            my $d = deferred;
            $d->reject("Offset must be numeric");
            return $d->promise;
          }
        }
        when (2) {
          if ( $spec->[0]->isa('Dallycot::Value::Numeric')
            && $spec->[1]->isa('Dallycot::Value::Numeric') )
          {
            my ( $offset, $length )
              = ( $spec->[0]->value->numify, $spec->[1]->value->numify );

            return $string->take_range( $engine, $offset, $length );
          }
          else {
            my $d = deferred;
            $d->reject("string-take requires numeric offsets");
            return $d->promise;
          }
        }
        default {
          my $d = deferred;
          $d->reject("string-take requires 1 or 2 numeric elements in an offset vector");
          return $d->promise;
        }
      }
    }
    else {
      my $d = deferred;
      $d->reject("Offset must be numeric or a vector of numerics");
      return $d->promise;
    }
  }
  };

define
  'string-drop' => (
  hold    => 0,
  arity   => 2,
  options => {},
  ),
  sub {
  my ( $engine, $options, $string, $spec ) = @_;

  if ( !$string ) {
    my $d = deferred;
    $d->resolve( $engine->UNDEFINED );
    return $d->promise;
  }
  elsif ( !$spec ) {
    my $d = deferred;
    $d->resolve( $engine->UNDEFINED );
    return $d->promise;
  }
  elsif ( $spec->isa('Dallycot::Value::Numeric') ) {
    my $offset = $spec->value->numify;
    return $string->drop( $engine, $offset );
  }
  else {
    my $d = deferred;
    $d->reject("string-drop requires a numeric second argument");
    return $d->promise;
  }
  };

define 'string-join' => << 'EOD';
(joiner, string-stream) :> last(
  foldl1(
    { #1 ::> joiner ::> #2 }/2,
    string-stream
  )
)
EOD

define 'ends-with?' => <<'EOD';
(value, substr) :> (
  string-take(value, < length(value) - length(substr) + 1, length(value) > ) = substr
)
EOD

define 'starts-with?' => <<'EOD';
(value, substr) :> (
  string-take(value, < 1, length(substr) > ) = substr
)
EOD

define
  'hash' => (
  hold    => 0,
  arity   => 1,
  options => { type => Dallycot::Value::String->new('MD5') }
  ),
  sub {
  my ( $engine, $options, $string ) = @_;

  my $digest = Digest::MD5::md5_hex( $string->value );
  my $num    = Math::BigRat->from_hex("0x$digest");
  my $d      = deferred;
  $d->resolve( Dallycot::Value::Numeric->new($num) );
  return $d->promise;
  };

define
  'string-multiply' => (
  hold    => 0,
  arity   => 2,
  options => {}
  ),
  sub {
  my ( $engine, $options, $string, $count ) = @_;

  if ( !defined($string) || !$string->isa('Dallycot::Value::String') ) {
    croak 'string-multiple requires a string as its first argument.';
  }
  if ( !defined($count) || !$count->isa('Dallycot::Value::Numeric') ) {
    croak 'string-multiple requires a numeric second argument.';
  }
  my $base = $string->value;
  my $c    = $count->value->as_int;
  return Dallycot::Value::String->new( $base x $c, $string->lang );
  };

define
  'N' => (
  hold    => 0,
  arity   => 1,
  options => { accuracy => Dallycot::Value::Numeric->new( Math::BigRat->new(40) ) }
  ),
  sub {
  my ( $engine, $options, $number ) = @_;

  if ( !defined($number) || !$number->isa('Dallycot::Value::Numeric') ) {
    my $d = deferred;
    $d->reject("N requires a numeric argument");
    return $d->promise;
  }

  if ( !defined( $options->{accuracy} ) || !$options->{accuracy}->isa('Dallycot::Value::Numeric') ) {
    my $d = deferred;
    $d->reject("N requires a numeric accuracy");
    return $d->promise;
  }

  my $accuracy = $options->{accuracy}->value->as_int;
  $number = $number->value->as_float->bround($accuracy);
  my $d = deferred;
  $d->resolve( Dallycot::Value::String->new( $number->bstr ) );
  return $d->promise;
  };

define
  'number-string' => (
  hold    => 0,
  arity   => [ 1, 2 ],
  options => {}
  ),
  sub {
  my ( $engine, $options, $number, $base ) = @_;

  if ( !defined($number) || !$number->isa('Dallycot::Value::Numeric') ) {
    my $d = deferred;
    $d->reject("number-string requires a numeric argument");
    return $d->promise;
  }

  $base = defined($base) ? $base->value->numify : 10;
  my $d = deferred;

  if ( $base < 2 || $base > 64 ) {
    $d->reject('number-string requires a base between 2 and 64 inclusive');
    return $d->promise;
  }

  my @regular_digits = ( 0 .. 9, 'a' .. 'z', 'A' .. 'Z', '_' );

  my $converter = Math::BaseCalc->new( digits => [ 0, 1 ] );
  if ( $base < 64 ) {
    $converter->digits( [ @regular_digits[ 0 .. $base - 1 ] ] );
  }
  else {
    $converter->digits( [ 'A' .. 'Z', 'a' .. 'z', 0 .. 9, '+', '/' ] );
  }

  my $string;

  my ( $num, $den ) = $number->value->parts;

  if ( $number->value->is_int || $den->is_one ) {
    $string = $converter->to_base($num);
  }
  else {
    $string = $converter->to_base($num) . " / " . $converter->to_base($den);
  }
  $d->resolve( Dallycot::Value::String->new($string) );
  return $d->promise;
  };

1;
