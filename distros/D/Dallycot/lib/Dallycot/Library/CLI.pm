package Dallycot::Library::CLI;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: functions for use with the command line interface

use strict;
use warnings;

use utf8;
use Dallycot::Library;

use Carp qw(croak);
use Promises qw(deferred collect);

use experimental qw(switch);

ns 'http://www.dallycot.net/ns/cli/1.0#';

define
  print => (
  hold    => 0,
  arity   => [1],
  options => {}
  ),
  sub {
  my ( $engine, $options, @things ) = @_;

  my $d = deferred;

  for my $thing (@things) {
    if ( $thing->isa('Dallycot::Value::String') ) {
      $engine->channel_send( '$OUTPUT', $thing->value );
    }
    else {
      $engine->channel_send( '$OUTPUT', $thing->as_text );
    }
  }
  $engine->channel_send( '$OUTPUT', "\n" );
  $d->resolve( $engine->TRUE );
  return $d->promise;
  };

define emit => (
  hold => 0,
  arity => 1,
  options => {}
), sub {
  my ( $engine, $options, $point ) = @_;

  if(!$point || !$point->isa('Dallycot::Value::Numeric') || !$point->value->is_int) {
    croak 'emit requires an integer code point';
  }

  $engine->channel_send( '$OUTPUT',  chr($point->value->numify));
  my $d = deferred;
  $d -> resolve($engine -> TRUE);
  return $d -> promise;
};

define
  'input-string' => (
  hold    => 0,
  arity   => [ 0, 1 ],
  options => {}
  ),
  sub {
  my ( $engine, $options, $prompt ) = @_;

  my %options;
  if ($prompt) {
    $options{prompt} = $prompt;
  }

  return $engine->channel_read( '$INPUT', %options );
  };

define
  input => (
  hold    => 0,
  arity   => [ 0, 1 ],
  options => {}
  ),
  sub {
  my ( $engine, $options, $prompt ) = @_;

  my %options;
  if ($prompt) {
    $options{prompt} = $prompt;
  }

  my $d = deferred;
  _get_valid_input( $engine, $d, '$INPUT', %options );
  return $d->promise;
  };

sub _get_valid_input {
  my ( $engine, $d, $channel, %options ) = @_;

  $engine->channel_read( $channel, %options )->done(
    sub {
      my ($string) = @_;
      my $source   = $string->value;
      my $parser   = Dallycot::Parser->new;
      my $parse    = $parser->parse($source);
      if ($parse) {
        $engine->new->execute(@$parse)->done(
          sub {
            $d->resolve(@_);
          },
          sub {
            my ($err) = @_;
            $engine->channel_send( '$OUTPUT', "*** $err\n" );
            _get_valid_input( $engine, $d, $channel, %options );
          }
        );
      }
      elsif ( $parser->error ) {
        $engine->channel_send( '$OUTPUT', "*** " . $parser->error . "\n" );
        _get_valid_input( $engine, $d, $channel, %options );
      }
      else {
        _get_valid_input( $engine, $d, $channel, %options );
      }
    },
    sub {
      my ($err) = @_;
      $engine->channel_send( '$OUTPUT', "*** $err\n" );
      _get_valid_input( $engine, $d, $channel, %options );
    }
  );
  return;
}

1;
