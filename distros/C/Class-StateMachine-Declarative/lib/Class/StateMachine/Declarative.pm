package Class::StateMachine::Declarative;

sub _clean_eval { eval shift }

our $VERSION = '0.03';

use 5.010;

use strict;
use warnings;
use Carp;
BEGIN { our @CARP_NOT = qw(Class::StateMachine Class::StateMachine::Private) }

use Class::StateMachine::Declarative::Builder;

my $dump = exists $ENV{CLASS_STATEMACHINE_DECLARATIVE_DUMPFILE};
my %dump;

END {
    if ($dump) {
        open my $fh, ">", $ENV{CLASS_STATEMACHINE_DECLARATIVE_DUMPFILE} or return;
        require Data::Dumper;
        print $fh Data::Dumper->Dump([\%dump], [qw(*state_machines)]);
        close $fh;
    }
}

sub import {
    shift;
    my $class = scalar(caller);
    $dump{$class} = [ @_ ] if $dump;
    my $builder = Class::StateMachine::Declarative::Builder->new($class);
    $builder->parse_state_declarations(@_);
    $builder->generate_class;
    #use Data::Dumper;
    #print STDERR Dumper($builder);
}

1;
__END__

=head1 NAME

Class::StateMachine::Declarative - Define state machines classes in a high level declarative fashion

=head1 SYNOPSIS


  package Dog;

  use parent 'Class::StateMachine';

  use Class::StateMachine::Declarative
      __any__  => { ignore => [qw(on_sleep on_feed)],
                    before => { on_knocked_down => 'cry',
                                kicked => 'bark' },
                    transitions => { on_knocked_down => 'unhappy/injuried',
                                     kicked          => 'unhappy/angry' } },

      happy    => { enter => 'move_tail',
                    on => { on_head_touched => 'move_tail' },
                    transitions => { on_knocked_down => 'injuried',

      unhappy => { substates => [ injuried => { enter => 'bark',
                                                on => { on_head_touched => 'bark' },
                                                transitions => { on_sleep => 'happy' } },
                                  angry    => { enter => 'bark',
                                                ignore => [qw(kicked)],
                                                on => { on_head_touched => 'bite' },
                                                transitions => { on_feed => 'happy' } } ] };

  sub new {
    my $class = shift;
    my $self = {};
    # starting state is set here:
    Class::StateMachine::bless $self, $class, 'happy';
    $self;
  }

  package main;

  my $dog = Dog->new;
  $dog->on_head_touched; # the dog moves his tail
  $dog->on_kicked;
  $dog->on_head_touched; # the dog bites (you!)
  $dog->on_injuried;
  $dog->on_head_touched; # the dog barks
  $dog->on_sleep;
  $dog->on_head_touched; # the dog moves his tail


=head1 DESCRIPTION

Class::StateMachine::Declarative is a L<Class::StateMachine> (from now
on C::SM) extension that allows to define most of a state machine
class declaratively.

The way to create a new Class::StateMachine derived class from this
module is to pass a set of state declarations through its use
statement:

  use Class::StateMachine::Declarative
      $state1 => $decl1,
      $state2 => $decl2,
      ...;

Note that Class::StateMachine::Declarative will not set C<@ISA> for
you, as you may want to derive your classes not from C::SM directly
but from some of its subclasses. For instance:

  use parent 'My::StateMachine::BaseClass';
  use Class::StateMachine::Declarative @decl;

The following attributes can be used to define the state behaviour:

=over 4

=item enter => $method

method to be called when the object enters in the state

=item leave => $method

method to be called when the object leaves the state

=item advance => $event

when this event (method call) happens the state is changed to the next one declared.

=item before => \%before

where %before contains pairs C<< $event => $action >>

When any of the events on the declaration happens, the corresponding
action (a method actually) will be called before the final C<advance>,
C<on>, C<transition> or C<ignore> action is carried out.

Also, C<before> actions are stacked on the hierarchy. So, if you
define a before action for a state and then another for some substate,
then both C<before> actions will be called when on the substate.

For instance:

  Class::StateMachine::Declarative
    foo => { ignore => ['bar'],
             before => { bar => 'bar_from_foo' },
             substates => [ doz => { before => { bar => 'bar_from_doz' } } ] };

Invoking C<bar> from the state C<foo/doz> calls both C<bar_from_foo>
and C<bar_from_doz> methods.

Note that C<before> actions are not carried out when the principal
action is marked as delayed (via the C<delay> declaration).

Before actions is the ideal place to propagate events to other
objects.

=item on => \%on

where %on contains pairs C<< $event => $action >>

When any of the events in the declaration happens the corresponding
given action is called.

=item transitions => \%transitions

where %transitions contains pairs C<< $event => $target_state >>

When any of the given events happens, the object state is changed to
the corresponding target state (and executing C<before>,
C<leave_state> and C<enter_state> hooks on the way).

=item ignore => \@event_list

When any of the given events happen, they are ignored.

C<before> actions defined are executed though.

=item delay => \@event_list

When any of the given events happen, no action is executed but they
are remembered until the next state change and them called again.

C<before> actions are not called. They will be called when the event
is called again from the next state, but them the actual action
executed will be that for that state if any.

=item jump => $target_state

When the object enters in this state it immediately changes its state
to the given one.

=item substates => \@substates

An state can have substates.

Most actions are inherited from the state into the substates. For
instance, a transition defined in some state will also happen in its
substates unless it is overridden by another declaration.

The state C<__any__> is an special state that is considered the parent
of all the other states.

=back

=head1 SEE ALSO

L<Class::StateMachine>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2014 by Salvador FandiE<ntilde>o <sfandino@yahoo.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
