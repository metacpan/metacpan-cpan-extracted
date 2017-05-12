package Auto::Mata;
# ABSTRACT: A simple, reliable finite state machine
$Auto::Mata::VERSION = '0.08';

use strict;
use warnings;
use parent 'Exporter';
use Carp;
use Data::Dumper;
use List::Util qw(first reduce);
use Storable qw(dclone);
use Type::Utils -all;
use Types::Standard -all;
use Type::Params qw(compile);

our @EXPORT = qw(
  machine
  ready
  terminal
  term
  transition
  to
  on
  with
  using
);

our $DEBUG = $ENV{DEBUG_AUTOMATA};

my $Ident = declare 'Ident', as StrMatch[qr/^[A-Z][_0-9A-Z]*$/i];
my $State = declare 'State', as Tuple[$Ident, Any];
my $Type  = declare 'Type',  as InstanceOf['Type::Tiny'];
coerce $Type, from Undef, via { Any };

my $Transition = declare 'Transition', as Dict[
  to        => $Ident,
  initial   => $Type,
  transform => Maybe[CodeRef],
];

my $Automata = declare 'Automata', as Dict[
  ready => Maybe[$Ident],
  term  => Maybe[$Ident],
  map   => Map[$Ident, ArrayRef[$Transition]],
];


sub machine (&) {
  my $code = shift;

  #-----------------------------------------------------------------------------
  # Define the machine parameters
  #-----------------------------------------------------------------------------
  my %fsm = (
    ready => undef,
    term  => undef,
    map   => {},
  );

  do {
    local $_ = \%fsm;
    $code->();
    validate();
  };

  my %map      = %{$fsm{map}};
  my $ready    = $fsm{ready};
  my $term     = $fsm{term};
  my $Terminal = declare 'Terminal', as Tuple[Enum[$term], Any];

  #-----------------------------------------------------------------------------
  # For each state, compile a type union that matches all 'on' constraints
  # where that state is the 'to' state. This will be used to validate the state
  # accumulator after each transition to that state.
  #-----------------------------------------------------------------------------
  my %final = ($term => $Terminal);

  foreach my $from (keys %map) {
    my @next = map { $_->{initial} } @{$map{$from}};
    $final{$from} = declare $from, as reduce { $a | $b } @next;
  }

  #-----------------------------------------------------------------------------
  # Build the transition engine
  #-----------------------------------------------------------------------------
  my @match;
  foreach my $from (keys %map) {
    #---------------------------------------------------------------------------
    # Create a type constraint that matches each possible initial "from" state.
    # Use this to build a matching function that calls the appropriate mutator
    # for that transisiton.
    #---------------------------------------------------------------------------
    foreach my $transition (@{$map{$from}}) {
      my $to      = $transition->{to};
      my $initial = $transition->{initial};
      my $with    = $transition->{transform};
      my $final   = $final{$to};

      push @match, $initial, sub {
        my ($from, $input) = @$_;
        debug('%s -> %s', $from, $to);

        do { local $_ = $input; $input = $with->() } if $with;
        my $state = [$to, $input];

        if (defined(my $error = $final->validate($state))) {
          if (my $explain = $final->validate_explain($state, 'FINAL_STATE')) {
            debug($_) foreach @$explain;
          }

          croak join "\n",
            sprintf('Transition from %s to %s produced an invalid state.', $from, $to),
            sprintf('Initial state: %s', explain($_)),
            sprintf('Final state: %s', explain($_)),
            sprintf($error);
        }

        return @$state;
      };
    }
  }

  my $default = sub { croak 'no transitions match ' . explain($_) };
  my $transform = compile_match_on_type(@match, => $default);

  #-----------------------------------------------------------------------------
  # Return function that builds a transition engine for the given input
  #-----------------------------------------------------------------------------
  return sub {
    my $interactive = shift;

    my $state = $ready;
    my $done;

    my $iter = sub (\$) {
      return if $done;
      ($state, $_[0]) = $transform->([$state, $_[0]]);
      $done = $Terminal->check([$state, $_[0]]);
      wantarray ? ($state, $_[0]) : $state;
    };

    return $iter if $interactive;

    return sub (\$) {
      while (my ($state, $acc) = $iter->($_[0])) {
        ;
      }

      return $_[0];
    };
  };
}


sub ready    ($)   { assert_in_the_machine(); $_->{ready} = shift }
sub terminal ($)   { assert_in_the_machine(); $_->{term}  = shift }
sub term     ($)   { goto \&terminal }
sub to       ($;%) { (to   => shift, @_) }
sub on       ($;%) { (on   => shift, @_) }
sub with     (&;%) { (with => shift, @_) }
sub using    (&;%) { goto \&with }


my $_transition_args;

sub transition ($%) {
  assert_in_the_machine();
  $_transition_args ||= compile($Ident, $Ident, $Type, Maybe[CodeRef]);

  my ($arg, %param) = @_;
  my ($from, $to, $on, $with) = $_transition_args->($arg, @param{qw(to on with)});

  $_->{map}{$from} ||= [];

  my $name = $on->name;
  my $init = declare "${from}_to_${to}_on_${name}", as Tuple[Enum[$from], $on];
  debug("New state: $init");

  foreach my $next (@{$_->{map}{$from}}) {
    croak "transition conflict in $from to $to: $on already matched by $next->{initial}"
      if $init == $next->{initial};
  }

  my $transition = {
    to        => $to,
    initial   => $init,
    transform => $with,
  };

  # Add this contraint to the list of matches
  push @{$_->{map}{$from}}, $transition;
}

#-------------------------------------------------------------------------------
# Throws an error when not within a call to `machine`. When debugging, includes
# the full `validate_explain` if the error was due to a type-checking failure.
#-------------------------------------------------------------------------------
sub assert_in_the_machine {
  croak 'cannot be called outside a state machine definition block' unless $_;

  unless (!defined(my $msg = $Automata->validate_explain($_, '$_'))) {
    debug('Invalid machine state detected: %s', join("\n", map {" -$_"} @$msg));
    croak 'invalid machine definition';
  }
}

#-------------------------------------------------------------------------------
# Emits a debug message preceded by 'DEBUG> ' to STDERR when $DEBUG is true.
# Behaves like `warn(sprintf(@_))` in all other respects.
#-------------------------------------------------------------------------------
sub debug {
  return unless $DEBUG;
  my ($msg, @args) = @_;
  warn sprintf("# DEBUG> $msg\n", @args);
}

#-------------------------------------------------------------------------------
# Alias for Data::Dumper::Dumper with no Indent and Terse output.
#-------------------------------------------------------------------------------
sub explain {
  my $state = shift;
  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Terse  = 1;
  Dumper($state);
}

#-------------------------------------------------------------------------------
# Validate sanity as much as possible without strict types and without
# guarantees on the return type of transitions.
#-------------------------------------------------------------------------------
sub validate {
  assert_in_the_machine();

  croak 'no ready state defined'
    unless $_->{ready};

  croak 'no terminal state defined'
    unless $_->{term};

  croak 'terminal state and ready state are identical'
    if $_->{ready} eq $_->{term};

  croak 'no transitions defined'
    unless keys %{$_->{map}};

  croak 'no transition defined for ready state'
    unless $_->{map}{$_->{ready}}
        && @{$_->{map}{$_->{ready}}};

  my $is_terminated;

  foreach my $from (keys %{$_->{map}}) {
    croak 'invalid transition from terminal state detected'
      if $from eq $_->{term};

    foreach my $next (@{$_->{map}{$from}}) {
      my $to = $next->{to};

      if ($to eq $_->{term}) {
        $is_terminated = 1;
        next;
      }

      croak "no subsequent states are reachable from $to"
        unless exists $_->{map}{$to};
    }
  }

  croak 'no transition defined to terminal state'
    unless $is_terminated;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auto::Mata - A simple, reliable finite state machine

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Auto::Mata;
  use Types::Standard -types;

  my $NoData   = Undef,
  my $HasFirst = Tuple[Str];
  my $HasLast  = Tuple[Str, Str];
  my $Complete = Tuple[Str, Str, Int];

  sub get_input {
    my $query = shift;
    print "\n$query ";
    my $input = <STDIN>;
    chomp $input;
    return $input;
  }

  my $fsm = machine {
    ready 'READY';
    term  'TERM';

    transition 'READY', to 'FIRST',
      on $NoData,
      with { return [get_input("What is your first name? ")] };

    transition 'FIRST', to 'LAST',
      on $HasFirst,
      with { return [@$_, get_input("What is your last name? ")] };

    transition 'LAST', to 'AGE',
      on $HasLast,
      with { return [@$_, get_input("What is your age? ")] };

    transition 'AGE', to 'TERM',
      on $Complete;
  };

  my $prog = $fsm->();
  my $data = $prog->();

  printf "Hello %s %s, aged %d years!\n", @$data;

=head1 DESCRIPTION

Finite state machines (or automata) are a technique for modeling the workflow
of a program as a series of dependent, programmable steps. State machines are
useful tools for building software whose behavior can be predicted with a high
degree of confidence.

Using a state machine to implement a program helps to ensure determinacy, where
the program state is known at all times. Designing software this way leads to
greater accuracy and testability.

=head1 WHAT IS A STATE MACHINE

A program can be described as a set of discrete I<states>. Each state is
defined by the existence or value of a variable, the presence of a file, etc.
A state machine replaces the if/else clauses typically used to inspect and
branch based on run-time conditions.

Rather than performing ad hoc tests using if/else conditions, the program is
instead described as a set of I<transitions> which move the program from an
initial state to a final state. The state machine begins in the "ready" state.
The initial state is described using an identifier and a type constraint (see
L<Type::Tiny> and L<Types::Standard>).  When input matches the transition's
initial state, the transition step is executed, after which the new initial
state is the final state described in the transition. This proceeds until the
"terminal" state is reached.

=head1 EXPORTED SUBROUTINES

C<Auto::Mata> is an C<Exporter>. All subroutines are exported by default.

=head2 machine

Creates a lexical context in which a state machine is defined. Returns a
function that creates new instances of the defined automata.

The automata instance is itself a builder function. When called, it returns a
new function that accepts the initial program state as input and returns the
final state.

This instance function's input value in conjunction with the current state
label is matched (see L</on>) against the transition table (defined with
L</transition>) to determine the next state.

Once a match has been made, the action defined for the transition (using
L</with>) will be executed. During evaluation of the L</with> function, C<$_>
is a reference to the input value.

Note that the input state is modified in place during the transition.

  # Define the state machine
  my $builder = machine { ... };

  # Create an instance
  my $instance = $builder->();

  # Run the program to get the result
  my $result = $instance->($state_data);

If the builder function is called with a true value as the first argument, it
will instead build an interactive iterator that performs a single transition
per call. It accepts a single value as input representing the program's current
state.

The return value is new state's label in scalar context, the label and state in
list context, and C<undef> after the terminal state has been reached.

  # Define the state machine
  my $builder = machine { ... };

  # Create an instance of the machine
  my $program = $builder->();

  # Run the program
  my $state = [];
  while (my ($token, $data) = $program->($state)) {
    print "Current state is $token\n"; # $token == label of current state (e.g. READY)
    print "State data: @$data\n";      # $data == $state input to $program
  }

=head2 ready

Sets the name given to the "ready" state. This is the initial state held by the
state machine.

=head2 terminal

Sets the name given to the "terminal" state. This is the final state held by
the state machine. Once in this state, the machine will cease to perform any
more work.

=head2 term

Alias for L</terminal>.

=head2 transition

Defines a transition between two states by matching the symbol identifying the
state at the end of the most recent transition and the input passed into the
transition engine (see L</machine>) for the transition being performed.

The first argument to C<transition> is the symbol identifying the state at the
outset of the transition. A L<Type::Tiny> constraint is used to identify the
expected input using L</on>. When both of these match the current program
state, the return value of L</with> replaces the current input in place.
L</with> is permitted to the current input. If L</with> is not specified, the
input remains unchanged. Once the transition is complete, the symbol supplied
by L</to> will identify the current program state.

The first transition is always from the "ready" state. The final transition is
always to the "terminal" state. There may be no transitions from the "terminal"
state.

The following functions are used in concert with L</transition>.

=over

=item to

A name identifying the state held I<after> the transition.

=item on

A L<Type::Tiny> constraint that matches the state immediately I<before> the
transition.

=item with

A code block whose return value is the mutable state used to determine the next
transition to perform. Within the code block C<$_> is a reference to the
program state.

=item using

Alias for L</with> that may be used to avoid conflicts with other packages
exporting C<with>. Prevent the export of C<with> in the typical way (see
L<Exporter/Specialised-Import-Lists>).

  use Auto::Mata '!with';

  machine {
    ...

    transition 'INITIAL_STATE', to 'THE_NEXT_STATE',
      on Dict[command => Str, remember => Bool],
      with {
        if ($_->{command} eq 'fnord') {
          return {command => undef, remember => 0};
        }
        else {
          return {command => undef, remember => 1};
        }
      };
  };

=back

=head1 DEBUGGING

If C<$ENV{DEBUG_AUTOMATA}> is true, helpful debugging messages will be emitted
to C<STDERR>.

=head1 AUTHOR

Jeff Ober <jeffober@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
