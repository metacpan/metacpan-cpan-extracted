## no critic ( ProhibitMultiplePackages )

use strict;
use warnings;

# https://en.wikipedia.org/wiki/Finite-state_machine

package TurnstileStateMachine;

use Exporter qw( import );
use Class::Enumeration::Builder { export => 1 }, qw( Locked Unlocked );

package TurnstileStateMachine::Locked;

use Carp qw( croak );

sub do_something {
  my ( $self, $input ) = @_;

  return __PACKAGE__->value_of( 'Unlocked' ) if $input eq 'coin';
  return $self                               if $input eq 'push';
  croak "Wrong input '$input', stooped";
}

package TurnstileStateMachine::Unlocked;

use Carp qw( croak );

sub do_something {
  my ( $self, $input ) = @_;

  return __PACKAGE__->value_of( 'Locked' ) if $input eq 'push';
  return $self                             if $input eq 'coin';
  croak "Wrong input '$input', stooped";
}

1
