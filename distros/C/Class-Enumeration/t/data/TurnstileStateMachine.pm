## no critic ( ProhibitMultiplePackages )

# https://en.wikipedia.org/wiki/Finite-state_machine

use strict;
use warnings;

use Carp ();

my $croak = \&Carp::croak;

package TurnstileStateMachine;

use Exporter qw( import );
use Class::Enumeration::Builder { export => 1 }, qw( Locked Unlocked );

package TurnstileStateMachine::Locked;

sub do_something {
  my ( $self, $input ) = @_;

  return __PACKAGE__->value_of( 'Unlocked' ) if $input eq 'coin';
  return $self                               if $input eq 'push';
  $croak->( "Wrong input '$input', stopped" )
}

package TurnstileStateMachine::Unlocked;

sub do_something {
  my ( $self, $input ) = @_;

  return __PACKAGE__->value_of( 'Locked' ) if $input eq 'push';
  return $self                             if $input eq 'coin';
  $croak->( "Wrong input '$input', stopped" )
}

1
