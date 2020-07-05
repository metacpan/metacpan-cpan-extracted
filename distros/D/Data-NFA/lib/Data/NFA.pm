#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Non deterministic finite state machine from regular expression.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2018
#-------------------------------------------------------------------------------
# podDocumentation
package Data::NFA;
our $VERSION = 20200623;
require v5.26;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use utf8;

# NFA : bless {state=>{symbol=>state}, jumps=>{state=>1}, final=>defined if final, return=>state to return to}
# Jumps are instead of a transition not after a transition

my $logFile = q(/home/phil/z/z/z/zzz.txt);                                      # Log printed results if developing

sub Element   {q(element)}                                                      # Element of a regular expression.
sub Sequence  {q(sequence)}                                                     # Sequence of regular expressions.
sub Optional  {q(optional)}                                                     # Optional regular expression.
sub ZeroOrMore{q(zeroOrMore)}                                                   # Zero or more instances of a regular expression.
sub OneOrMore {q(oneOrMore)}                                                    # One or more instances of a regular expression.
sub Choice    {q(choice)}                                                       # Choice between regular expressions.
sub Except    {q(except)}                                                       # Choice between any symbols mentioned so far minus the ones listed.

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

#D1 Non deterministic finite state machine                                      # Create a non deterministic finite state machine to represent a regular expression.

sub newNfa(%)                                                                   #P Create a new NFA
 {my (%options) = @_;                                                           # Options
  bless {}, q(Data::NFA);
 }

sub newNfaState(%)                                                              #P Create a new NFA state.
 {my (%options) = @_;                                                           # Options

  my $r = genHash(q(Data::NFA::State),                                          # NFA State
    transitions => undef,                                                       # {symbol => state} : transitions from this state consuming one input symbol
    jumps       => undef,                                                       # {to     => 1}     : jumps from this state not consuming any input symbols
    final       => undef,                                                       # Whether this state is final
   );

  %$r = (%$r, %options);

  $r
 }

sub addNewState(%)                                                              #P Create a new NFA state and add it to an NFA created with L<newNfa>.
 {my ($nfa) = @_;                                                               # Nfa
  my $n = keys %$nfa;
  $$nfa{$n} = newNfaState;
 }

sub fromExpr2($$$)                                                              #P Create an NFA from a regular expression.
 {my ($states, $expr, $symbols) = @_;                                           # States, regular expression constructed from L<element|/element> L<sequence|/sequence> L<optional|/optional> L<zeroOrMore|/zeroOrMore> L<oneOrMore|/oneOrMore> L<choice|/choice>, set of symbols used by the NFA.
  $states  //= {};
  my $next   = sub{scalar keys %$states};                                       # Next state name
  my $last   = sub{&$next - 1};                                                 # Last state created

  my $save   = sub                                                              # Save as a new state
   {my ($transitions, $jumps, $final) = @_;                                     # Transitions, jumps, final
    my $s = $states->{&$next} = newNfaState
     (transitions=>$transitions, jumps=>$jumps, final=>$final);
    $s;
   };

  my $jump = sub                                                                # Add jumps
   {my ($from, @to) = @_;
    my $state = $states->{$from};
    $state->jumps->{$_}++ for @to
   };

  my $start = &$next + 1;                                                       # Start state
  &$save(undef, {$start=>1});                                                   # Offset the start of each expression by one cell to allow zeroOrMore, oneOrMore to jump back to their beginning without jumping back to the start of a containing choice

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
      &$save();                                                                 # Create new empty state
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
 } # fromExpr2

sub propagateFinalState($)                                                      #P Mark the B<$states> that can reach the final state with a jump as final.
 {my ($states) = @_;                                                            # States
  my %checked;
  for(;;)
   {my $changes = 0;
    for my $state(values %$states)                                              # Each state
     {if (!defined $state->final)                                               # Current state is not a final state
       {if (defined $state->jumps)
         {for my $jumpName(sort keys $state->jumps->%*)                         # Each jump
           {my $jump = $$states{$jumpName};
            if (defined(my $final = $jump->final))                              # Target state is final
             {++$changes;
              $state->final = $final;                                           # Mark state as final
              last;
             }
           }
         }
       }
     }
    last unless $changes;
   }
 } # propagateFinalState

sub statesReachableViaJumps($$)                                                 #P Find the names of all the B<$states> that can be reached from a specified B<$stateName> via jumps alone.
 {my ($states, $StateName) = @_;                                                # States, name of start state
  my %reachable;
  my @check = ($StateName);
  my %checked;

  while(@check)                                                                 # Reachable from the start state by a single transition after zero or more jumps
   {my $stateName = pop @check;
    next if $checked{$stateName}++;
    confess "No such state: $stateName" unless my $state = $$states{$stateName};
    for my $s(sort keys $state->jumps->%*)                                      # States that can be reached via jumps
     {$reachable{$s}++;                                                         # New state to check
      push @check, $s;
     }
   }

  [sort keys %reachable]
 } # statesReachableViaJumps

sub removeEmptyFields($)                                                        #P Remove empty fields from the B<states> representing an NFA.
 {my ($states) = @_;                                                            # States
  for my $state(values %$states)                                                # Remove empty fields
   {for(qw(jumps transitions))
     {delete $$state{$_} unless keys $$state{$_}->%*;
     }
    delete $$state{final} unless defined $$state{final};
   }
 } # removeEmptyFields

sub fromExpr(@)                                                                 #S Create an NFA from a regular B<@expression>.
 {my (@expression) = @_;                                                        # Regular expressions
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
  $symbols->($_) for @expression;                                               # Locate all symbols

  $states->fromExpr2($_, \%symbols) for @expression;                            # Create state transitions
  $states->{keys %$states} = newNfaState(final=>1);                             # End state

  for my $state(sort keys %$states)                                             # Collapse multiple jumps
   {$$states{$state}->jumps =
      {map {$_=>1} @{statesReachableViaJumps($states, $state)}};
   }

  $states->propagateFinalState;                                                 # Propagate final states

  $states->removeEmptyFields;                                                   # Remove any empty fields

  $states
 } # fromExpr

sub printFinalState($)                                                          #P Print the final field of the specified B<$state>.
 {my ($state) = @_;                                                             # State
  defined($state->final) ? 1 : q();
 }

sub printWithJumps($;$)                                                         #P Print the current B<$states> of an NFA with jumps using the specvified B<$title>.
 {my ($states, $title) = @_;                                                    # States, optional title
  my @o;
  push @o, [qw(Location  F Transitions Jumps)];
  for(sort{$a <=> $b} keys %$states)
   {my $d = $states->{$_};
    my @j = sort {$a <=> $b} keys %{$d->jumps};
    my $f = printFinalState($d);
    push @o, [sprintf("%4d", $_), $f,
              dump($d->transitions),
              dump(@j ? [@j] : undef)];
   }
  my $t = formatTableBasic([@o]);
  $title ? "$title\n$t" : $t
 }

sub printWithOutJumps($$)                                                       #P Print the current B<$states> of an NFA without jumps using  the specified B<$title>.
 {my ($states, $title) = @_;                                                    # States, title.
  my @o;
  push @o, [qw(Location  F Transitions)];
  for(sort{$a <=> $b} keys %$states)
   {my $d = $states->{$_};
    my $f = printFinalState($d);
    push @o, [sprintf("%4d", $_), $f,
              dump($d->transitions)];
   }
  "$title\n". formatTableBasic([@o]);
 }

sub print($$)                                                                   # Print the current B<$states> of the non deterministic finite state automaton using the specified B<$title>. If it is non deterministic, the non deterministic jumps will be shown as well as the transitions table. If deterministic, only the transitions table will be shown.
 {my ($states, $title) = @_;                                                    # States, title
  my $j = 0;                                                                    # Number of non deterministic jumps encountered
  for(sort{$a <=> $b} keys %$states)
   {my $d = $states->{$_};
    my @j = sort keys %{$d->jumps};
    ++$j if @j > 0;
   }

  my $r = $j ? &printWithJumps(@_) : &printWithOutJumps(@_);                    # Print

  owf($logFile, $r) if -e $logFile;                                             # Log the result if requested
  $r                                                                            # Return the result
 }

sub symbols($)                                                                  # Return an array of all the transition symbols.
 {my ($states) = @_;                                                            # States
  my %s;
  for my $d(values %$states)
   {if ($d->transitions)
     {$s{$_}++ for sort keys $d->transitions->%*;
     }
   }
  sort keys %s
 }

sub isFinal($$)                                                                 # Whether, in the B<$states> specifying an NFA the named state B<$state> is a final state.
 {my ($states, $state) = @_;                                                    # States, name of state to test
  my $f = $$states{$state}->final;
  my $F = defined($f) ? $f : undef;                                             # Defined yields "" for false which is not what we want
  $F
 }

sub statesReachableViaSymbol($$$$)                                              #P Find the names of all the states that can be reached from a specified state via a specified symbol and all the jumps available.
 {my ($states, $StateName, $symbol, $cache) = @_;                               # States, name of start state, symbol to reach on, a hash to be used as a cache
  my %reachable;
  my @check = ($StateName);
  my %checked;

  while(@check)                                                                 # Reachable from the start state by a single transition after zero or more jumps
   {my $stateName = pop @check;
    next if $checked{$stateName}++;
    confess "No such state: $stateName" unless my $state = $$states{$stateName};

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

sub allTransitions($)                                                           # Return all transitions in the NFA specified by B<$states> as {stateName}{symbol} = [reachable states].
 {my ($states) = @_;                                                            # States
  my $symbols = [$states->symbols];                                             # Symbols in nfa
  my $cache = {};                                                               # Cache results

  my $nfaSymbolTransitions;
  for my $StateName(sort keys %$states)                                         # Each NFA state
   {my $target = $$nfaSymbolTransitions{$StateName} = {};
    for my $symbol(@$symbols)                                                   # Each NFA symbol
     {my $statesReachableViaSymbol = sub                                        #P Find the names of all the states that can be reached from a specified state via a specified symbol and all the jumps available.
       {my %reachable;
        my @check     = ($StateName);
        my %checked;

        while(@check)                                                           # Reachable from the start state by a single transition after zero or more jumps
         {my $stateName = pop @check;
          next if $checked{$stateName}++;
          my $state = $$states{$stateName};
          confess "No such state: $stateName" unless $state;
          my $transitions = $state->transitions;

          if (defined(my $to = $$transitions{$symbol}))                         # Transition on the symbol
           {$reachable{$to}++;
            $reachable{$_}++
              for @{$$cache{$to} //= statesReachableViaJumps($states, $to)};    # Cache results of this expensive call
           }
          if (my $jumps = $state->jumps)
           {push @check, sort keys %$jumps;                                     # Make a jump and try again
           }
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

  if (defined(my $final = $$states{$stateName}->final))                         # Return success if we are in a final state with no more symbols to parse
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

sub parse($@)                                                                   # Parse, using the NFA specified by B<$states>, the list of symbols in L<@symbols>.
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


Version 20200621.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Construct regular expression

Construct a regular expression that defines the language to be parsed using the following combining operations which can all be imported:

=head2 element($label)

One element. An element can also be represented by a string or number

     Parameter  Description
  1  $label     Transition symbol

B<Example:>


    my $nfa = fromExpr(𝗲𝗹𝗲𝗺𝗲𝗻𝘁("a"));
    ok $nfa->print("Element: a") eq <<END;
  Element: a
  Location  F  Transitions  Jumps
         0     undef        [1]
         1     { a => 2 }   undef
         2  1  undef        undef\
  END
    ok  $nfa->isFinal(2);
    ok !$nfa->isFinal(0);
    ok  $nfa->parse(qw(a));
    ok !$nfa->parse(qw(a b));
    ok !$nfa->parse(qw(b));
    ok !$nfa->parse(qw(b a));


This is a static method and so should either be imported or invoked as:

  Data::NFA::element


=head2 sequence(@elements)

Sequence of elements and/or symbols.

     Parameter  Description
  1  @elements  Elements

B<Example:>


    my $nfa = fromExpr(qw(a b));
    is_deeply $nfa->print("ab"), <<END;
  ab
  Location  F  Transitions  Jumps
         0     undef        [1]
         1     { a => 2 }   undef
         2     undef        [3]
         3     { b => 4 }   undef
         4  1  undef        undef
  END
    ok !$nfa->parse(qw());
    ok  $nfa->parse(qw(a b));
    ok !$nfa->parse(qw(b a));
    ok !$nfa->parse(qw(a));
    ok !$nfa->parse(qw(b));


This is a static method and so should either be imported or invoked as:

  Data::NFA::sequence


=head2 optional(@element)

An optional sequence of elements and/or symbols.

     Parameter  Description
  1  @element   Elements

B<Example:>


    my $nfa = fromExpr("a", 𝗼𝗽𝘁𝗶𝗼𝗻𝗮𝗹("b"), "c");
    is_deeply $nfa->print("ab?c"), <<END;
  ab?c
  Location  F  Transitions  Jumps
         0     undef        [1]
         1     { a => 2 }   undef
         2     undef        [3 .. 6]
         3     undef        [4, 5, 6]
         4     { b => 5 }   undef
         5     undef        [6]
         6     { c => 7 }   undef
         7  1  undef        undef
  END
    ok !$nfa->parse(qw(a));
    ok  $nfa->parse(qw(a b c));
    ok  $nfa->parse(qw(a c));
    ok !$nfa->parse(qw(a c b));


This is a static method and so should either be imported or invoked as:

  Data::NFA::optional


=head2 zeroOrMore(@element)

Zero or more repetitions of a sequence of elements and/or symbols.

     Parameter  Description
  1  @element   Elements

B<Example:>


    my $nfa = fromExpr("a", 𝘇𝗲𝗿𝗼𝗢𝗿𝗠𝗼𝗿𝗲("b"), "c");
    is_deeply $nfa->print("ab*c"), <<END;
  ab*c
  Location  F  Transitions  Jumps
         0     undef        [1]
         1     { a => 2 }   undef
         2     undef        [3, 4, 6, 7]
         3     undef        [4, 6, 7]
         4     { b => 5 }   undef
         5     undef        [3, 4, 6, 7]
         6     undef        [7]
         7     { c => 8 }   undef
         8  1  undef        undef
  END
    ok  $nfa->parse(qw(a c));
    ok  $nfa->parse(qw(a b c));
    ok  $nfa->parse(qw(a b b c));
    ok !$nfa->parse(qw(a b b d));

    my $nfa = fromExpr("a",
                       𝘇𝗲𝗿𝗼𝗢𝗿𝗠𝗼𝗿𝗲(choice("a",
                       "a")),
                       "a");
    is_deeply $nfa->print("(a(a|a)*a"), <<END;
  (a(a|a)*a
  Location  F  Transitions  Jumps
         0     undef        [1]
         1     { a => 2 }   undef
         2     undef        [3, 4, 5, 7, 8, 10, 11]
         3     undef        [4, 5, 7, 8, 10, 11]
         4     undef        [5, 7, 8]
         5     { a => 6 }   undef
         6     undef        [3, 4, 5, 7 .. 11]
         7     undef        [8]
         8     { a => 9 }   undef
         9     undef        [3, 4, 5, 7, 8, 10, 11]
        10     undef        [11]
        11     { a => 12 }  undef
        12  1  undef        undef
  END

    ok !$nfa->parse(qw(a));
    ok  $nfa->parse(qw(a a));
    ok  $nfa->parse(qw(a a a));
    ok !$nfa->parse(qw(a b a));


This is a static method and so should either be imported or invoked as:

  Data::NFA::zeroOrMore


=head2 oneOrMore(@element)

One or more repetitions of a sequence of elements and/or symbols.

     Parameter  Description
  1  @element   Elements

B<Example:>


    my $nfa = fromExpr("a", 𝗼𝗻𝗲𝗢𝗿𝗠𝗼𝗿𝗲("b"), "c");

    is_deeply $nfa->print("One or More: ab+c"), <<END;
  One or More: ab+c
  Location  F  Transitions  Jumps
         0     undef        [1]
         1     { a => 2 }   undef
         2     undef        [3, 4]
         3     undef        [4]
         4     { b => 5 }   undef
         5     undef        [3, 4, 6, 7]
         6     undef        [7]
         7     { c => 8 }   undef
         8  1  undef        undef
  END

    ok !$nfa->parse(qw(a c));
    ok  $nfa->parse(qw(a b c));
    ok  $nfa->parse(qw(a b b c));
    ok !$nfa->parse(qw(a b b d));


This is a static method and so should either be imported or invoked as:

  Data::NFA::oneOrMore


=head2 choice(@elements)

Choice from amongst one or more elements and/or symbols.

     Parameter  Description
  1  @elements  Elements to be chosen from

B<Example:>


    my $nfa = fromExpr("a",
                       𝗰𝗵𝗼𝗶𝗰𝗲(qw(b c)),
                       "d");
    is_deeply $nfa->print("(a(b|c)d"), <<END;
  (a(b|c)d
  Location  F  Transitions  Jumps
         0     undef        [1]
         1     { a => 2 }   undef
         2     undef        [3, 4, 6, 7]
         3     undef        [4, 6, 7]
         4     { b => 5 }   undef
         5     undef        [8, 9]
         6     undef        [7]
         7     { c => 8 }   undef
         8     undef        [9]
         9     { d => 10 }  undef
        10  1  undef        undef
  END

    ok  $nfa->parse(qw(a b d));
    ok  $nfa->parse(qw(a c d));
    ok !$nfa->parse(qw(a b c d));


This is a static method and so should either be imported or invoked as:

  Data::NFA::choice


=head2 except(@elements)

Choice from amongst all symbols except the ones mentioned

     Parameter  Description
  1  @elements  Elements not to be chosen from

B<Example:>


    my $nfa = fromExpr(choice(qw(a b c)), 𝗲𝘅𝗰𝗲𝗽𝘁(qw(c x)), choice(qw(a b c)));

    is_deeply $nfa->print("(a|b|c)(c!x)(a|b|c)"), <<END;
  (a|b|c)(c!x)(a|b|c)
  Location  F  Transitions  Jumps
         0     undef        [1, 2, 4, 5, 7, 8]
         1     undef        [2, 4, 5, 7, 8]
         2     { a => 3 }   undef
         3     undef        [9, 10, 11, 13, 14]
         4     undef        [5]
         5     { b => 6 }   undef
         6     undef        [9, 10, 11, 13, 14]
         7     undef        [8]
         8     { c => 9 }   undef
         9     undef        [10, 11, 13, 14]
        10     undef        [11, 13, 14]
        11     { a => 12 }  undef
        12     undef        [15, 16, 17, 19, 20, 22, 23]
        13     undef        [14]
        14     { b => 15 }  undef
        15     undef        [16, 17, 19, 20, 22, 23]
        16     undef        [17, 19, 20, 22, 23]
        17     { a => 18 }  undef
        18  1  undef        [24]
        19     undef        [20]
        20     { b => 21 }  undef
        21  1  undef        [24]
        22     undef        [23]
        23     { c => 24 }  undef
        24  1  undef        undef
  END

    ok !$nfa->parse(qw(a a));
    ok  $nfa->parse(qw(a a a));
    ok !$nfa->parse(qw(a c a));


This is a static method and so should either be imported or invoked as:

  Data::NFA::except


=head1 Non deterministic finite state machine

Create a non deterministic finite state machine to represent a regular expression.

=head2 fromExpr(@expression)

Create an NFA from a regular B<@expression>.

     Parameter    Description
  1  @expression  Regular expressions

B<Example:>


    my $nfa = 𝗳𝗿𝗼𝗺𝗘𝘅𝗽𝗿
     ("a",
      oneOrMore(choice(qw(b c))),
      optional("d"),
      element("e")
     );

    is_deeply $nfa->print("a(b|c)+d?e"), <<END;
  a(b|c)+d?e
  Location  F  Transitions  Jumps
         0     undef        [1]
         1     { a => 2 }   undef
         2     undef        [3, 4, 5, 7, 8]
         3     undef        [4, 5, 7, 8]
         4     undef        [5, 7, 8]
         5     { b => 6 }   undef
         6     undef        [3, 4, 5, 7 .. 14]
         7     undef        [8]
         8     { c => 9 }   undef
         9     undef        [3, 4, 5, 7, 8, 10 .. 14]
        10     undef        [11 .. 14]
        11     undef        [12, 13, 14]
        12     { d => 13 }  undef
        13     undef        [14]
        14     { e => 15 }  undef
        15  1  undef        undef
  END

    is_deeply ['a'..'e'], [$nfa->symbols];

    ok !$nfa->parse(qw(a e));
    ok !$nfa->parse(qw(a d e));
    ok  $nfa->parse(qw(a b c e));
    ok  $nfa->parse(qw(a b c d e));


This is a static method and so should either be imported or invoked as:

  Data::NFA::fromExpr


=head2 print($states, $title)

Print the current B<$states> of the non deterministic finite state automaton using the specified B<$title>. If it is non deterministic, the non deterministic jumps will be shown as well as the transitions table. If deterministic, only the transitions table will be shown.

     Parameter  Description
  1  $states    States
  2  $title     Title

B<Example:>


    my $nfa = fromExpr
     ("a",
      oneOrMore(choice(qw(b c))),
      optional("d"),
      element("e")
     );

    is_deeply $nfa->𝗽𝗿𝗶𝗻𝘁("a(b|c)+d?e"), <<END;
  a(b|c)+d?e
  Location  F  Transitions  Jumps
         0     undef        [1]
         1     { a => 2 }   undef
         2     undef        [3, 4, 5, 7, 8]
         3     undef        [4, 5, 7, 8]
         4     undef        [5, 7, 8]
         5     { b => 6 }   undef
         6     undef        [3, 4, 5, 7 .. 14]
         7     undef        [8]
         8     { c => 9 }   undef
         9     undef        [3, 4, 5, 7, 8, 10 .. 14]
        10     undef        [11 .. 14]
        11     undef        [12, 13, 14]
        12     { d => 13 }  undef
        13     undef        [14]
        14     { e => 15 }  undef
        15  1  undef        undef
  END

    is_deeply ['a'..'e'], [$nfa->symbols];

    ok !$nfa->parse(qw(a e));
    ok !$nfa->parse(qw(a d e));
    ok  $nfa->parse(qw(a b c e));
    ok  $nfa->parse(qw(a b c d e));


=head2 symbols($states)

Return an array of all the transition symbols.

     Parameter  Description
  1  $states    States

B<Example:>


    my $nfa = fromExpr
     ("a",
      oneOrMore(choice(qw(b c))),
      optional("d"),
      element("e")
     );

    is_deeply $nfa->print("a(b|c)+d?e"), <<END;
  a(b|c)+d?e
  Location  F  Transitions  Jumps
         0     undef        [1]
         1     { a => 2 }   undef
         2     undef        [3, 4, 5, 7, 8]
         3     undef        [4, 5, 7, 8]
         4     undef        [5, 7, 8]
         5     { b => 6 }   undef
         6     undef        [3, 4, 5, 7 .. 14]
         7     undef        [8]
         8     { c => 9 }   undef
         9     undef        [3, 4, 5, 7, 8, 10 .. 14]
        10     undef        [11 .. 14]
        11     undef        [12, 13, 14]
        12     { d => 13 }  undef
        13     undef        [14]
        14     { e => 15 }  undef
        15  1  undef        undef
  END

    is_deeply ['a'..'e'], [$nfa->𝘀𝘆𝗺𝗯𝗼𝗹𝘀];

    ok !$nfa->parse(qw(a e));
    ok !$nfa->parse(qw(a d e));
    ok  $nfa->parse(qw(a b c e));
    ok  $nfa->parse(qw(a b c d e));


=head2 isFinal($states, $state)

Whether, in the B<$states> specifying an NFA the named state B<$state> is a final state.

     Parameter  Description
  1  $states    States
  2  $state     Name of state to test

B<Example:>


    my $nfa = fromExpr(element("a"));
    ok $nfa->print("Element: a") eq <<END;
  Element: a
  Location  F  Transitions  Jumps
         0     undef        [1]
         1     { a => 2 }   undef
         2  1  undef        undef\
  END
    ok  $nfa->𝗶𝘀𝗙𝗶𝗻𝗮𝗹(2);
    ok !$nfa->𝗶𝘀𝗙𝗶𝗻𝗮𝗹(0);
    ok  $nfa->parse(qw(a));
    ok !$nfa->parse(qw(a b));
    ok !$nfa->parse(qw(b));
    ok !$nfa->parse(qw(b a));


=head2 allTransitions($states)

Return all transitions in the NFA specified by B<$states> as {stateName}{symbol} = [reachable states].

     Parameter  Description
  1  $states    States

B<Example:>


    my $s = q(zeroOrMore(choice("a")));

    my $nfa = eval qq(fromExpr(sequence($s,$s)));

    is_deeply $nfa->print("a*"), <<END;
  a*
  Location  F  Transitions  Jumps
         0  1  undef        [1 .. 4, 6 .. 9, 11]
         1  1  undef        [2, 3, 4, 6 .. 9, 11]
         2  1  undef        [3, 4, 6 .. 9, 11]
         3     undef        [4]
         4     { a => 5 }   undef
         5  1  undef        [2, 3, 4, 6 .. 9, 11]
         6  1  undef        [7, 8, 9, 11]
         7  1  undef        [8, 9, 11]
         8     undef        [9]
         9     { a => 10 }  undef
        10  1  undef        [7, 8, 9, 11]
        11  1  undef        undef
  END

    ok  $nfa->parse(qw());
    ok  $nfa->parse(qw(a));
    ok !$nfa->parse(qw(b));
    ok  $nfa->parse(qw(a a));
    ok !$nfa->parse(qw(b b));
    ok !$nfa->parse(qw(a b));
    ok !$nfa->parse(qw(b a));
    ok !$nfa->parse(qw(c));

    is_deeply $nfa->𝗮𝗹𝗹𝗧𝗿𝗮𝗻𝘀𝗶𝘁𝗶𝗼𝗻𝘀, {
    "0"  => { a => [10, 11, 2 .. 9] },
    "1"  => { a => [10, 11, 2 .. 9] },
    "2"  => { a => [10, 11, 2 .. 9] },
    "3"  => { a => [11, 2 .. 9] },
    "4"  => { a => [11, 2 .. 9] },
    "5"  => { a => [10, 11, 2 .. 9] },
    "6"  => { a => [10, 11, 7, 8, 9] },
    "7"  => { a => [10, 11, 7, 8, 9] },
    "8"  => { a => [10, 11, 7, 8, 9] },
    "9"  => { a => [10, 11, 7, 8, 9] },
    "10" => { a => [10, 11, 7, 8, 9] },
    "11" => { a => [] },
  };

    is_deeply $nfa->print("a*a* 2"), <<END;
  a*a* 2
  Location  F  Transitions  Jumps
         0  1  undef        [1 .. 4, 6 .. 9, 11]
         1  1  undef        [2, 3, 4, 6 .. 9, 11]
         2  1  undef        [3, 4, 6 .. 9, 11]
         3     undef        [4]
         4     { a => 5 }   undef
         5  1  undef        [2, 3, 4, 6 .. 9, 11]
         6  1  undef        [7, 8, 9, 11]
         7  1  undef        [8, 9, 11]
         8     undef        [9]
         9     { a => 10 }  undef
        10  1  undef        [7, 8, 9, 11]
        11  1  undef        undef
  END


=head2 parse($states, @symbols)

Parse, using the NFA specified by B<$states>, the list of symbols in L<@symbols>.

     Parameter  Description
  1  $states    States
  2  @symbols   Array of symbols

B<Example:>


    my $nfa = fromExpr(element("a"));
    ok $nfa->print("Element: a") eq <<END;
  Element: a
  Location  F  Transitions  Jumps
         0     undef        [1]
         1     { a => 2 }   undef
         2  1  undef        undef\
  END
    ok  $nfa->isFinal(2);
    ok !$nfa->isFinal(0);
    ok  $nfa->𝗽𝗮𝗿𝘀𝗲(qw(a));
    ok !$nfa->𝗽𝗮𝗿𝘀𝗲(qw(a b));
    ok !$nfa->𝗽𝗮𝗿𝘀𝗲(qw(b));
    ok !$nfa->𝗽𝗮𝗿𝘀𝗲(qw(b a));



=head2 Data::NFA::State Definition


NFA State




=head3 Output fields


B<final> - Whether this state is final

B<jumps> - {to     => 1}     : jumps from this state not consuming any input symbols

B<transitions> - {symbol => state} : transitions from this state consuming one input symbol



=head1 Private Methods

=head2 newNfa(%options)

Create a new NFA

     Parameter  Description
  1  %options   Options

=head2 newNfaState(%options)

Create a new NFA state.

     Parameter  Description
  1  %options   Options

=head2 addNewState($nfa)

Create a new NFA state and add it to an NFA created with L<newNfa>.

     Parameter  Description
  1  $nfa       Nfa

=head2 fromExpr2($states, $expr, $symbols)

Create an NFA from a regular expression.

     Parameter  Description
  1  $states    States
  2  $expr      Regular expression constructed from L<element|/element> L<sequence|/sequence> L<optional|/optional> L<zeroOrMore|/zeroOrMore> L<oneOrMore|/oneOrMore> L<choice|/choice>
  3  $symbols   Set of symbols used by the NFA.

=head2 propagateFinalState($states)

Mark the B<$states> that can reach the final state with a jump as final.

     Parameter  Description
  1  $states    States

=head2 statesReachableViaJumps($states, $StateName)

Find the names of all the B<$states> that can be reached from a specified B<$stateName> via jumps alone.

     Parameter   Description
  1  $states     States
  2  $StateName  Name of start state

=head2 removeEmptyFields($states)

Remove empty fields from the B<states> representing an NFA.

     Parameter  Description
  1  $states    States

=head2 printFinalState($state)

Print the final field of the specified B<$state>.

     Parameter  Description
  1  $state     State

=head2 printWithJumps($states, $title)

Print the current B<$states> of an NFA with jumps using the specvified B<$title>.

     Parameter  Description
  1  $states    States
  2  $title     Optional title

=head2 printWithOutJumps($states, $title)

Print the current B<$states> of an NFA without jumps using  the specified B<$title>.

     Parameter  Description
  1  $states    States
  2  $title     Title.

=head2 statesReachableViaSymbol($states, $StateName, $symbol, $cache)

Find the names of all the states that can be reached from a specified state via a specified symbol and all the jumps available.

     Parameter   Description
  1  $states     States
  2  $StateName  Name of start state
  3  $symbol     Symbol to reach on
  4  $cache      A hash to be used as a cache

=head2 parse2($states, $stateName, @symbols)

Parse an array of symbols

     Parameter   Description
  1  $states     States
  2  $stateName  Current state
  3  @symbols    Remaining symbols


=head1 Index


1 L<addNewState|/addNewState> - Create a new NFA state and add it to an NFA created with L<newNfa>.

2 L<allTransitions|/allTransitions> - Return all transitions in the NFA specified by B<$states> as {stateName}{symbol} = [reachable states].

3 L<choice|/choice> - Choice from amongst one or more elements and/or symbols.

4 L<element|/element> - One element.

5 L<except|/except> - Choice from amongst all symbols except the ones mentioned

6 L<fromExpr|/fromExpr> - Create an NFA from a regular B<@expression>.

7 L<fromExpr2|/fromExpr2> - Create an NFA from a regular expression.

8 L<isFinal|/isFinal> - Whether, in the B<$states> specifying an NFA the named state B<$state> is a final state.

9 L<newNfa|/newNfa> - Create a new NFA

10 L<newNfaState|/newNfaState> - Create a new NFA state.

11 L<oneOrMore|/oneOrMore> - One or more repetitions of a sequence of elements and/or symbols.

12 L<optional|/optional> - An optional sequence of elements and/or symbols.

13 L<parse|/parse> - Parse, using the NFA specified by B<$states>, the list of symbols in L<@symbols>.

14 L<parse2|/parse2> - Parse an array of symbols

15 L<print|/print> - Print the current B<$states> of the non deterministic finite state automaton using the specified B<$title>.

16 L<printFinalState|/printFinalState> - Print the final field of the specified B<$state>.

17 L<printWithJumps|/printWithJumps> - Print the current B<$states> of an NFA with jumps using the specvified B<$title>.

18 L<printWithOutJumps|/printWithOutJumps> - Print the current B<$states> of an NFA without jumps using  the specified B<$title>.

19 L<propagateFinalState|/propagateFinalState> - Mark the B<$states> that can reach the final state with a jump as final.

20 L<removeEmptyFields|/removeEmptyFields> - Remove empty fields from the B<states> representing an NFA.

21 L<sequence|/sequence> - Sequence of elements and/or symbols.

22 L<statesReachableViaJumps|/statesReachableViaJumps> - Find the names of all the B<$states> that can be reached from a specified B<$stateName> via jumps alone.

23 L<statesReachableViaSymbol|/statesReachableViaSymbol> - Find the names of all the states that can be reached from a specified state via a specified symbol and all the jumps available.

24 L<symbols|/symbols> - Return an array of all the transition symbols.

25 L<zeroOrMore|/zeroOrMore> - Zero or more repetitions of a sequence of elements and/or symbols.

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
use Test::More tests=>122;

#goto latestTest;

if (1) {                                                                        #Telement #TisFinal #Tparse
  my $nfa = fromExpr(element("a"));
  ok $nfa->print("Element: a") eq <<END;
Element: a
Location  F  Transitions  Jumps
       0     undef        [1]
       1     { a => 2 }   undef
       2  1  undef        undef\
END
  ok  $nfa->isFinal(2);
  ok !$nfa->isFinal(0);
  ok  $nfa->parse(qw(a));
  ok !$nfa->parse(qw(a b));
  ok !$nfa->parse(qw(b));
  ok !$nfa->parse(qw(b a));
 }

if (1)
 {my $nfa = fromExpr(q(b));
  is_deeply $nfa->print("b"), <<END;
b
Location  F  Transitions  Jumps
       0     undef        [1]
       1     { b => 2 }   undef
       2  1  undef        undef
END
  ok !$nfa->parse();
  ok  $nfa->parse(qw(b));
  ok !$nfa->parse(qw(b b));
  ok !$nfa->parse(qw(a));
 }

if (1)
 {my $nfa = fromExpr(2);
  is_deeply $nfa->print("2"), <<END;
2
Location  F  Transitions  Jumps
       0     undef        [1]
       1     { 2 => 2 }   undef
       2  1  undef        undef
END
  ok !$nfa->parse();
  ok  $nfa->parse(qw(2));
  ok !$nfa->parse(qw(2 2));
  ok !$nfa->parse(qw(1));
 }

if (1) {                                                                        #Tsequence
  my $nfa = fromExpr(qw(a b));
  is_deeply $nfa->print("ab"), <<END;
ab
Location  F  Transitions  Jumps
       0     undef        [1]
       1     { a => 2 }   undef
       2     undef        [3]
       3     { b => 4 }   undef
       4  1  undef        undef
END
  ok !$nfa->parse(qw());
  ok  $nfa->parse(qw(a b));
  ok !$nfa->parse(qw(b a));
  ok !$nfa->parse(qw(a));
  ok !$nfa->parse(qw(b));
 }

if (1) {                                                                        #Toptional
  my $nfa = fromExpr("a", optional("b"), "c");
  is_deeply $nfa->print("ab?c"), <<END;
ab?c
Location  F  Transitions  Jumps
       0     undef        [1]
       1     { a => 2 }   undef
       2     undef        [3 .. 6]
       3     undef        [4, 5, 6]
       4     { b => 5 }   undef
       5     undef        [6]
       6     { c => 7 }   undef
       7  1  undef        undef
END
  ok !$nfa->parse(qw(a));
  ok  $nfa->parse(qw(a b c));
  ok  $nfa->parse(qw(a c));
  ok !$nfa->parse(qw(a c b));
 }

if (1) {                                                                        #TzeroOrMore
  my $nfa = fromExpr("a", zeroOrMore("b"), "c");
  is_deeply $nfa->print("ab*c"), <<END;
ab*c
Location  F  Transitions  Jumps
       0     undef        [1]
       1     { a => 2 }   undef
       2     undef        [3, 4, 6, 7]
       3     undef        [4, 6, 7]
       4     { b => 5 }   undef
       5     undef        [3, 4, 6, 7]
       6     undef        [7]
       7     { c => 8 }   undef
       8  1  undef        undef
END
  ok  $nfa->parse(qw(a c));
  ok  $nfa->parse(qw(a b c));
  ok  $nfa->parse(qw(a b b c));
  ok !$nfa->parse(qw(a b b d));
 }

if (1) {                                                                        #ToneOrMore
  my $nfa = fromExpr("a", oneOrMore("b"), "c");

  is_deeply $nfa->print("One or More: ab+c"), <<END;
One or More: ab+c
Location  F  Transitions  Jumps
       0     undef        [1]
       1     { a => 2 }   undef
       2     undef        [3, 4]
       3     undef        [4]
       4     { b => 5 }   undef
       5     undef        [3, 4, 6, 7]
       6     undef        [7]
       7     { c => 8 }   undef
       8  1  undef        undef
END

  ok !$nfa->parse(qw(a c));
  ok  $nfa->parse(qw(a b c));
  ok  $nfa->parse(qw(a b b c));
  ok !$nfa->parse(qw(a b b d));
 }

if (1) {                                                                        #Tchoice
  my $nfa = fromExpr("a",
                     choice(qw(b c)),
                     "d");
  is_deeply $nfa->print("(a(b|c)d"), <<END;
(a(b|c)d
Location  F  Transitions  Jumps
       0     undef        [1]
       1     { a => 2 }   undef
       2     undef        [3, 4, 6, 7]
       3     undef        [4, 6, 7]
       4     { b => 5 }   undef
       5     undef        [8, 9]
       6     undef        [7]
       7     { c => 8 }   undef
       8     undef        [9]
       9     { d => 10 }  undef
      10  1  undef        undef
END

  ok  $nfa->parse(qw(a b d));
  ok  $nfa->parse(qw(a c d));
  ok !$nfa->parse(qw(a b c d));
 }

if (1) {                                                                        #TzeroOrMore
  my $nfa = fromExpr("a",
                     zeroOrMore(choice("a",
                     "a")),
                     "a");
  is_deeply $nfa->print("(a(a|a)*a"), <<END;
(a(a|a)*a
Location  F  Transitions  Jumps
       0     undef        [1]
       1     { a => 2 }   undef
       2     undef        [3, 4, 5, 7, 8, 10, 11]
       3     undef        [4, 5, 7, 8, 10, 11]
       4     undef        [5, 7, 8]
       5     { a => 6 }   undef
       6     undef        [3, 4, 5, 7 .. 11]
       7     undef        [8]
       8     { a => 9 }   undef
       9     undef        [3, 4, 5, 7, 8, 10, 11]
      10     undef        [11]
      11     { a => 12 }  undef
      12  1  undef        undef
END

  ok !$nfa->parse(qw(a));
  ok  $nfa->parse(qw(a a));
  ok  $nfa->parse(qw(a a a));
  ok !$nfa->parse(qw(a b a));
 }

if (1)
 {my $nfa = fromExpr("a",
                     zeroOrMore(choice(qw(b c))),
                     "d");
  ok $nfa->print("(a(b|c)*d") eq <<END;
(a(b|c)*d
Location  F  Transitions  Jumps
       0     undef        [1]
       1     { a => 2 }   undef
       2     undef        [3, 4, 5, 7, 8, 10, 11]
       3     undef        [4, 5, 7, 8, 10, 11]
       4     undef        [5, 7, 8]
       5     { b => 6 }   undef
       6     undef        [3, 4, 5, 7 .. 11]
       7     undef        [8]
       8     { c => 9 }   undef
       9     undef        [3, 4, 5, 7, 8, 10, 11]
      10     undef        [11]
      11     { d => 12 }  undef
      12  1  undef        undef
END

  ok  $nfa->parse(qw(a d));
  ok  $nfa->parse(qw(a b b c c b b d));
  ok !$nfa->parse(qw(a d b));
 }

if (1) {                                                                        #TfromExpr #Tprint #Tsymbols #Tparser
  my $nfa = fromExpr
   ("a",
    oneOrMore(choice(qw(b c))),
    optional("d"),
    element("e")
   );

  is_deeply $nfa->print("a(b|c)+d?e"), <<END;
a(b|c)+d?e
Location  F  Transitions  Jumps
       0     undef        [1]
       1     { a => 2 }   undef
       2     undef        [3, 4, 5, 7, 8]
       3     undef        [4, 5, 7, 8]
       4     undef        [5, 7, 8]
       5     { b => 6 }   undef
       6     undef        [3, 4, 5, 7 .. 14]
       7     undef        [8]
       8     { c => 9 }   undef
       9     undef        [3, 4, 5, 7, 8, 10 .. 14]
      10     undef        [11 .. 14]
      11     undef        [12, 13, 14]
      12     { d => 13 }  undef
      13     undef        [14]
      14     { e => 15 }  undef
      15  1  undef        undef
END

  is_deeply ['a'..'e'], [$nfa->symbols];

  ok !$nfa->parse(qw(a e));
  ok !$nfa->parse(qw(a d e));
  ok  $nfa->parse(qw(a b c e));
  ok  $nfa->parse(qw(a b c d e));
 }

if (1)
 {my $s = q(choice(qw(a b)));
  my $nfa = eval qq(fromExpr($s));

  is_deeply $nfa->print("(a|b)"), <<END;
(a|b)
Location  F  Transitions  Jumps
       0     undef        [1, 2, 4, 5]
       1     undef        [2, 4, 5]
       2     { a => 3 }   undef
       3  1  undef        [6]
       4     undef        [5]
       5     { b => 6 }   undef
       6  1  undef        undef
END

  ok !$nfa->parse(qw());
  ok  $nfa->parse(qw(a));
  ok  $nfa->parse(qw(b));
  ok !$nfa->parse(qw(a a));
  ok !$nfa->parse(qw(a b));
  ok !$nfa->parse(qw(b a));
  ok !$nfa->parse(qw(b b));
  ok !$nfa->parse(qw(c));
 }

if (1)
 {my $s = q(choice(qw(a b)));
  my $nfa = eval qq(fromExpr($s));

  is_deeply $nfa->print("(a|b)"), <<END;
(a|b)
Location  F  Transitions  Jumps
       0     undef        [1, 2, 4, 5]
       1     undef        [2, 4, 5]
       2     { a => 3 }   undef
       3  1  undef        [6]
       4     undef        [5]
       5     { b => 6 }   undef
       6  1  undef        undef
END
  ok !$nfa->parse(qw());
  ok  $nfa->parse(qw(a));
  ok  $nfa->parse(qw(b));
  ok !$nfa->parse(qw(a a));
  ok !$nfa->parse(qw(a b));
  ok !$nfa->parse(qw(b a));
  ok !$nfa->parse(qw(b b));
  ok !$nfa->parse(qw(c));
 }

if (1)
 {my $s = q(choice(qw(a b)));
  my $nfa = eval qq(fromExpr(sequence($s,$s)));

  is_deeply $nfa->print("(a|b)(a|b)"), <<END;
(a|b)(a|b)
Location  F  Transitions  Jumps
       0     undef        [1, 2, 3, 5, 6]
       1     undef        [2, 3, 5, 6]
       2     undef        [3, 5, 6]
       3     { a => 4 }   undef
       4     undef        [7, 8, 9, 11, 12]
       5     undef        [6]
       6     { b => 7 }   undef
       7     undef        [8, 9, 11, 12]
       8     undef        [9, 11, 12]
       9     { a => 10 }  undef
      10  1  undef        [13]
      11     undef        [12]
      12     { b => 13 }  undef
      13  1  undef        undef
END
  ok !$nfa->parse(qw());
  ok !$nfa->parse(qw(a));
  ok !$nfa->parse(qw(b));
  ok  $nfa->parse(qw(a a));
  ok  $nfa->parse(qw(a b));
  ok  $nfa->parse(qw(b a));
  ok  $nfa->parse(qw(b b));
  ok !$nfa->parse(qw(c));
 }

if (1)
 {my $s = q(zeroOrMore(choice("a")));
  my $nfa = eval qq(fromExpr(sequence($s)));

  is_deeply $nfa->print("a*"), <<END;
a*
Location  F  Transitions  Jumps
       0  1  undef        [1 .. 4, 6]
       1  1  undef        [2, 3, 4, 6]
       2  1  undef        [3, 4, 6]
       3     undef        [4]
       4     { a => 5 }   undef
       5  1  undef        [2, 3, 4, 6]
       6  1  undef        undef
END
  ok  $nfa->parse(qw());
  ok  $nfa->parse(qw(a));
  ok !$nfa->parse(qw(b));
  ok  $nfa->parse(qw(a a));
  ok !$nfa->parse(qw(a b));
  ok !$nfa->parse(qw(b a));
  ok !$nfa->parse(qw(b b));
  ok !$nfa->parse(qw(c));
 }

if (1) {                                                                        #TallTransitions
  my $s = q(zeroOrMore(choice("a")));

  my $nfa = eval qq(fromExpr(sequence($s,$s)));

  is_deeply $nfa->print("a*"), <<END;
a*
Location  F  Transitions  Jumps
       0  1  undef        [1 .. 4, 6 .. 9, 11]
       1  1  undef        [2, 3, 4, 6 .. 9, 11]
       2  1  undef        [3, 4, 6 .. 9, 11]
       3     undef        [4]
       4     { a => 5 }   undef
       5  1  undef        [2, 3, 4, 6 .. 9, 11]
       6  1  undef        [7, 8, 9, 11]
       7  1  undef        [8, 9, 11]
       8     undef        [9]
       9     { a => 10 }  undef
      10  1  undef        [7, 8, 9, 11]
      11  1  undef        undef
END

  ok  $nfa->parse(qw());
  ok  $nfa->parse(qw(a));
  ok !$nfa->parse(qw(b));
  ok  $nfa->parse(qw(a a));
  ok !$nfa->parse(qw(b b));
  ok !$nfa->parse(qw(a b));
  ok !$nfa->parse(qw(b a));
  ok !$nfa->parse(qw(c));

  is_deeply $nfa->allTransitions, {
  "0"  => { a => [10, 11, 2 .. 9] },
  "1"  => { a => [10, 11, 2 .. 9] },
  "2"  => { a => [10, 11, 2 .. 9] },
  "3"  => { a => [11, 2 .. 9] },
  "4"  => { a => [11, 2 .. 9] },
  "5"  => { a => [10, 11, 2 .. 9] },
  "6"  => { a => [10, 11, 7, 8, 9] },
  "7"  => { a => [10, 11, 7, 8, 9] },
  "8"  => { a => [10, 11, 7, 8, 9] },
  "9"  => { a => [10, 11, 7, 8, 9] },
  "10" => { a => [10, 11, 7, 8, 9] },
  "11" => { a => [] },
};

  is_deeply $nfa->print("a*a* 2"), <<END;
a*a* 2
Location  F  Transitions  Jumps
       0  1  undef        [1 .. 4, 6 .. 9, 11]
       1  1  undef        [2, 3, 4, 6 .. 9, 11]
       2  1  undef        [3, 4, 6 .. 9, 11]
       3     undef        [4]
       4     { a => 5 }   undef
       5  1  undef        [2, 3, 4, 6 .. 9, 11]
       6  1  undef        [7, 8, 9, 11]
       7  1  undef        [8, 9, 11]
       8     undef        [9]
       9     { a => 10 }  undef
      10  1  undef        [7, 8, 9, 11]
      11  1  undef        undef
END
 }

if (1)
 {my $N = 4;
  my $s = q(zeroOrMore(choice("a", element("b"))));
  my $nfa = eval qq(fromExpr(($s)x$N));
  is_deeply $nfa->print("((a|b)*)**$N"), <<END;
((a|b)*)**4
Location  F  Transitions  Jumps
       0  1  undef        [1, 2, 3, 5, 6, 8 .. 11, 13, 14, 16 .. 19, 21, 22, 24 .. 27, 29, 30, 32]
       1  1  undef        [2, 3, 5, 6, 8 .. 11, 13, 14, 16 .. 19, 21, 22, 24 .. 27, 29, 30, 32]
       2     undef        [3, 5, 6]
       3     { a => 4 }   undef
       4  1  undef        [1, 2, 3, 5 .. 11, 13, 14, 16 .. 19, 21, 22, 24 .. 27, 29, 30, 32]
       5     undef        [6]
       6     { b => 7 }   undef
       7  1  undef        [1, 2, 3, 5, 6, 8 .. 11, 13, 14, 16 .. 19, 21, 22, 24 .. 27, 29, 30, 32]
       8  1  undef        [9, 10, 11, 13, 14, 16 .. 19, 21, 22, 24 .. 27, 29, 30, 32]
       9  1  undef        [10, 11, 13, 14, 16 .. 19, 21, 22, 24 .. 27, 29, 30, 32]
      10     undef        [11, 13, 14]
      11     { a => 12 }  undef
      12  1  undef        [9, 10, 11, 13 .. 19, 21, 22, 24 .. 27, 29, 30, 32]
      13     undef        [14]
      14     { b => 15 }  undef
      15  1  undef        [9, 10, 11, 13, 14, 16 .. 19, 21, 22, 24 .. 27, 29, 30, 32]
      16  1  undef        [17, 18, 19, 21, 22, 24 .. 27, 29, 30, 32]
      17  1  undef        [18, 19, 21, 22, 24 .. 27, 29, 30, 32]
      18     undef        [19, 21, 22]
      19     { a => 20 }  undef
      20  1  undef        [17, 18, 19, 21 .. 27, 29, 30, 32]
      21     undef        [22]
      22     { b => 23 }  undef
      23  1  undef        [17, 18, 19, 21, 22, 24 .. 27, 29, 30, 32]
      24  1  undef        [25, 26, 27, 29, 30, 32]
      25  1  undef        [26, 27, 29, 30, 32]
      26     undef        [27, 29, 30]
      27     { a => 28 }  undef
      28  1  undef        [25, 26, 27, 29 .. 32]
      29     undef        [30]
      30     { b => 31 }  undef
      31  1  undef        [25, 26, 27, 29, 30, 32]
      32  1  undef        undef
END
 }

if (1) {                                                                        #Texcept
  my $nfa = fromExpr(choice(qw(a b c)), except(qw(c x)), choice(qw(a b c)));

  is_deeply $nfa->print("(a|b|c)(c!x)(a|b|c)"), <<END;
(a|b|c)(c!x)(a|b|c)
Location  F  Transitions  Jumps
       0     undef        [1, 2, 4, 5, 7, 8]
       1     undef        [2, 4, 5, 7, 8]
       2     { a => 3 }   undef
       3     undef        [9, 10, 11, 13, 14]
       4     undef        [5]
       5     { b => 6 }   undef
       6     undef        [9, 10, 11, 13, 14]
       7     undef        [8]
       8     { c => 9 }   undef
       9     undef        [10, 11, 13, 14]
      10     undef        [11, 13, 14]
      11     { a => 12 }  undef
      12     undef        [15, 16, 17, 19, 20, 22, 23]
      13     undef        [14]
      14     { b => 15 }  undef
      15     undef        [16, 17, 19, 20, 22, 23]
      16     undef        [17, 19, 20, 22, 23]
      17     { a => 18 }  undef
      18  1  undef        [24]
      19     undef        [20]
      20     { b => 21 }  undef
      21  1  undef        [24]
      22     undef        [23]
      23     { c => 24 }  undef
      24  1  undef        undef
END

  ok !$nfa->parse(qw(a a));
  ok  $nfa->parse(qw(a a a));
  ok !$nfa->parse(qw(a c a));
 }

if (1) {
  my $nfa = fromExpr(sequence(qw(a b c)), except(qw(c x)));

  is_deeply $nfa->print("(abc)(c!x)"), <<END;
(abc)(c!x)
Location  F  Transitions  Jumps
       0     undef        [1, 2]
       1     undef        [2]
       2     { a => 3 }   undef
       3     undef        [4]
       4     { b => 5 }   undef
       5     undef        [6]
       6     { c => 7 }   undef
       7     undef        [8, 9, 11, 12]
       8     undef        [9, 11, 12]
       9     { a => 10 }  undef
      10  1  undef        [13]
      11     undef        [12]
      12     { b => 13 }  undef
      13  1  undef        undef
END

  ok  $nfa->parse(qw(a b c a));
  ok  $nfa->parse(qw(a b c b));
  ok !$nfa->parse(qw(a b c c));
 }

if (1) {
  my $nfa = fromExpr(choice(zeroOrMore(q(a)), q(b)));

  is_deeply $nfa->print("a*|b+"), <<END;
a*|b+
Location  F  Transitions  Jumps
       0  1  undef        [1, 2, 3, 5 .. 8]
       1  1  undef        [2, 3, 5 .. 8]
       2  1  undef        [3, 5, 8]
       3     { a => 4 }   undef
       4  1  undef        [2, 3, 5, 8]
       5  1  undef        [8]
       6     undef        [7]
       7     { b => 8 }   undef
       8  1  undef        undef
END

  ok  $nfa->parse(qw());
  ok  $nfa->parse(qw(a));
  ok  $nfa->parse(qw(a a));
  ok  $nfa->parse(qw(b));
  ok !$nfa->parse(qw(b b));
  ok !$nfa->parse(qw(a b));
  ok !$nfa->parse(qw(a a b));
  ok !$nfa->parse(qw(b a));
 }

latestTest:;

done_testing;
#owf(q(/home/phil/z/z/z/zzz.txt), dump($nfa));
