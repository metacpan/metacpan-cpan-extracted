#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Non deterministic finite state machine from regular expression
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2018
#-------------------------------------------------------------------------------
# podDocumentation

package Data::NFA;
our $VERSION = "20191030";
require v5.26;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use utf8;

# NFA : bless {state=>{symbol=>state}, jumps=>{state=>1}, final=>true if final, return=>state to return to}

sub Element   {q(element)}                                                      # Components of an expression
sub Sequence  {q(sequence)}
sub Optional  {q(optional)}
sub ZeroOrMore{q(zeroOrMore)}
sub OneOrMore {q(oneOrMore)}
sub Choice    {q(choice)}
sub Except    {q(except)}

#D1 Construct regular expression                                                # Construct a regular expression that defines the language to be parsed using the following combining operations which can all be imported:

sub element($)                                                                  #S One element. An element can also be represented by a string or number
 {my ($label) = @_;                                                             # Transition symbol
  [Element, @_]
 }

sub sequence(@)                                                                 #S Sequence of elements and/or symbols.
 {my (@elements) = @_;                                                          # Elements
  [Sequence, @elements]
 }

sub optional(@)                                                                 #S An optional sequence of elements and/or symbols.
 {my (@element) = @_;                                                           # Elements
  [Optional, @element]
 }

sub zeroOrMore(@)                                                               #S Zero or more repetitions of a sequence of elements and/or symbols.
 {my (@element) = @_;                                                           # Elements
  [ZeroOrMore, @element]
 }

sub oneOrMore(@)                                                                #S One or more repetitions of a sequence of elements and/or symbols.
 {my (@element) = @_;                                                           # Elements
  [OneOrMore, @element]
 }

sub choice(@)                                                                   #S Choice from amongst one or more elements and/or symbols.
 {my (@elements) = @_;                                                          # Elements to be chosen from
  [Choice, @elements]
 }

sub except(@)                                                                   #S Choice from amongst all symbols except the ones mentioned
 {my (@elements) = @_;                                                          # Elements not to be chosen from
  [Except, @elements]
 }

#D1 Non Deterministic finite state machine

sub newState(%)                                                                 #P Create a new NFA state
 {my (%options) = @_;                                                           # NFA state as hash

  my $r = genHash(q(Data::NFA::State),                                          # NFA State
    transitions => undef,                                                       # {symbol => state} : transitions from this state consuming one input symbol
    jumps       => undef,                                                       # {jump   => 1}     : jumps from this state not consuming any input symbols
    final       => undef,                                                       # Whether this state is final
    return      => undef,                                                       # Return point
   );

  %$r = (%$r, %options);

  $r
 }

sub fromExpr2($$$)                                                              #P Create an NFA from a regular expression.
 {my ($states, $expr, $symbols) = @_;                                           # States, regular expression constructed from L<element|/element> L<sequence|/sequence> L<optional|/optional> L<zeroOrMore|/zeroOrMore> L<oneOrMore|/oneOrMore> L<choice|/choice>, set of symbols used by the NFA.
  $states       //= {};
  my $next        = sub{scalar keys %$states};                                  # Next state name
  my $last        = sub{&$next - 1};                                            # Last state created

  my $save        = sub                                                         # Save as a new state
   {my ($transitions, $jumps, $final) = @_;                                     # Transitions, jumps, final
    my $s = $states->{&$next} = newState
     (transitions => $transitions, jumps => $jumps, final => $final);
    $s;
   };

  my $jump        = sub                                                         # Add jumps
   {my ($from, @to) = @_;
    my $state = $states->{$from};
    $state->jumps->{$_}++ for @to
   };

  my $start       = &$next;                                                     # Start state

  if (!ref($expr))                                                              # Element not wrapped with element()
   {&$save({$expr=>$start+1}, undef);
   }
  else
   {my ($structure) = @$expr;
    if ($structure eq Element)                                                  # Element
     {my (undef, $element) = @$expr;
      &$save({$element=>$start+1}, undef);
     }
    elsif ($structure eq Sequence)                                              # Sequence of elements
     {my (undef, @elements) = @$expr;
      $states->fromExpr2($_, $symbols) for @elements;
     }
    elsif ($structure eq Optional)                                              # Optional element
     {my (undef, @elements) = @$expr;
      $states->fromExpr2($_, $symbols) for @elements;
      &$jump($start, &$next);                                                   # Optional so we have the option of jumping over it
     }
    elsif ($structure eq ZeroOrMore)                                            # Zero or more
     {my (undef, @elements) = @$expr;
      $states->fromExpr2($_, $symbols) for @elements;
      &$jump($start, &$next+1);                                                 # Optional so we have the option of jumping over it
      &$save(undef, {$start=>1});                                               # Repeated so we have the option of redoing it
     }
    elsif ($structure eq OneOrMore)                                             # One or more
     {my (undef, @elements) = @$expr;
      $states->fromExpr2($_, $symbols) for @elements;
      my $N = &$next;
      &$save();
      &$jump($N, $start, $N+1);                                                 # Do it again or move on
     }
    elsif ($structure eq Choice)                                                # Choice
     {my (undef, @elements) = @$expr;
      my @fix;
      for my $i(keys @elements)                                                 # Each element index
       {my $element = $elements[$i];                                            # Each element separate by a gap so we can not jump in then jump out
        if ($i)
         {&$jump($start, &$next)
         }
        $states->fromExpr2($element, $symbols);                                 # Choice
        if ($i < $#elements)
         {push @fix, &$next;
          &$save();                                                             # Fixed later to jump over subsequent choices
         }
       }
      my $N = &$next;                                                           # Fix intermediates
      &$jump($_, $N) for @fix;
     }
    elsif ($structure eq Except)                                                # Except
     {my (undef, @exclude) = @$expr;
      my %exclude = map{(ref $_ ? $$_[1] : $_)=>1} @exclude;                    # Names of elements to exclude
      my @fix;
      my @elements = grep {!$exclude{$_}}
                     sort keys %$symbols;                                       # Each element not excluded
      for my $i(keys @elements)                                                 # Each element index
       {my $element = $elements[$i];                                            # Each element separate by a gap so we can not jump in then jump out
        &$jump($start, &$next) if $i;
        $states->fromExpr2(element($element), $symbols);                        # Choice of not excluded symbols
        if ($i < $#elements)
         {push @fix, &$next;
          &$save();                                                             # Fixed later to jump over subsequent choices
         }
       }
      my $N = &$next;                                                           # Fix intermediates
#     &$save();
      &$jump($_, $N) for @fix;
     }
    else                                                                        # Unknown request
     {confess "Unknown structuring operation: $structure";
     }
   }
  $states
 }

sub propagateFinalState($)                                                      #P Mark the states that can reach the final  state with a jump as final
 {my ($states) = @_;                                                            # States
  my %checked;
  for(;;)
   {my $changes = 0;
    for my $stateName(sort keys %$states)                                       # Each state
     {my $state = $$states{$stateName};
      if (!$state->final)                                                       # Current state is not a final state
       {for my $jumpName(sort keys $state->jumps->%*)                           # Each jump
         {my $jump      = $$states{$jumpName};
          if (my $final = $jump->final)                                         # Target state is final
           {++$changes;
            $state->final = $final;                                             # Mark state as final
            last;
           }
         }
       }
     }
    last unless $changes;
   }
 }

sub statesReachableViaJumps($$)                                                 #P Find the names of all the states that can be reached from a specified state via jumps alone
 {my ($states, $StateName) = @_;                                                # States, name of start state
  my %reachable;
  my @check = ($StateName);
  my %checked;

  while(@check)                                                                 # Reachable from the start state by a single transition after zero or more jumps
   {my $stateName = pop @check;
    next if $checked{$stateName}++;
    my $state = $$states{$stateName};
    confess "No such state: $stateName" unless $state;
    $reachable{$_}++ for sort keys $state->jumps->%*;                           # States that can be reached via jumps
    push @check, sort keys $state->jumps->%*;                                   # Make a jump and try again
   }

  [sort keys %reachable]
 } # statesReachableViaJumps

sub fromExpr(@)                                                                 #S Create an NFA from a regular expression.
 {my (@expr) = @_;                                                              # Expressions
  my $states = bless {};
  my %symbols;                                                                  # Symbols named in expression
  my $symbols; $symbols = sub                                                   # Locate symbols
   {my ($expr) = @_;
    if (ref $expr)
     {$symbols{$$expr[1]}++ if $$expr[0] eq Element;                            # Add symbol enclosed in element
      my ($type, @elements) = @$expr;
      for(@elements)
       {ref $_ ? $symbols->($_) : $symbols{$_}++;
       }
     }
    else                                                                        # Process sub expressions
     {$symbols{$expr}++;                                                        # Add symbol not enclosed in element()
     }
   };
  $symbols->($_) for @expr;                                                     # Locate all symbols

  $states->fromExpr2($_, \%symbols) for @expr;                                  # Create state transitions
  $states->{keys %$states} = newState(final=>1);                                # End state

  for my $state(sort keys %$states)
   {$$states{$state}->jumps =
      {map {$_=>1} @{statesReachableViaJumps($states, $state)}};
   }

  $states->propagateFinalState;
  $states
 }

sub printWithJumps($$;$)                                                        #P Print the current state of an NFA with jumps.
 {my ($states, $title, $print) = @_;                                            # States, title, print to STDERR if 2 or to STDOUT if 1
  my @o;
  push @o, [qw(Location  F Transitions Jumps)];
  for(sort{$a <=> $b} keys %$states)
   {my $d = $states->{$_};
    my @j = sort {$a <=> $b} keys %{$d->jumps};
    push @o, [sprintf("%4d", $_), $d->final//0,
              dump($d->transitions), dump(@j ? [@j]:undef)];
   }
  "$title\n". formatTableBasic([@o]);
 }

sub printWithOutJumps($$;$)                                                     #P Print the current state of an NFA without jumps
 {my ($states, $title, $print) = @_;                                            # States, title, print to STDERR if 2 or to STDOUT if 1
  my @o;
  push @o, [qw(Location  F Transitions)];
  for(sort{$a <=> $b} keys %$states)
   {my $d = $states->{$_};
    push @o, [sprintf("%4d", $_), $d->final//0, dump($d->transitions)];
   }
  "$title\n". formatTableBasic([@o]);
 }

sub print($$)                                                                   # Print the current state of the finite automaton. If it is non deterministic, the non deterministic jumps will be shown as well as the transitions table. If deterministic, only the transitions table will be shown.
 {my ($states, $title) = @_;                                                    # States, title
  my $j = 0;                                                                    # Number of non deterministic jumps encountered
  for(sort{$a <=> $b} keys %$states)
   {my $d = $states->{$_};
    my @j = sort keys %{$d->jumps};
    ++$j if @j > 0;
   }
  if ($j) {&printWithJumps(@_)} else {&printWithOutJumps(@_)}
 }

sub symbols($)                                                                  # Return an array of all the transition symbols.
 {my ($states) = @_;                                                            # States
  my %s;
  for(keys %$states)
   {my $d = $$states{$_};
    if ($d->transitions)
     {$s{$_}++ for sort keys $d->transitions->%*;
     }
   }
  sort keys %s
 }

sub isFinal($$)                                                                 # Whether this is a final state or not
 {my ($states, $stateName) = @_;                                                # States, name of state

  my $f = $$states{$stateName}->final;
  $f ? $f : undef;
 }

sub statesReachableViaSymbol($$$$)                                              #P Find the names of all the states that can be reached from a specified state via a specified symbol and all the jumps available.
 {my ($states, $StateName, $symbol, $cache) = @_;                               # States, name of start state, symbol to reach on, a hash to be used as a cache
  my %reachable;
  my @check = ($StateName);
  my %checked;

  while(@check)                                                                 # Reachable from the start state by a single transition after zero or more jumps
   {my $stateName = pop @check;
    next if $checked{$stateName}++;
    my $state = $$states{$stateName};
    confess "No such state: $stateName" unless $state;

    if ($state->transitions)
     {if (my $t = $state->transitions->{$symbol})                               # Transition on the symbol
       {$reachable{$t}++;
        $reachable{$_}++
          for @{$$cache{$t} //= statesReachableViaJumps($states, $t)};          # Cache results of this expensive call
       }
     }
    push @check, sort keys $state->jumps->%*;                                   # Make a jump and try again
   }

  [sort keys %reachable]
 } # statesReachableViaSymbol

sub allTransitions($)                                                           # Return all transitions in the NFA as {stateName}{symbol} = [reachable states]
 {my ($states) = @_;                                                            # States
  my $symbols = [$states->symbols];                                             # Symbols in nfa
  my $cache = {};                                                               # Cache results

  my $nfaSymbolTransitions;
  for my $StateName(sort keys %$states)                                         # Each NFA state
   {my (%reachable, %checked);
    my @check;
    my ($stateName, $state, $transitions, $jumps, $to);

    my $target = $$nfaSymbolTransitions{$StateName} = {};
    for my $symbol(@$symbols)                                                   # Each NFA symbol
     {my $statesReachableViaSymbol = sub                                        #P Find the names of all the states that can be reached from a specified state via a specified symbol and all the jumps available.
       {%reachable = ();
        @check     = ($StateName);
        %checked   = ();

        while(@check)                                                           # Reachable from the start state by a single transition after zero or more jumps
         {$stateName = pop @check;
          next if $checked{$stateName}++;
          $state = $$states{$stateName};
          confess "No such state: $stateName" unless $state;
          $transitions = $state->transitions;
          $jumps       = $state->jumps;

          if (defined($to = $$transitions{$symbol}))                            # Transition on the symbol
           {$reachable{$to}++;
            $reachable{$_}++
              for @{$$cache{$to} //= statesReachableViaJumps($states, $to)};    # Cache results of this expensive call
           }
          push @check, keys %$jumps;                                            # Make a jump and try again
         }

        [sort keys %reachable]                                                  # List of reachable states
       }; # statesReachableViaSymbol

      $$target{$symbol} = &$statesReachableViaSymbol;                           # States in the NFA reachable on the symbol
     }
   }

  $nfaSymbolTransitions
 } # allTransitions

sub parse2($$@)                                                                 #P Parse an array of symbols
 {my ($states, $stateName, @symbols) = @_;                                      # States, current state, remaining symbols

  if (my $final = $$states{$stateName}->final)                                  # Return success if we are in a final state with no more symbols to parse
   {return 1 unless @symbols;
   }

  return 0 unless @symbols;                                                     # No more symbols but not in a final state

  my ($symbol, @remainder) = @symbols;                                          # Current symbol to parse
  my $reachable = statesReachableViaSymbol($states, $stateName, $symbol, {});   # States reachable from the current state via the current symbol

  for my $nextState(@$reachable)                                                # Each state reachable from the current state
   {my $result = &parse2($states, $nextState, @remainder);                      # Try each reachable state
    return $result if $result;                                                  # Propagate success if a solution was found
   }

  undef                                                                         # No path to a final state found
 }

sub parse($@)                                                                   # Parse an array of symbols
 {my ($states, @symbols) = @_;                                                  # States, array of symbols

  parse2($states, 0, @symbols);
 }

#D0
#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT_OK    = qw(
choice
element
except
oneOrMore optional
sequence
zeroOrMore
);
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Data::NFA - Non deterministic finite state machine from regular expression.

=head1 Synopsis

Create a non deterministic finite state machine from a regular expression which
can then be converted into a deterministic finite state machine by L<Data::DFA>
and used to parse sequences of symbols.

For example, the regular expression:

  ((a|b)*)**4

produces the following machine:

  use Data::NFA qw(:all);
  use Data::Table::Text qw(:all);
  use Test::More qw(no_plan);

  my $N = 4;

  my $s = q(zeroOrMore(choice(element("a"), element("b"))));

  my $nfa = eval qq(fromExpr(($s)x$N));

  ok $nfa->printNws("((a|b)*)**$N: ") eq nws <<END;
((a|b)*)**4:
Location  F  Transitions  Jumps
       0  1  { a => 1 }   [2, 4, 6, 8, 10, 12, 14, 16]
       1  1  undef        [0, 2, 3, 4, 6, 8, 10, 12, 14, 16]
       2  0  { b => 3 }   undef
       3  1  undef        [0, 2, 4, 6, 8, 10, 12, 14, 16]
       4  1  { a => 5 }   [6, 8, 10, 12, 14, 16]
       5  1  undef        [4, 6, 7, 8, 10, 12, 14, 16]
       6  0  { b => 7 }   undef
       7  1  undef        [4, 6, 8, 10, 12, 14, 16]
       8  1  { a => 9 }   [10, 12, 14, 16]
       9  1  undef        [8, 10, 11, 12, 14, 16]
      10  0  { b => 11 }  undef
      11  1  undef        [8, 10, 12, 14, 16]
      12  1  { a => 13 }  [14, 16]
      13  1  undef        [12, 14, 15, 16]
      14  0  { b => 15 }  undef
      15  1  undef        [12, 14, 16]
      16  1  undef        undef
END

=head1 Description

Non deterministic finite state machine from regular expression.


Version "20181027".


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Construct regular expression

Construct a regular expression that defines the language to be parsed using the following combining operations which can all be imported:

=head2 element($)

One element. An element can also be represented by a string or number

     Parameter  Description
  1  $label     Transition symbol

B<Example:>


  if (1) {
    my $nfa = fromExpr(𝗲𝗹𝗲𝗺𝗲𝗻𝘁("a"));
    ok $nfa->print("Element: a") eq <<END;
  Element: a
  Location  F  Transitions
         0  0  { a => 1 }
         1  1  undef
  END
    ok  $nfa->isFinal(1);
    ok !$nfa->isFinal(0);
    ok  $nfa->parse(qw(a));
    ok !$nfa->parse(qw(a b));
    ok !$nfa->parse(qw(b));
    ok !$nfa->parse(qw(b a));
   }


This is a static method and so should be invoked as:

  Data::NFA::element


=head2 sequence(@)

Sequence of elements and/or symbols.

     Parameter  Description
  1  @elements  Elements

B<Example:>


  if (1) {
    my $nfa = fromExpr(𝘀𝗲𝗾𝘂𝗲𝗻𝗰𝗲(element("a"), element("b")));
    ok $nfa->print("Sequence: ab") eq <<END;
  Sequence: ab
  Location  F  Transitions
         0  0  { a => 1 }
         1  0  { b => 2 }
         2  1  undef
  END
    ok  $nfa->parse(qw(a b));
    ok !$nfa->parse(qw(b a));
    ok !$nfa->parse(qw(a));
    ok !$nfa->parse(qw(b));
   }


This is a static method and so should be invoked as:

  Data::NFA::sequence


=head2 optional(@)

An optional sequence of elements and/or symbols.

     Parameter  Description
  1  @element   Elements

B<Example:>


  if (1) {
    my $nfa = fromExpr(element("a"), 𝗼𝗽𝘁𝗶𝗼𝗻𝗮𝗹(element("b")), element("c"));
    ok $nfa->print("Optional: ab?c") eq <<END;
  Optional: ab?c
  Location  F  Transitions  Jumps
         0  0  { a => 1 }   undef
         1  0  { b => 2 }   [2]
         2  0  { c => 3 }   undef
         3  1  undef        undef
  END
    ok  $nfa->parse(qw(a b c));
    ok  $nfa->parse(qw(a c));
    ok !$nfa->parse(qw(a c b));
   }


This is a static method and so should be invoked as:

  Data::NFA::optional


=head2 zeroOrMore(@)

Zero or more repetitions of a sequence of elements and/or symbols.

     Parameter  Description
  1  @element   Elements

B<Example:>


  if (1) {
    my $nfa = fromExpr(element("a"), 𝘇𝗲𝗿𝗼𝗢𝗿𝗠𝗼𝗿𝗲(element("b")), element("c"));
    ok $nfa->print("Zero Or More: ab*c") eq <<END;
  Zero Or More: ab*c
  Location  F  Transitions  Jumps
         0  0  { a => 1 }   undef
         1  0  { b => 2 }   [3]
         2  0  undef        [1, 3]
         3  0  { c => 4 }   undef
         4  1  undef        undef
  END
    ok  $nfa->parse(qw(a c));
    ok  $nfa->parse(qw(a b c));
    ok  $nfa->parse(qw(a b b c));
    ok !$nfa->parse(qw(a b b d));
   }

  if (1) {
    my $nfa = fromExpr(element("a"),
                       𝘇𝗲𝗿𝗼𝗢𝗿𝗠𝗼𝗿𝗲(choice(element("a"),
                       element("a"))),
                       element("a"));
    ok $nfa->print("aChoice: (a(a|a)*a") eq <<END;
  aChoice: (a(a|a)*a
  Location  F  Transitions  Jumps
         0  0  { a => 1 }   undef
         1  0  { a => 2 }   [3, 5]
         2  0  undef        [1, 3, 4, 5]
         3  0  { a => 4 }   undef
         4  0  undef        [1, 3, 5]
         5  0  { a => 6 }   undef
         6  1  undef        undef
  END

    is_deeply [1 .. 6],     $nfa->statesReachableViaSymbol(1, "a");
    is_deeply [1 .. 6],     $nfa->statesReachableViaSymbol(2, "a");
    is_deeply [1, 3, 4, 5], $nfa->statesReachableViaSymbol(3, "a");

    ok !$nfa->parse(qw(a));
    ok  $nfa->parse(qw(a a));
    ok  $nfa->parse(qw(a a a));
    ok !$nfa->parse(qw(a b a));
   }


This is a static method and so should be invoked as:

  Data::NFA::zeroOrMore


=head2 oneOrMore(@)

One or more repetitions of a sequence of elements and/or symbols.

     Parameter  Description
  1  @element   Elements

B<Example:>


  if (1) {
    my $nfa = fromExpr(element("a"), 𝗼𝗻𝗲𝗢𝗿𝗠𝗼𝗿𝗲(element("b")), element("c"));

    ok $nfa->print("One or More: ab+c") eq <<END;
  One or More: ab+c
  Location  F  Transitions  Jumps
         0  0  { a => 1 }   undef
         1  0  { b => 2 }   undef
         2  0  undef        [1, 3]
         3  0  { c => 4 }   undef
         4  1  undef        undef
  END

    is_deeply [],     $nfa->statesReachableViaSymbol(2,"a");
    is_deeply [1..3], $nfa->statesReachableViaSymbol(2,"b");
    is_deeply [4],    $nfa->statesReachableViaSymbol(2,"c");

    ok !$nfa->parse(qw(a c));
    ok  $nfa->parse(qw(a b c));
    ok  $nfa->parse(qw(a b b c));
    ok !$nfa->parse(qw(a b b d));
   }


This is a static method and so should be invoked as:

  Data::NFA::oneOrMore


=head2 choice(@)

Choice from amongst one or more elements and/or symbols.

     Parameter  Description
  1  @elements  Elements to be chosen from

B<Example:>


  if (1) {
    my $nfa = fromExpr(element("a"),
                       𝗰𝗵𝗼𝗶𝗰𝗲(element("b"), element("c")),
                       element("d"));
    ok $nfa->print("Choice: (a(b|c)d") eq <<END;
  Choice: (a(b|c)d
  Location  F  Transitions  Jumps
         0  0  { a => 1 }   undef
         1  0  { b => 2 }   [3]
         2  0  undef        [4]
         3  0  { c => 4 }   undef
         4  0  { d => 5 }   undef
         5  1  undef        undef
  END

    is_deeply [],     $nfa->statesReachableViaSymbol(1, "a");
    is_deeply [2, 4], $nfa->statesReachableViaSymbol(1, "b");
    is_deeply [4],    $nfa->statesReachableViaSymbol(1, "c");
    is_deeply ['a'..'d'], [$nfa->symbols];

    ok  $nfa->parse(qw(a b d));
    ok  $nfa->parse(qw(a c d));
    ok !$nfa->parse(qw(a b c d));
   }


This is a static method and so should be invoked as:

  Data::NFA::choice


=head2 except(@)

Choice from amongst all symbols except the ones mentioned

     Parameter  Description
  1  @elements  Elements not to be chosen from

B<Example:>


  if (1) {
    my $nfa = fromExpr(choice(qw(a b c)), 𝗲𝘅𝗰𝗲𝗽𝘁(qw(c x)), choice(qw(a b c)));

    ok $nfa->print("(a|b|c)(c!x)(a|b|c):") eq <<END;
  (a|b|c)(c!x)(a|b|c):
  Location  F  Transitions  Jumps
         0  0  { a => 1 }   [2, 4]
         1  0  undef        [5, 7]
         2  0  { b => 3 }   undef
         3  0  undef        [5, 7]
         4  0  { c => 5 }   undef
         5  0  { a => 6 }   [7]
         6  0  undef        [8, 10, 12]
         7  0  { b => 8 }   undef
         8  0  { a => 9 }   [10, 12]
         9  1  undef        [13]
        10  0  { b => 11 }  undef
        11  1  undef        [13]
        12  0  { c => 13 }  undef
        13  1  undef        undef
  END

    ok !$nfa->parse(qw(a a));
    ok  $nfa->parse(qw(a a a));
    ok !$nfa->parse(qw(a c a));
   }


This is a static method and so should be invoked as:

  Data::NFA::except


=head1 Non Deterministic finite state machine

=head2 fromExpr(@)

Create an NFA from a regular expression.

     Parameter  Description
  1  @expr      Expressions

B<Example:>


  if (1) {
    my $nfa = 𝗳𝗿𝗼𝗺𝗘𝘅𝗽𝗿
     (element("a"),
      oneOrMore(choice(qw(b c))),
      optional(element("d")),
      element("e")
     );

    ok $nfa->print("a(b|c)+d?e :") eq <<END;
  a(b|c)+d?e :
  Location  F  Transitions  Jumps
         0  0  { a => 1 }   undef
         1  0  { b => 2 }   [3]
         2  0  undef        [1, 3 .. 6]
         3  0  { c => 4 }   undef
         4  0  undef        [1, 3, 5, 6]
         5  0  { d => 6 }   [6]
         6  0  { e => 7 }   undef
         7  1  undef        undef
  END


    is_deeply ['a'..'e'], [$nfa->symbols];

    ok !$nfa->parse(qw(a e));
    ok !$nfa->parse(qw(a d e));
    ok  $nfa->parse(qw(a b c e));
    ok  $nfa->parse(qw(a b c d e));
   }


This is a static method and so should be invoked as:

  Data::NFA::fromExpr


=head2 print($$)

Print the current state of the finite automaton. If it is non deterministic, the non deterministic jumps will be shown as well as the transitions table. If deterministic, only the transitions table will be shown.

     Parameter  Description
  1  $states    States
  2  $title     Title

B<Example:>


  if (1) {
    my $nfa = fromExpr
     (element("a"),
      oneOrMore(choice(qw(b c))),
      optional(element("d")),
      element("e")
     );

    ok $nfa->𝗽𝗿𝗶𝗻𝘁("a(b|c)+d?e :") eq <<END;
  a(b|c)+d?e :
  Location  F  Transitions  Jumps
         0  0  { a => 1 }   undef
         1  0  { b => 2 }   [3]
         2  0  undef        [1, 3 .. 6]
         3  0  { c => 4 }   undef
         4  0  undef        [1, 3, 5, 6]
         5  0  { d => 6 }   [6]
         6  0  { e => 7 }   undef
         7  1  undef        undef
  END


    is_deeply ['a'..'e'], [$nfa->symbols];

    ok !$nfa->parse(qw(a e));
    ok !$nfa->parse(qw(a d e));
    ok  $nfa->parse(qw(a b c e));
    ok  $nfa->parse(qw(a b c d e));
   }


=head2 symbols($)

Return an array of all the transition symbols.

     Parameter  Description
  1  $states    States

B<Example:>


  if (1) {
    my $nfa = fromExpr
     (element("a"),
      oneOrMore(choice(qw(b c))),
      optional(element("d")),
      element("e")
     );

    ok $nfa->print("a(b|c)+d?e :") eq <<END;
  a(b|c)+d?e :
  Location  F  Transitions  Jumps
         0  0  { a => 1 }   undef
         1  0  { b => 2 }   [3]
         2  0  undef        [1, 3 .. 6]
         3  0  { c => 4 }   undef
         4  0  undef        [1, 3, 5, 6]
         5  0  { d => 6 }   [6]
         6  0  { e => 7 }   undef
         7  1  undef        undef
  END


    is_deeply ['a'..'e'], [$nfa->𝘀𝘆𝗺𝗯𝗼𝗹𝘀];

    ok !$nfa->parse(qw(a e));
    ok !$nfa->parse(qw(a d e));
    ok  $nfa->parse(qw(a b c e));
    ok  $nfa->parse(qw(a b c d e));
   }


=head2 isFinal($$)

Whether this is a final state or not

     Parameter   Description
  1  $states     States
  2  $stateName  Name of state

B<Example:>


  if (1) {
    my $nfa = fromExpr(element("a"));
    ok $nfa->print("Element: a") eq <<END;
  Element: a
  Location  F  Transitions
         0  0  { a => 1 }
         1  1  undef
  END
    ok  $nfa->𝗶𝘀𝗙𝗶𝗻𝗮𝗹(1);
    ok !$nfa->𝗶𝘀𝗙𝗶𝗻𝗮𝗹(0);
    ok  $nfa->parse(qw(a));
    ok !$nfa->parse(qw(a b));
    ok !$nfa->parse(qw(b));
    ok !$nfa->parse(qw(b a));
   }


=head2 allTransitions($)

Return all transitions in the NFA as {stateName}{symbol} = [reachable states]

     Parameter  Description
  1  $states    States

B<Example:>


  if (1) {
    my $s = q(zeroOrMore(choice(element("a"))));

    my $nfa = eval qq(fromExpr(sequence($s,$s)));

    ok $nfa->print("a*a* 1:") eq <<END;
  a*a* 1:
  Location  F  Transitions  Jumps
         0  1  { a => 1 }   [2, 4]
         1  1  undef        [0, 2, 4]
         2  1  { a => 3 }   [4]
         3  1  undef        [2, 4]
         4  1  undef        undef
  END

    is_deeply [0 .. 4],  $nfa->statesReachableViaSymbol(0, q(a));
    is_deeply [0 .. 4],  $nfa->statesReachableViaSymbol(1, q(a));
    is_deeply [2, 3, 4], $nfa->statesReachableViaSymbol(2, q(a));
    is_deeply [2, 3, 4], $nfa->statesReachableViaSymbol(3, q(a));

    is_deeply $nfa->𝗮𝗹𝗹𝗧𝗿𝗮𝗻𝘀𝗶𝘁𝗶𝗼𝗻𝘀, {
    "0" => { a => [0 .. 4] },
    "1" => { a => [0 .. 4] },
    "2" => { a => [2, 3, 4] },
    "3" => { a => [2, 3, 4] },
    "4" => { a => [] },
    };

    ok $nfa->print("a*a* 2:") eq <<END;
  a*a* 2:
  Location  F  Transitions  Jumps
         0  1  { a => 1 }   [2, 4]
         1  1  undef        [0, 2, 4]
         2  1  { a => 3 }   [4]
         3  1  undef        [2, 4]
         4  1  undef        undef
  END
   }


=head2 parse($@)

Parse an array of symbols

     Parameter  Description
  1  $states    States
  2  @symbols   Array of symbols

B<Example:>


  if (1) {
    my $nfa = fromExpr(element("a"));
    ok $nfa->print("Element: a") eq <<END;
  Element: a
  Location  F  Transitions
         0  0  { a => 1 }
         1  1  undef
  END
    ok  $nfa->isFinal(1);
    ok !$nfa->isFinal(0);
    ok  $nfa->𝗽𝗮𝗿𝘀𝗲(qw(a));
    ok !$nfa->𝗽𝗮𝗿𝘀𝗲(qw(a b));
    ok !$nfa->𝗽𝗮𝗿𝘀𝗲(qw(b));
    ok !$nfa->𝗽𝗮𝗿𝘀𝗲(qw(b a));
   }



=head2 Data::NFA::State Definition


NFA State




=head3 Output fields


B<final> - Whether this state is final

B<jumps> - {jump   => 1}     : jumps from this state not consuming any input symbols

B<return> - Return point

B<transitions> - {symbol => state} : transitions from this state consuming one input symbol



=head1 Private Methods

=head2 newState(%)

Create a new NFA state

     Parameter  Description
  1  %options   NFA state as hash

=head2 fromExpr2($$$)

Create an NFA from a regular expression.

     Parameter  Description
  1  $states    States
  2  $expr      Regular expression constructed from L<element|/element> L<sequence|/sequence> L<optional|/optional> L<zeroOrMore|/zeroOrMore> L<oneOrMore|/oneOrMore> L<choice|/choice>
  3  $symbols   Set of symbols used by the NFA.

=head2 propagateFinalState($)

Mark the states that can reach the final  state with a jump as final

     Parameter  Description
  1  $states    States

=head2 statesReachableViaJumps($$)

Find the names of all the states that can be reached from a specified state via jumps alone

     Parameter   Description
  1  $states     States
  2  $StateName  Name of start state

=head2 printWithJumps($$$)

Print the current state of an NFA with jumps.

     Parameter  Description
  1  $states    States
  2  $title     Title
  3  $print     Print to STDERR if 2 or to STDOUT if 1

=head2 printWithOutJumps($$$)

Print the current state of an NFA without jumps

     Parameter  Description
  1  $states    States
  2  $title     Title
  3  $print     Print to STDERR if 2 or to STDOUT if 1

=head2 statesReachableViaSymbol($$$$)

Find the names of all the states that can be reached from a specified state via a specified symbol and all the jumps available.

     Parameter   Description
  1  $states     States
  2  $StateName  Name of start state
  3  $symbol     Symbol to reach on
  4  $cache      A hash to be used as a cache

=head2 parse2($$@)

Parse an array of symbols

     Parameter   Description
  1  $states     States
  2  $stateName  Current state
  3  @symbols    Remaining symbols


=head1 Index


1 L<allTransitions|/allTransitions> - Return all transitions in the NFA as {stateName}{symbol} = [reachable states]

2 L<choice|/choice> - Choice from amongst one or more elements and/or symbols.

3 L<element|/element> - One element.

4 L<except|/except> - Choice from amongst all symbols except the ones mentioned

5 L<fromExpr|/fromExpr> - Create an NFA from a regular expression.

6 L<fromExpr2|/fromExpr2> - Create an NFA from a regular expression.

7 L<isFinal|/isFinal> - Whether this is a final state or not

8 L<newState|/newState> - Create a new NFA state

9 L<oneOrMore|/oneOrMore> - One or more repetitions of a sequence of elements and/or symbols.

10 L<optional|/optional> - An optional sequence of elements and/or symbols.

11 L<parse|/parse> - Parse an array of symbols

12 L<parse2|/parse2> - Parse an array of symbols

13 L<print|/print> - Print the current state of the finite automaton.

14 L<printWithJumps|/printWithJumps> - Print the current state of an NFA with jumps.

15 L<printWithOutJumps|/printWithOutJumps> - Print the current state of an NFA without jumps

16 L<propagateFinalState|/propagateFinalState> - Mark the states that can reach the final  state with a jump as final

17 L<sequence|/sequence> - Sequence of elements and/or symbols.

18 L<statesReachableViaJumps|/statesReachableViaJumps> - Find the names of all the states that can be reached from a specified state via jumps alone

19 L<statesReachableViaSymbol|/statesReachableViaSymbol> - Find the names of all the states that can be reached from a specified state via a specified symbol and all the jumps available.

20 L<symbols|/symbols> - Return an array of all the transition symbols.

21 L<zeroOrMore|/zeroOrMore> - Zero or more repetitions of a sequence of elements and/or symbols.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Data::NFA

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2019 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
__DATA__
use warnings FATAL=>qw(all);
use strict;
use Test::More tests=>81;

#goto latestTest;

if (1) {                                                                        #Telement #TisFinal #Tparse
  my $nfa = fromExpr(element("a"));
  ok $nfa->print("Element: a") eq <<END;
Element: a
Location  F  Transitions
       0  0  { a => 1 }
       1  1  undef
END
  ok  $nfa->isFinal(1);
  ok !$nfa->isFinal(0);
  ok  $nfa->parse(qw(a));
  ok !$nfa->parse(qw(a b));
  ok !$nfa->parse(qw(b));
  ok !$nfa->parse(qw(b a));
 }

if (1)
 {my $nfa = fromExpr(q(b));
  ok $nfa->print("Element: b") eq <<END;
Element: b
Location  F  Transitions
       0  0  { b => 1 }
       1  1  undef
END
  ok  $nfa->isFinal(1);
  ok !$nfa->isFinal(0);
 }

if (1)
 {my $nfa = fromExpr(2);
  ok $nfa->print("Element: 2") eq <<END;
Element: 2
Location  F  Transitions
       0  0  { 2 => 1 }
       1  1  undef
END
  ok  $nfa->isFinal(1);
  ok !$nfa->isFinal(0);
 }

if (1) {                                                                        #Tsequence
  my $nfa = fromExpr(sequence(element("a"), element("b")));
  ok $nfa->print("Sequence: ab") eq <<END;
Sequence: ab
Location  F  Transitions
       0  0  { a => 1 }
       1  0  { b => 2 }
       2  1  undef
END
  ok  $nfa->parse(qw(a b));
  ok !$nfa->parse(qw(b a));
  ok !$nfa->parse(qw(a));
  ok !$nfa->parse(qw(b));
 }

if (1) {                                                                        #Toptional
  my $nfa = fromExpr(element("a"), optional(element("b")), element("c"));
  ok $nfa->print("Optional: ab?c") eq <<END;
Optional: ab?c
Location  F  Transitions  Jumps
       0  0  { a => 1 }   undef
       1  0  { b => 2 }   [2]
       2  0  { c => 3 }   undef
       3  1  undef        undef
END
  ok  $nfa->parse(qw(a b c));
  ok  $nfa->parse(qw(a c));
  ok !$nfa->parse(qw(a c b));
 }

if (1) {                                                                        #TzeroOrMore
  my $nfa = fromExpr(element("a"), zeroOrMore(element("b")), element("c"));
  ok $nfa->print("Zero Or More: ab*c") eq <<END;
Zero Or More: ab*c
Location  F  Transitions  Jumps
       0  0  { a => 1 }   undef
       1  0  { b => 2 }   [3]
       2  0  undef        [1, 3]
       3  0  { c => 4 }   undef
       4  1  undef        undef
END
  ok  $nfa->parse(qw(a c));
  ok  $nfa->parse(qw(a b c));
  ok  $nfa->parse(qw(a b b c));
  ok !$nfa->parse(qw(a b b d));
 }

if (1) {                                                                        #ToneOrMore
  my $nfa = fromExpr(element("a"), oneOrMore(element("b")), element("c"));

  ok $nfa->print("One or More: ab+c") eq <<END;
One or More: ab+c
Location  F  Transitions  Jumps
       0  0  { a => 1 }   undef
       1  0  { b => 2 }   undef
       2  0  undef        [1, 3]
       3  0  { c => 4 }   undef
       4  1  undef        undef
END

  is_deeply [],     $nfa->statesReachableViaSymbol(2,"a");
  is_deeply [1..3], $nfa->statesReachableViaSymbol(2,"b");
  is_deeply [4],    $nfa->statesReachableViaSymbol(2,"c");

  ok !$nfa->parse(qw(a c));
  ok  $nfa->parse(qw(a b c));
  ok  $nfa->parse(qw(a b b c));
  ok !$nfa->parse(qw(a b b d));
 }

if (1) {                                                                        #Tchoice
  my $nfa = fromExpr(element("a"),
                     choice(element("b"), element("c")),
                     element("d"));
  ok $nfa->print("Choice: (a(b|c)d") eq <<END;
Choice: (a(b|c)d
Location  F  Transitions  Jumps
       0  0  { a => 1 }   undef
       1  0  { b => 2 }   [3]
       2  0  undef        [4]
       3  0  { c => 4 }   undef
       4  0  { d => 5 }   undef
       5  1  undef        undef
END

  is_deeply [],     $nfa->statesReachableViaSymbol(1, "a");
  is_deeply [2, 4], $nfa->statesReachableViaSymbol(1, "b");
  is_deeply [4],    $nfa->statesReachableViaSymbol(1, "c");
  is_deeply ['a'..'d'], [$nfa->symbols];

  ok  $nfa->parse(qw(a b d));
  ok  $nfa->parse(qw(a c d));
  ok !$nfa->parse(qw(a b c d));
 }

if (1) {                                                                        #TzeroOrMore
  my $nfa = fromExpr(element("a"),
                     zeroOrMore(choice(element("a"),
                     element("a"))),
                     element("a"));
  ok $nfa->print("aChoice: (a(a|a)*a") eq <<END;
aChoice: (a(a|a)*a
Location  F  Transitions  Jumps
       0  0  { a => 1 }   undef
       1  0  { a => 2 }   [3, 5]
       2  0  undef        [1, 3, 4, 5]
       3  0  { a => 4 }   undef
       4  0  undef        [1, 3, 5]
       5  0  { a => 6 }   undef
       6  1  undef        undef
END

  is_deeply [1 .. 6],     $nfa->statesReachableViaSymbol(1, "a");
  is_deeply [1 .. 6],     $nfa->statesReachableViaSymbol(2, "a");
  is_deeply [1, 3, 4, 5], $nfa->statesReachableViaSymbol(3, "a");

  ok !$nfa->parse(qw(a));
  ok  $nfa->parse(qw(a a));
  ok  $nfa->parse(qw(a a a));
  ok !$nfa->parse(qw(a b a));
 }

if (1)
 {my $nfa = fromExpr(element("a"),
                     zeroOrMore(choice(element("b"), element("c"))),
                     element("d"));
  ok $nfa->print("aChoice: (a(b|c)*d") eq <<END;
aChoice: (a(b|c)*d
Location  F  Transitions  Jumps
       0  0  { a => 1 }   undef
       1  0  { b => 2 }   [3, 5]
       2  0  undef        [1, 3, 4, 5]
       3  0  { c => 4 }   undef
       4  0  undef        [1, 3, 5]
       5  0  { d => 6 }   undef
       6  1  undef        undef
END

  ok  $nfa->parse(qw(a d));
  ok  $nfa->parse(qw(a b b c c b b d));
  ok !$nfa->parse(qw(a d b));
 }

if (1) {                                                                        #TfromExpr #Tprint #Tsymbols #Tparser
  my $nfa = fromExpr
   (element("a"),
    oneOrMore(choice(qw(b c))),
    optional(element("d")),
    element("e")
   );

  ok $nfa->print("a(b|c)+d?e :") eq <<END;
a(b|c)+d?e :
Location  F  Transitions  Jumps
       0  0  { a => 1 }   undef
       1  0  { b => 2 }   [3]
       2  0  undef        [1, 3 .. 6]
       3  0  { c => 4 }   undef
       4  0  undef        [1, 3, 5, 6]
       5  0  { d => 6 }   [6]
       6  0  { e => 7 }   undef
       7  1  undef        undef
END


  is_deeply ['a'..'e'], [$nfa->symbols];

  ok !$nfa->parse(qw(a e));
  ok !$nfa->parse(qw(a d e));
  ok  $nfa->parse(qw(a b c e));
  ok  $nfa->parse(qw(a b c d e));
 }

if (1)
 {my $s = q(choice(element(q(a)), element(q(b))));
  my $nfa = eval qq(fromExpr($s));

  ok $nfa->print("(a|b):") eq <<END;
(a|b):
Location  F  Transitions  Jumps
       0  0  { a => 1 }   [2]
       1  1  undef        [3]
       2  0  { b => 3 }   undef
       3  1  undef        undef
END

  ok  $nfa->parse(qw(a));
  ok  $nfa->parse(qw(b));
  ok !$nfa->parse(qw(c));
  ok !$nfa->parse(qw(a b));
 }

if (1)
 {my $s = q(choice(qw(a b)));
  my $nfa = eval qq(fromExpr($s));

  ok $nfa->print("(a|b):") eq <<END;
(a|b):
Location  F  Transitions  Jumps
       0  0  { a => 1 }   [2]
       1  1  undef        [3]
       2  0  { b => 3 }   undef
       3  1  undef        undef
END
 }

if (1)
 {my $s = q(choice(element("a"), element("b")));
  my $nfa = eval qq(fromExpr(sequence($s,$s)));

  ok $nfa->print("(a|b)(a|b):") eq <<END;
(a|b)(a|b):
Location  F  Transitions  Jumps
       0  0  { a => 1 }   [2]
       1  0  undef        [3, 5]
       2  0  { b => 3 }   undef
       3  0  { a => 4 }   [5]
       4  1  undef        [6]
       5  0  { b => 6 }   undef
       6  1  undef        undef
END
 }

if (1)
 {my $s = q(zeroOrMore(choice(element("a"))));
  my $nfa = eval qq(fromExpr(sequence($s)));

  ok $nfa->print("a*:") eq <<END;
a*:
Location  F  Transitions  Jumps
       0  1  { a => 1 }   [2]
       1  1  undef        [0, 2]
       2  1  undef        undef
END
 }

if (1) {                                                                        #TallTransitions
  my $s = q(zeroOrMore(choice(element("a"))));

  my $nfa = eval qq(fromExpr(sequence($s,$s)));

  ok $nfa->print("a*a* 1:") eq <<END;
a*a* 1:
Location  F  Transitions  Jumps
       0  1  { a => 1 }   [2, 4]
       1  1  undef        [0, 2, 4]
       2  1  { a => 3 }   [4]
       3  1  undef        [2, 4]
       4  1  undef        undef
END

  is_deeply [0 .. 4],  $nfa->statesReachableViaSymbol(0, q(a));
  is_deeply [0 .. 4],  $nfa->statesReachableViaSymbol(1, q(a));
  is_deeply [2, 3, 4], $nfa->statesReachableViaSymbol(2, q(a));
  is_deeply [2, 3, 4], $nfa->statesReachableViaSymbol(3, q(a));

  is_deeply $nfa->allTransitions, {
  "0" => { a => [0 .. 4] },
  "1" => { a => [0 .. 4] },
  "2" => { a => [2, 3, 4] },
  "3" => { a => [2, 3, 4] },
  "4" => { a => [] },
  };

  ok $nfa->print("a*a* 2:") eq <<END;
a*a* 2:
Location  F  Transitions  Jumps
       0  1  { a => 1 }   [2, 4]
       1  1  undef        [0, 2, 4]
       2  1  { a => 3 }   [4]
       3  1  undef        [2, 4]
       4  1  undef        undef
END
 }

if (1)
 {my $N = 4;
  my $s = q(zeroOrMore(choice(element("a"), element("b"))));
  my $nfa = eval qq(fromExpr(($s)x$N));
  ok $nfa->print("((a|b)*)**$N:") eq <<END;
((a|b)*)**4:
Location  F  Transitions  Jumps
       0  1  { a => 1 }   [2, 4, 6, 8, 10, 12, 14, 16]
       1  1  undef        [0, 2, 3, 4, 6, 8, 10, 12, 14, 16]
       2  0  { b => 3 }   undef
       3  1  undef        [0, 2, 4, 6, 8, 10, 12, 14, 16]
       4  1  { a => 5 }   [6, 8, 10, 12, 14, 16]
       5  1  undef        [4, 6, 7, 8, 10, 12, 14, 16]
       6  0  { b => 7 }   undef
       7  1  undef        [4, 6, 8, 10, 12, 14, 16]
       8  1  { a => 9 }   [10, 12, 14, 16]
       9  1  undef        [8, 10, 11, 12, 14, 16]
      10  0  { b => 11 }  undef
      11  1  undef        [8, 10, 12, 14, 16]
      12  1  { a => 13 }  [14, 16]
      13  1  undef        [12, 14, 15, 16]
      14  0  { b => 15 }  undef
      15  1  undef        [12, 14, 16]
      16  1  undef        undef
END
 }

latestTest:;

if (1) {                                                                        #Texcept
  my $nfa = fromExpr(choice(qw(a b c)), except(qw(c x)), choice(qw(a b c)));

  ok $nfa->print("(a|b|c)(c!x)(a|b|c):") eq <<END;
(a|b|c)(c!x)(a|b|c):
Location  F  Transitions  Jumps
       0  0  { a => 1 }   [2, 4]
       1  0  undef        [5, 7]
       2  0  { b => 3 }   undef
       3  0  undef        [5, 7]
       4  0  { c => 5 }   undef
       5  0  { a => 6 }   [7]
       6  0  undef        [8, 10, 12]
       7  0  { b => 8 }   undef
       8  0  { a => 9 }   [10, 12]
       9  1  undef        [13]
      10  0  { b => 11 }  undef
      11  1  undef        [13]
      12  0  { c => 13 }  undef
      13  1  undef        undef
END

  ok !$nfa->parse(qw(a a));
  ok  $nfa->parse(qw(a a a));
  ok !$nfa->parse(qw(a c a));
 }
