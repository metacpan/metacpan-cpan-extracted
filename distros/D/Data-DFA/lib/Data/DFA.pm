#!/usr/bin/perl -I/home/phil/perl/cpan/DataNFA/lib/
#-------------------------------------------------------------------------------
# Deterministic finite state parser from a regular expression.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2018-2020
#-------------------------------------------------------------------------------
# podDocumentation
package Data::DFA;
our $VERSION = 20201031;
require v5.26;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::NFA;
use Data::Table::Text qw(:all);
use feature qw(current_sub say);

#  dfa: {state=>state name, transitions=>{symbol=>state}, final state=>{reduction rule=>1}, pumps=>[[pumping lemmas]]}

my $logFile = q(/home/phil/z/z/z/zzz.txt);                                      # Log printed results if developing

#D1 Construct regular expression                                                # Construct a regular expression that defines the language to be parsed using the following combining operations:

sub element($)                                                                  #S One element.
 {my ($label) = @_;                                                             # Transition symbol
  &Data::NFA::element(@_);
 }

sub sequence(@)                                                                 #S Sequence of elements.
 {my (@elements) = @_;                                                          # Elements
  &Data::NFA::sequence(@_);
 }

sub optional(@)                                                                 #S An optional sequence of element.
 {my (@element) = @_;                                                           # Elements
  &Data::NFA::optional(@_);
 }

sub zeroOrMore(@)                                                               #S Zero or more repetitions of a sequence of elements.
 {my (@element) = @_;                                                           # Elements
  &Data::NFA::zeroOrMore(@_);
 }

sub oneOrMore(@)                                                                #S One or more repetitions of a sequence of elements.
 {my (@element) = @_;                                                           # Elements
  &Data::NFA::oneOrMore(@_);
 }

sub choice(@)                                                                   #S Choice from amongst one or more elements.
 {my (@elements) = @_;                                                          # Elements to be chosen from
  &Data::NFA::choice(@_);
 }

sub except(@)                                                                   #S Choice from amongst all symbols except the ones mentioned
 {my (@elements) = @_;                                                          # Elements to be chosen from
  &Data::NFA::except(@_);
 }

#1 Deterministic finite state parser                                            # Create a deterministic finite state automaton to parse sequences of symbols in the language defined by a regular expression.

sub newDFA                                                                      #P Create a new DFA.
 {genHash(q(Data::DFA));                                                        # DFA State
 }

sub newState(%)                                                                 #P Create a new DFA state with the specified options.
 {my (%options) = @_;                                                           # DFA state as hash

  my $r = genHash(q(Data::DFA::State),                                          # DFA State
    state       => undef,                                                       # Name of the state - the join of the NFA keys
    nfaStates   => undef,                                                       # Hash whose keys are the NFA states that contributed to this super state
    transitions => undef,                                                       # Transitions from this state
    final       => undef,                                                       # Whether this state is final
    pump        => undef,                                                       # Pumping lemmas for this state
    sequence    => undef,                                                       # Sequence of states to final state minus pumped states
   );

  %$r = (%$r, %options);

  $r
 }

sub fromNfa($)                                                                  #P Create a DFA parser from an NFA.
 {my ($nfa) = @_;                                                               # Nfa

  my $dfa       = newDFA;                                                       # A DFA is a hash of states

  my @nfaStates = (0, $nfa->statesReachableViaJumps(0)->@*);                    # Nfa states reachable from the start state
  my $initialSuperState = join ' ', sort @nfaStates;                            # Initial super state

  $$dfa{$initialSuperState} = newState(                                         # Start state
    state       => $initialSuperState,                                          # Name of the state - the join of the NFA keys
    nfaStates   => {map{$_=>1} @nfaStates},                                     # Hash whose keys are the NFA states that contributed to this super state
    final       => finalState($nfa, {map {$_=>1} @nfaStates}),                  # Whether this state is final
   );

  $dfa->superStates($initialSuperState, $nfa);                                  # Create DFA superstates from states reachable from the start state

  my $r = $dfa->renumberDfa($initialSuperState);                                # Renumber
  my $d = $r->removeDuplicatedStates;                                           # Remove duplicate states
  my $u = $d->removeUnreachableStates;                                          # Remove unreachable states
  my $R = $u->renumberDfa(0);                                                   # Renumber again

  $R                                                                            # Resulting Dfa
 }

sub fromExpr(@)                                                                 #S Create a DFA parser from a regular B<@expression>.
 {my (@expression) = @_;                                                        # Regular expression
  fromNfa(Data::NFA::fromExpr(@expression))
 }

sub finalState($$)                                                              #P Check whether, in the specified B<$nfa>, any of the states named in the hash reference B<$reach> are final. Final states that refer to reduce rules are checked for reduce conflicts.
 {my ($nfa, $reach) = @_;                                                       # NFA, hash of states in the NFA
  my @final;                                                                    # Reduction rule

  for my $state(sort keys %$reach)                                              # Each state we can reach
   {if (my $f = $nfa->isFinal($state))
     {push @final, $f;
     }
   }

  @final ? \@final : undef;                                                     # undef if not final else reduction rules
 }

sub superState($$$$$)                                                           #P Create super states from existing superstate.
 {my ($dfa, $superStateName, $nfa, $symbols, $nfaSymbolTransitions) = @_;       # DFA, start state in DFA, NFA we are converting, symbols in the NFA we are converting, states reachable from each state by symbol
  my $superState  = $$dfa{$superStateName};
  my $nfaStates   = $superState->nfaStates;

  my @created;                                                                  # New super states created
  for my $symbol(@$symbols)                                                     # Each symbol
   {my $reach = {};                                                             # States in NFS reachable from start state in dfa
    for my $nfaState(sort keys %$nfaStates)                                     # Each NFA state in the dfa start state
     {if (my $r = $$nfaSymbolTransitions{$nfaState}{$symbol})                   # States in the NFA reachable on the symbol
       {map{$$reach{$_}++} @$r;                                                 # Accumulate NFA reachable NFA states
       }
     }

    if (keys %$reach)                                                           # Current symbol takes us somewhere
     {my $newSuperStateName = join ' ', sort keys %$reach;                      # Name of the super state reached from the start state via the current symbol
      if (!$$dfa{$newSuperStateName})                                           # Super state does not exists so create it
       {my $newState  = $$dfa{$newSuperStateName} = newState
         (nfaStates   => $reach,
          transitions => undef,
          final       => finalState($nfa, $reach),
         );
        push @created, $newSuperStateName;                                      # Find all its transitions
       }
      $$dfa{$superStateName}->transitions->{$symbol} = $newSuperStateName;
     }
   }

  @created
 }

sub superStates($$$)                                                            #P Create super states from existing superstate.
 {my ($dfa, $SuperStateName, $nfa) = @_;                                        # DFA, start state in DFA, NFA we are tracking
  my $symbols     = [$nfa->symbols];                                            # Symbols in nfa
  my $transitions = $nfa->allTransitions;                                       # Precompute transitions in the NFA

  my @fix = ($SuperStateName);
  while(@fix)                                                                   # Create each superstate as the set of all nfa states we could be in after each transition on a symbol
   {push @fix, superState($dfa, pop @fix, $nfa, $symbols, $transitions);
   }
 }

sub transitionOnSymbol($$$)                                                     #P The super state reached by transition on a symbol from a specified state.
 {my ($dfa, $superStateName, $symbol) = @_;                                     # DFA, start state in DFA, symbol
  my $superState  = $$dfa{$superStateName};
  my $transitions = $superState->transitions;

  $$transitions{$symbol}
 } # transitionOnSymbol

sub renumberDfa($$)                                                             #P Renumber the states in the specified B<$dfa>.
 {my ($dfa, $initialStateName) = @_;                                            # DFA, initial super state name
  my %rename;
  my $cfa = newDFA;

  $rename{$initialStateName} = 0;                                               # The start state is always 0 in the dfa
  for my $s(sort keys %$dfa)                                                    # Each state
   {$rename{$s} = keys %rename if !exists $rename{$s};                          # Rename state
   }

  for my $superStateName(sort keys %$dfa)                                       # Each state
   {my $sourceState = $rename{$superStateName};
    my $s = $$cfa{$sourceState} = newState;
    my $superState  = $$dfa{$superStateName};

    my $transitions = $superState->transitions;
    for my $symbol(sort keys %$transitions)                                     # Rename the target of every transition
     {$s->transitions->{$symbol} = $rename{$$transitions{$symbol}};
     }

    $s->final = $superState->final;
   }

  $cfa
 } # renumberDfa

sub univalent($)                                                                # Check that the L<DFA> is univalent: a univalent L<DFA> has a mapping from symbols to states. Returns a hash showing the mapping from symbols to states  if the L<DFA> is univalent, else returns B<undfef>.
 {my ($dfa) = @_;                                                               # Dfa to check

  my %symbols;                                                                  # Symbol to states
  for my $state(sort keys %$dfa)                                                # Each state name
   {my $transitions = $$dfa{$state}->transitions;                               # Transitions from state being checked
    for my $symbol(sort keys %$transitions)                                     # Each transition from the state being checked
     {my $target = $$transitions{$symbol};                                      # New state reached by transition from state being checked
      $symbols{$symbol}{$target}++;                                             # Count targets for symbol
     }
   }

  my @multiple; my %single;                                                     # Symbols with multiple targets, single targets
  for my $symbol(sort keys %symbols)                                            # Symbols
   {my @states = sort keys $symbols{$symbol}->%*;                               # States
    if (@states == 1)                                                           # Single target
     {($single{$symbol}) = @states;                                             # Mapping
     }
    else                                                                        # Multiple targets
     {push @multiple, $symbol
     }
   }

  dumpFile($logFile, \%single) if -e $logFile and !@multiple;                   # Log the result if requested

  @multiple ? undef : \%single                                                  # Only return the mapping if it is valid
 } # univalent

#D1 Print                                                                       # Pritn the Dfa in various ways.

sub printFinal($)                                                               #P Print a final state
 {my ($final) = @_;                                                             # final State
  my %f;
  for my $f(@$final)
   {$f{ref($f) ? $f->print->($f) : $f}++;
   }
  join ' ', sort keys %f;
 }

sub print($;$)                                                                  # Print the specified B<$dfa> using the specified B<$title>.
 {my ($dfa, $title) = @_;                                                       # DFA, optional title

  my @out;
  for my $superStateName(sort {$a <=> $b} keys %$dfa)                           # Each state
   {my $superState  = $$dfa{$superStateName};
    my $transitions = $superState->transitions;
    my $Final       = $superState->final;
    if (my @s = sort keys %$transitions)                                        # Transitions present
     {my $s = $s[0];
      my $S = $dfa->transitionOnSymbol($superStateName, $s);
      my $final = $$dfa{$S}->final;
      push @out, [$superStateName, $Final ? 1 : q(), $s, $$transitions{$s},
                                   printFinal($final)];
      for(1..$#s)
       {my $s = $s[$_];
        my $S = $dfa->transitionOnSymbol($superStateName, $s);
        my $final = $$dfa{$S}->final;
        push @out, ['', '', $s, $$transitions{$s}, printFinal($final)];
       }
     }
    else                                                                        # No transitions present
     {push @out, [$superStateName, $Final ? 1 : q(), q(), q(), printFinal($Final)];
     }
   }

  my $r = sub                                                                   # Format results as a table
   {if (@out)
     {my $t = formatTable([@out], [qw(State Final Symbol Target Final)])."\n";
      my $s = $title ? "$title\n$t" : $t;
      $s =~ s(\s*\Z) ()gs;
      $s =~ s(\s*\n) (\n)gs;
      return "$s\n";
     }
    "$title: No states in Dfa";
   }->();

  owf($logFile, $r) if -e $logFile;                                             # Log the result if requested
  $r                                                                            # Return the result
 }

sub symbols($)                                                                  # Return an array of all the symbols accepted by a B<$dfa>.
 {my ($dfa) = @_;                                                               # DFA
  my %symbols;
  for my $superState(values %$dfa)                                              # Each state
   {my $transitions = $superState->transitions;
    $symbols{$_}++ for sort keys %$transitions;                                 # Symbol for each transition
   }

  sort keys %symbols;
 }

sub parser($;$)                                                                 # Create a parser from a B<$dfa> constructed from a regular expression.
 {my ($dfa, $observer) = @_;                                                    # Deterministic finite state automaton, optional observer
  return genHash(q(Data::DFA::Parser),                                          # Parse a sequence of symbols with a DFA
    dfa       => $dfa,                                                          # DFA being used
    state     => 0,                                                             # Current state
    fail      => undef,                                                         # Symbol on which we failed
    observer  => $observer,                                                     # Optional sub($parser, $symbol, $target) to observe transitions.
    processed => [],                                                             # Symbols processed
   );
 }

sub dumpAsJson($)                                                               # Create a JSON string representing a B<$dfa>.
 {my ($dfa) = @_;                                                               # Deterministic finite state automaton generated from an expression
  my $jfa;
  for my $state(sort keys %$dfa)                                                # Each state
   {my $transitions = $$dfa{$state}->transitions;                               # Transitions
    for my $t(sort keys %$transitions)
     {$$jfa{transitions}{$state}{$t} = $$transitions{$t};                       # Clone transitions
     }
    $$jfa{finalStates}{$state} = $$dfa{$state}->final;                          # Final states
   }
  encodeJson($jfa);
 }

sub removeDuplicatedStates($)                                                   #P Remove duplicated states in a B<$dfa>.
 {my ($dfa)   = @_;                                                             # Deterministic finite state automaton generated from an expression
  my $deleted;                                                                  # Deleted state count

  for(1..100)                                                                   # Keep squeezing out duplicates
   {my %d;
    for my $state(sort keys %$dfa)                                              # Each state
     {my $s = $$dfa{$state};                                                    # State
#     my $c = dump([$s->transitions, $s->final]);                               # State content
      my $c = dump([$s->transitions, $s->final ? 1 : 0]);                       # State content - we only need to know if the state is final or not
      push $d{$c}->@*, $state;
     }

    my %m;                                                                      # Map deleted duplicated states back to undeleted original
    for my $d(values %d)                                                        # Delete unitary states
     {my ($b, @d) = $d->@*;
      if (@d)
       {for my $r(@d)                                                           # Map duplicated states to base unduplicated state
         {$m{$r} = $b;                                                          # Map
          delete $$dfa{$r};                                                     # Remove duplicated state from DFA
          ++$deleted;
         }
       }
     }

    if (keys %m)                                                                # Remove duplicate states
     {for my $state(values %$dfa)                                               # Each state
       {my $transitions = $state->transitions;
        for my $symbol(sort keys %$transitions)
         {my $s = $$transitions{$symbol};
          if (defined $m{$s})
           {$$transitions{$symbol} = $m{$s};
           }
         }
       }
     }
    else {last};
   }

  $deleted ? renumberDfa($dfa, 0) : $dfa;                                       # Renumber states if necessary
 } # removeDuplicatedStates

sub removeUnreachableStates($)                                                  #P Remove unreachable states in a B<$dfa>.
 {my ($dfa)   = @_;                                                             # Deterministic finite state automaton generated from an expression
  my $deleted = 0;                                                              # Count of deleted unreachable states
  my %reachable;                                                                # States reachable from the start state
  my %checked;                                                                  # States that have been checked
  my @check;                                                                    # States to check

  my ($startState) = sort keys %$dfa;                                           # Start state name
  $reachable{$startState}++;                                                    # Mark start state as reachable
  $checked{$startState}++;                                                      # Mark start state as checked
  push @check, $startState;                                                     # Check start state

  while(@check)                                                                 # Check each state reachable from the start state
   {my $state = pop @check;                                                     # State to check
    for my $s(sort keys $$dfa{$state}->transitions->%*)                         # Target each transition from the state
     {my $t = $$dfa{$state}->transitions->{$s};                                 # Target state
      $reachable{$t}++;                                                         # Mark target as reachable
      push @check, $t unless $checked{$t}++;                                    # Check states reachable from the target state unless already checked
     }
   }

  for my $s(sort keys %$dfa)                                                    # Each state
   {if (!$reachable{$s})                                                        # Unreachable state
     {++$deleted;                                                               # Count unreachable states
      delete $$dfa{$s};                                                         # Remove unreachable state
     }
   }
  my $r = $deleted ? renumberDfa($dfa, 0) : $dfa;                               # Renumber states if necessary
  $r
 }

# Trace from the start node through to each node remembering the long path.  If
# we reach a node we have already visited then add a pumping lemma to it as the
# long path minus the short path used to reach the node the first time.
#
# Trace from start node to final states without revisiting nodes. Write the
# expressions so obtained as a choice of sequences with pumping lemmas.

sub printAsExpr2($%)                                                            #P Print a DFA B<$dfa_> in an expression form determined by the specified B<%options>.
 {my ($dfa, %options) = @_;                                                     # Dfa, options.

  checkKeys(\%options,                                                          # Check options
   {element    => q(Format a single element),
    choice     => q(Format a choice of expressions),
    sequence   => q(Format a sequence of expressions),
    zeroOrMore => q(Format zero or more instances of an expression),
    oneOrMore  => q(One or more instances of an expression),
   });

  my ($fe, $fc, $fs, $fz, $fo) = @options{qw(element choice sequence zeroOrMore oneOrMore)};

  my %pumped;                                                                   # States pumped => [symbols along pump]
  my $pump; $pump = sub                                                         # Create pumping lemmas for each state
   {my ($state, @path) = @_;                                                    # Current state, path to state
    if (defined $pumped{$state})                                                # State already visited
     {my @pump = @path[$pumped{$state}..$#path];                                # Long path minus short path
      push $$dfa{$state}->pump->@*, [@pump] if @pump;                           # Add the pumping lemma
     }
    else                                                                        # State not visited
     {my $transitions = $$dfa{$state}->transitions;                             # Transitions hash
      $pumped{$state} = @path;                                                  # Record visit to this state
      for my $t(sort keys %$transitions)                                        # Visit each adjacent states
       {&$pump($$transitions{$t}, @path, $t);                                   # Visit adjacent state
       }
     }
   };

  &$pump(0);                                                                    # Find the pumping lemmas for each node

  my %visited;                                                                  # States visited => [symbols along path to state]
  my $visit; $visit = sub                                                       # Find non pumped paths
   {my ($state, @path) = @_;                                                    # Current state, sequence to get here
    if (@path and $$dfa{$state}->final)                                         # Non empty path leads to final state
     {push $$dfa{$state}->sequence->@*, [@path]                                 # Record path as a sequence that leads to a final state
     }
    if (!defined $visited{$state})                                              # States not yet visited
     {my $transitions = $$dfa{$state}->transitions;                             # Transitions hash
      $visited{$state} = [@path];
      for my $symbol(sort keys %$transitions)                                   # Visit each adjacent states
       {my $s = $$transitions{$symbol};                                         # Adjacent state
        &$visit($$transitions{$symbol}, @path, [$state, $symbol, $s]);          # Visit adjacent state
       }
      delete $visited{$state};
     }
   };

  &$visit(0);                                                                   # Find unpumped paths

  my @choices;                                                                  # Construct regular expression as choices amongst pumped paths
  for my $s(sort keys %$dfa)                                                    # Each state name
   {my $state =       $$dfa{$s};                                                # Each state

    if ($state->final)                                                          # Final state
     {for my $path($state->sequence->@*)                                        # Each path to this state
       {my @seq;

        for my $step(@$path)                                                    # Current state, sequence to get here
         {my ($from, $symbol, $to) = @$step;                                    # States not yet visited
          push @seq, &$fe($symbol) unless $from == $to;                         # Add element unless looping in a final state

          if (my $pump = $$dfa{$to}->pump)                                      # Add pumping lemmas
           {my @c;
            for my $p(@$pump)                                                   # Add each pumping lemma for this state
             {if (@$p == 1)                                                     # Format one element
               {push @c, &$fe($$p[0]);
               }
              else                                                              # Sequence of several elements
               {push @c, &$fs(map {&$fe($_)} @$p);
               }
             }

            my sub insertPump($)                                                # Insert a pumping path
             {my ($c) = @_;                                                     # Pumping path, choice
              my $z = &$fz($c);
              if (@seq and $seq[-1] eq $c)                                      # Sequence plus zero or more of same sequence is one or more of sequence
               {$seq[-1] = &$fo($c)
               }
              elsif (!@seq or $seq[-1] ne $z && $seq[-1] ne &$fo($c))           # Suppress multiple zero or more or one and more followed by zero or more of the same item
               {push @seq, $z
               }
             }

            if (@c == 1) {insertPump $c[0]}                                     # Only one pumping lemma
            else         {insertPump &$fc(@c)}                                  # Multiple pumping lemmas
           }
         }
        push @choices, &$fs(@seq);                                              # Combine choice of sequences from start state
       }
     }
   };

  my sub debracket($)                                                           # Remove duplicated outer brackets
   {my ($re) = @_;                                                              # Re
    while(length($re) > 1 and substr($re,  0, 1) eq '(' and
                              substr($re, -1, 1) eq ')')
     {$re = substr($re, 1, -1)
     }
    $re
   }

  return debracket $choices[0] if @choices == 1;                                # No wrapping needed if only one choice
  debracket &$fc(map {&$fs($_)} @choices)
 } # printAsExpr2

sub printAsExpr($)                                                              # Print a B<$dfa> as an expression.
 {my ($dfa) = @_;                                                               # DFA

  my %options =                                                                 # Formatting methods
   (element    => sub
     {my ($e) = @_;
      qq/element(q($e))/
     },
    choice     => sub
     {my $c = join ', ', @_;
      qq/choice($c)/
     },
    sequence   => sub
     {my $s = join ', ', @_;
      qq/sequence($s)/
     },
    zeroOrMore => sub
     {my ($z) = @_;
      qq/zeroOrMore($z)/
     },
    oneOrMore  => sub
     {my ($o) = @_;
      qq/oneOrMore($o)/
     },
   );

  my $r = printAsExpr2($dfa, %options);                                         # Create an expression for the DFA
  if (1)                                                                        # Remove any unnecessary outer sequence
   {my $s = q/sequence(/;
    if (substr($r, 0, length($s)) eq $s and substr($r, -1, 1) eq q/)/)
     {$r = substr($r, length($s), -1)
     }
   }
  $r
 }

sub printAsRe($)                                                                # Print a B<$dfa> as a regular expression.
 {my ($dfa) = @_;                                                               # DFA

  my %options =                                                                 # Formatting methods
   (element    => sub {my ($e) = @_; $e},
    choice     => sub
     {my %c = map {$_=>1} @_;
      my @c = sort keys %c;
      return $c[0] if @c == 1;
      my $c = join ' | ', @c;
      qq/($c)/
     },
    sequence   => sub
     {return $_[0] if @_ == 1;
      my $s = join ' ', @_;
      qq/($s)/
     },
    zeroOrMore => sub {my ($z) = @_; qq/$z*/},
    oneOrMore  => sub {my ($z) = @_; qq/$z+/},
   );

  printAsExpr2($dfa, %options);                                                 # Create an expression for the DFA
 }

sub parseDtdElementAST($)                                                       # Convert the Dtd Element definition in B<$string> to a parse tree.
 {my ($string) = @_;                                                            # String representation of DTD element expression
  package dtdElementDfa;
  use Carp;
  use Data::Dump qw(dump);
  use Data::Table::Text qw(:all);

  sub element($)                                                                # An element
   {my ($e) = @_;
    bless ['element', $e]
   }

  sub  multiply                                                                 # Zero or more, one or more, optional
   {my ($l, $r) = @_;
    my $o = sub
     {return q(zeroOrMore) if $r eq q(*);
      return q(oneOrMore)  if $r eq q(+);
      return q(optional)   if $r eq q(?);
      confess "Unexpected multiplier $r";
     }->();
    bless [$o, $l];
   }

  sub choice                                                                    # Choice
   {my ($l, $r) = @_;
    bless ["choice", $l, $r];
   }

  sub sequence                                                                  # Sequence
   {my ($l, $r) = @_;
    bless ["sequence", $l, $r];
   }

  use overload
    '**'  => \&multiply,
    '*'   => \&choice,
    '+'   => \&sequence;

  sub parse($)                                                                  # Parse a string
   {my ($S) = @_;                                                               # String
    my $s = $S;
    $s =~ s(#PCDATA)      (PCDATA)gs;
    $s =~ s(((\w|-)+))    (element(q($1)))gs;                                   # Word
    $s =~ s(\)\s*([*+?])) (\) ** q($1))gs;
    $s =~ s(\|)           (*)gs;
    $s =~ s(,\s+)         (+)gs;
    my $r = eval $s;
    say STDERR "$@\n$S\n$s\n" if $@;
    $r
   }

  parse($string)                                                                # Parse the DTD element expression into a tree
 }

sub parseDtdElement($)                                                          # Convert the L<XML> <>DTD> Element definition in the specified B<$string> to a DFA.
 {my ($string) = @_;                                                            # DTD element expression string
  fromExpr parseDtdElementAST($string)                                          # Create a DFA from a parse tree created from the Dtd element expression string
 }

#D1 Paths                                                                       # Find paths in a DFA.

sub subArray($$)                                                                #P Whether the second array is contained within the first.
 {my ($A, $B) = @_;                                                             # Exterior array, interior array
  return 1 unless @$B;                                                          # The empty set is contained by every set
  my @a       = @$A;
  my ($b, @b) = @$B;                                                            # Next element to match in the second array
  while(@a)                                                                     # Each start position in the first array
   {my $a = shift @a;
    return 1 if $a eq $b and __SUB__->([@a], [@b])                              # Current position matches and remainder of second array is contained in the remainder of the first array
   }
  0
 }

sub removeLongerPathsThatContainShorterPaths($)                                 #P Remove longer paths that contain shorter paths.
 {my ($paths) = @_;                                                             # Paths
  my @paths = sort keys %$paths;                                                # Paths in definite order
  for   my $p(@paths)                                                           # Each long path
   {next unless exists $$paths{$p};                                             # Long path still present
    for my $q(@paths)                                                           # Each short path
     {next unless exists $$paths{$q};                                           # Short path still present
      delete $$paths{$p} if $p ne $q and subArray($$paths{$p}, $$paths{$q});    # Remove long path if it contains short path
     }
   }
 }

sub shortPaths($)                                                               # Find a set of paths that reach every state in the DFA with each path terminating in a final state.
 {my ($dfa) = @_;                                                               # DFA
  my %paths;                                                                    # {path => [transitions]} the transitions in each path
  my @path;                                                                     # Transitions in the current path
  my %seen;                                                                     # {state} states already seen in this path

  my sub check($)                                                               # Check remaining states from the specified state
   {my ($state) = @_;                                                           # Check from this state
    $paths{join ' ', @path} = [@path] if $$dfa{$state}->final;                  # Save non repeating path at a final state
    my $transitions = $$dfa{$state}->transitions;                               # Transitions from state being checked
    for my $symbol(sort keys %$transitions)                                     # Each transition from the state being checked not already seen
     {my $new =              $$transitions{$symbol};                            # New state reached by transition from state being checked
      push @path, $symbol;                                                      # Add transition to path
      if (!$seen{$new})                                                         # New state has not been visited yet
       {$seen{$new}++;                                                          # Mark state as already been seen
        __SUB__->($new);                                                        # Check from new state
        delete $seen{$new}                                                      # Mark state as not already been seen
       }
      pop @path;                                                                # Remove current transition from path
     }
   }

  $seen{0}++;                                                                   # Mark start state as seen
  check(0);                                                                     # Start at the start state

  dumpFile($logFile, \%paths) if -e $logFile;                                   # Log the result if requested

  \%paths                                                                       # Hash of non repeating paths
 } # shortPaths

sub longPaths($)                                                                # Find a set of paths that traverse each transition in the DFA with each path terminating in a final state.
 {my ($dfa) = @_;                                                               # DFA
  my %paths;                                                                    # {path => [transitions]} the transitions in each path
  my @path;                                                                     # Transitions in the current path
  my %seen;                                                                     # {state} states already seen in this path so we can avoid loops

  my sub check($)                                                               # Check remaining states from the specified state
   {my ($state) = @_;                                                           # Check from this state
    $paths{join ' ', @path} = [@path] if $$dfa{$state}->final;                  # Save non repeating path at a final state
    my $transitions = $$dfa{$state}->transitions;                               # Transitions from state being checked
    for my $symbol(sort keys %$transitions)                                     # Each transition from the state being checked not already seen
     {my $new =              $$transitions{$symbol};                            # New state reached by transition from state being checked
      if (!$seen{$state}{$symbol}++)                                            # Mark state as already been seen
       {push @path, $symbol;                                                    # Add transition to path
        __SUB__->($new);                                                        # Check from new state
        pop @path;                                                              # Remove current transition from path
        delete $seen{$state}{$symbol}                                           # Mark state as not already been seen
       }
     }
   }

  check(0);                                                                     # Start at the start state

  dumpFile($logFile, \%paths) if -e $logFile;                                   # Log the result if requested

  \%paths                                                                       # Hash of non repeating paths
 } # longPaths

sub loops($)                                                                    # Find the non repeating loops from each state.
 {my ($dfa) = @_;                                                               # DFA
  my %loops;                                                                    #{state=>[[non repeating loop through states]]}

  my sub loopsFromState($)                                                      # Find loops starting at this state
   {my ($start) = @_;                                                           # Check from this state

    my @path;                                                                   # Transitions in the current path
    my %seen;                                                                   # {state} states already seen in this path

    my sub check($)                                                             # Check remaining states from the specified state
     {my ($state) = @_;                                                         # Check from this state
      my $transitions = $$dfa{$state}->transitions;                             # Transitions from state being checked
      for my $symbol(sort keys %$transitions)                                   # Each transition from the state being checked not already seen
       {my $new =              $$transitions{$symbol};                          # New state reached by transition from state being checked
        push @path, $symbol;                                                    # Add transition to path
        push $loops{$start}->@*, [@path] if $new == $start;                     # Save loop
        if (!$seen{$new})                                                       # New state has not been visited yet
         {$seen{$new}++;                                                        # Mark state as already been seen
          __SUB__->($new);                                                      # Check from new state
          delete $seen{$new}                                                    # Mark state as not already been seen
         }
        pop @path;                                                              # Remove current transition from path
       }
     }

    $seen{$start}++;                                                            # Mark start state as seen
    check($start);                                                              # Start at the start state
   }

  loopsFromState($_) for sort keys %$dfa;                                       # Loops from each state
  dumpFile($logFile, \%loops) if -e $logFile;                                   # Log the result if requested

  \%loops
 } # loops

#D1 Parser methods                                                              # Use the DFA to parse a sequence of symbols

sub Data::DFA::Parser::accept($$)                                               # Using the specified B<$parser>, accept the next symbol drawn from the symbol set if possible by moving to a new state otherwise confessing with a helpful message that such a move is not possible.
 {my ($parser, $symbol) = @_;                                                   # DFA Parser, next symbol to be processed by the finite state automaton
  my $dfa = $parser->dfa;                                                       # Dfa
  my $observer    = $parser->observer;                                          # Optional observer
  my $transitions = $$dfa{$parser->state}->transitions;                         # Transitions for current state
  my $nextState = $$transitions{$symbol};                                       # Target state transitioned to
  if (defined $nextState)                                                       # Valid target state
   {$observer->($parser, $symbol, $nextState) if $observer;                     # Log transition if required
    $parser->state = $nextState;                                                # Enter next state
    push @{$parser->processed}, $symbol;                                        # Save transition symbol
    return 1;                                                                   # Success
   }
  else                                                                          # No such transition
   {$parser->{next} = [my @next = sort keys %$transitions];                     # Valid symbols
    my @processed   = @{$parser->processed};                                    # Symbols processed successfully
    $parser->fail   = $symbol;                                                  # Failing symbol

    push my @m, "Already processed: ". join(' ', @processed);                   # Create error message

    if (scalar(@next) > 0)                                                      # Expected
     {push  @m, "Expected one of  : ". join(' ', @next);
     }
    else
     {push  @m, "Expected nothing more.";
     }

    push    @m, "But found        : ". $symbol, "";                             # Found

    die join "\n", @m;
   }
 }

sub Data::DFA::Parser::final($)                                                 # Returns whether the specified B<$parser> is in a final state or not.
 {my ($parser) = @_;                                                            # DFA Parser
  my $dfa = $parser->dfa;
  my $state = $parser->state;
  $$dfa{$state}->final
 }

sub Data::DFA::Parser::next($)                                                  # Returns an array of symbols that would be accepted in the current state by the specified B<$parser>.
 {my ($parser) = @_;                                                            # DFA Parser
  my $dfa = $parser->dfa;
  my $state = $parser->state;
  my $transitions = $$dfa{$state}->transitions;
  sort keys %$transitions
 }

sub Data::DFA::Parser::accepts($@)                                              # Confirm that the specified B<$parser> accepts an array representing a sequence of symbols.
 {my ($parser, @symbols) = @_;                                                  # DFA Parser, array of symbols
  for my $symbol(@symbols)                                                      # Parse the symbols
   {eval {$parser->accept($symbol)};                                            # Try to accept a symbol
    confess "Error in observer: $@" if $@ and $@ !~ m(Already processed);
    return 0 if $@;                                                             # Failed
   }
  $parser->final                                                                # Confirm we are in an end state
 }

#D1 Data Structures                                                             # Data structures used by this package.

#D0
#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT_OK    = qw(
choice
fromExpr
fromNfa
element
except
oneOrMore optional
parser
print
sequence
zeroOrMore
);
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Data::DFA - Deterministic finite state parser from regular expression.

=head1 Synopsis

Create a deterministic finite state parser to recognize sequences of symbols
that match a given regular expression.

To recognize sequences of symbols drawn from B<'a'..'e'> that match
the regular expression: B<a (b|c)+ d? e>:

Create the parser:

  my $dfa = fromExpr
   ("a",
    oneOrMore
     (choice(qw(b c))),
    optional("d"),
    "e"
   );

Recognize sequences of symbols:

  ok  $dfa->parser->accepts(qw(a b e));
  ok  $dfa->parser->accepts(qw(a b c e));
  ok !$dfa->parser->accepts(qw(a d));
  ok !$dfa->parser->accepts(qw(a c d));
  ok  $dfa->parser->accepts(qw(a c d e));

Print the transition table:

  is_deeply $dfa->print("a(b|c)+d?e"), <<END;
a(b|c)+d?e
   State  Final  Symbol  Target  Final
1      0         a            4
2      1         b            1
3                c            1
4                d            2
5                e            3      1
6      2         e            3      1
7      3      1                      1
8      4         b            1
9                c            1
END

Discover why a sequence cannot be recognized:

  my $parser = $dfa->parser;

  eval { $parser->accept($_) } for qw(a b a);

  is_deeply $@, <<END;
Already processed: a b
Expected one of  : b c d e
But found        : a
END

  is_deeply  $parser->fail,       qq(a);
  is_deeply [$parser->next],     [qw(b c d e)];
  is_deeply  $parser->processed, [qw(a b)];

  ok !$parser->final;

To construct and parse regular expressions in the format used by B<!ELEMENT>
definitions in L<DTD>s used to validate L<XML>:

  is_deeply
    parseDtdElement(q(a,  b*,  c))->printAsExpr,
    q/element(q(a)), zeroOrMore(element(q(b))), element(q(c))/;

=head1 Description

Deterministic finite state parser from regular expression.


Version 20201030.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Construct regular expression

Construct a regular expression that defines the language to be parsed using the following combining operations:

=head2 element($label)

One element.

     Parameter  Description
  1  $label     Transition symbol

B<Example:>


    my $dfa = fromExpr                                                            # Construct DFA
     ("a",
      oneOrMore(choice(qw(b c))),
      optional("d"),
      "e"
     );
    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols

    my $dfa = fromExpr                                                            # Construct DFA

     (element("a"),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      oneOrMore(choice(element("b"), element("c"))),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      optional(element("d")),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      element("e")  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     );
    my $parser = $dfa->parser;                                                    # New parser

    eval { $parser->accept($_) } for qw(a b a);                                   # Try to parse a b a

    is_deeply [$parser->next],     [qw(b c d e)];                                 # Next acceptable symbol
    is_deeply  $parser->processed, [qw(a b)];                                     # Symbols processed

    ok !$parser->final;                                                           # Not in a final state

    ok $dfa->dumpAsJson eq <<END, q(dumpAsJson);                                  # Dump as json
  {
     "finalStates" : {
        "0" : null,
        "1" : null,
        "2" : null,
        "4" : null,
        "5" : 1
     },
     "transitions" : {
        "0" : {
           "a" : "2"
        },
        "1" : {
           "b" : "1",
           "c" : "1",
           "d" : "4",
           "e" : "5"
        },
        "2" : {
           "b" : "1",
           "c" : "1"
        },
        "4" : {
           "e" : "5"
        }
     }
  }
  END


This is a static method and so should either be imported or invoked as:

  Data::DFA::element


=head2 sequence(@elements)

Sequence of elements.

     Parameter  Description
  1  @elements  Elements

B<Example:>


    my $dfa = fromExpr                                                            # Construct DFA

     (zeroOrMore(sequence('a'..'c')),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      except('b'..'d')
     );

    ok  $dfa->parser->accepts(qw(a b c a ));
    ok !$dfa->parser->accepts(qw(a b c a b));
    ok !$dfa->parser->accepts(qw(a b c a c));
    ok !$dfa->parser->accepts(qw(a c c a b c));


    ok $dfa->print(q(Test)) eq <<END;                                             # Print renumbered DFA
  Test
     State  Final  Symbol  Target  Final
  1      0         a            1      1
  2      1      1  b            2
  3      2         c            0
  END


This is a static method and so should either be imported or invoked as:

  Data::DFA::sequence


=head2 optional(@element)

An optional sequence of element.

     Parameter  Description
  1  @element   Elements

B<Example:>


    my $dfa = fromExpr                                                            # Construct DFA
     ("a",
      oneOrMore(choice(qw(b c))),

      optional("d"),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      "e"
     );
    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols

    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),
      oneOrMore(choice(element("b"), element("c"))),

      optional(element("d")),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      element("e")
     );
    my $parser = $dfa->parser;                                                    # New parser

    eval { $parser->accept($_) } for qw(a b a);                                   # Try to parse a b a

    is_deeply [$parser->next],     [qw(b c d e)];                                 # Next acceptable symbol
    is_deeply  $parser->processed, [qw(a b)];                                     # Symbols processed

    ok !$parser->final;                                                           # Not in a final state

    ok $dfa->dumpAsJson eq <<END, q(dumpAsJson);                                  # Dump as json
  {
     "finalStates" : {
        "0" : null,
        "1" : null,
        "2" : null,
        "4" : null,
        "5" : 1
     },
     "transitions" : {
        "0" : {
           "a" : "2"
        },
        "1" : {
           "b" : "1",
           "c" : "1",
           "d" : "4",
           "e" : "5"
        },
        "2" : {
           "b" : "1",
           "c" : "1"
        },
        "4" : {
           "e" : "5"
        }
     }
  }
  END


This is a static method and so should either be imported or invoked as:

  Data::DFA::optional


=head2 zeroOrMore(@element)

Zero or more repetitions of a sequence of elements.

     Parameter  Description
  1  @element   Elements

B<Example:>


    my $dfa = fromExpr                                                            # Construct DFA

     (zeroOrMore(sequence('a'..'c')),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      except('b'..'d')
     );

    ok  $dfa->parser->accepts(qw(a b c a ));
    ok !$dfa->parser->accepts(qw(a b c a b));
    ok !$dfa->parser->accepts(qw(a b c a c));
    ok !$dfa->parser->accepts(qw(a c c a b c));


    ok $dfa->print(q(Test)) eq <<END;                                             # Print renumbered DFA
  Test
     State  Final  Symbol  Target  Final
  1      0         a            1      1
  2      1      1  b            2
  3      2         c            0
  END


This is a static method and so should either be imported or invoked as:

  Data::DFA::zeroOrMore


=head2 oneOrMore(@element)

One or more repetitions of a sequence of elements.

     Parameter  Description
  1  @element   Elements

B<Example:>


    my $dfa = fromExpr                                                            # Construct DFA
     ("a",

      oneOrMore(choice(qw(b c))),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      optional("d"),
      "e"
     );
    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols

    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),

      oneOrMore(choice(element("b"), element("c"))),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      optional(element("d")),
      element("e")
     );
    my $parser = $dfa->parser;                                                    # New parser

    eval { $parser->accept($_) } for qw(a b a);                                   # Try to parse a b a

    is_deeply [$parser->next],     [qw(b c d e)];                                 # Next acceptable symbol
    is_deeply  $parser->processed, [qw(a b)];                                     # Symbols processed

    ok !$parser->final;                                                           # Not in a final state

    ok $dfa->dumpAsJson eq <<END, q(dumpAsJson);                                  # Dump as json
  {
     "finalStates" : {
        "0" : null,
        "1" : null,
        "2" : null,
        "4" : null,
        "5" : 1
     },
     "transitions" : {
        "0" : {
           "a" : "2"
        },
        "1" : {
           "b" : "1",
           "c" : "1",
           "d" : "4",
           "e" : "5"
        },
        "2" : {
           "b" : "1",
           "c" : "1"
        },
        "4" : {
           "e" : "5"
        }
     }
  }
  END


This is a static method and so should either be imported or invoked as:

  Data::DFA::oneOrMore


=head2 choice(@elements)

Choice from amongst one or more elements.

     Parameter  Description
  1  @elements  Elements to be chosen from

B<Example:>


    my $dfa = fromExpr                                                            # Construct DFA
     ("a",

      oneOrMore(choice(qw(b c))),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      optional("d"),
      "e"
     );
    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols

    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),

      oneOrMore(choice(element("b"), element("c"))),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      optional(element("d")),
      element("e")
     );
    my $parser = $dfa->parser;                                                    # New parser

    eval { $parser->accept($_) } for qw(a b a);                                   # Try to parse a b a

    is_deeply [$parser->next],     [qw(b c d e)];                                 # Next acceptable symbol
    is_deeply  $parser->processed, [qw(a b)];                                     # Symbols processed

    ok !$parser->final;                                                           # Not in a final state

    ok $dfa->dumpAsJson eq <<END, q(dumpAsJson);                                  # Dump as json
  {
     "finalStates" : {
        "0" : null,
        "1" : null,
        "2" : null,
        "4" : null,
        "5" : 1
     },
     "transitions" : {
        "0" : {
           "a" : "2"
        },
        "1" : {
           "b" : "1",
           "c" : "1",
           "d" : "4",
           "e" : "5"
        },
        "2" : {
           "b" : "1",
           "c" : "1"
        },
        "4" : {
           "e" : "5"
        }
     }
  }
  END


This is a static method and so should either be imported or invoked as:

  Data::DFA::choice


=head2 except(@elements)

Choice from amongst all symbols except the ones mentioned

     Parameter  Description
  1  @elements  Elements to be chosen from

B<Example:>


    my $dfa = fromExpr                                                            # Construct DFA
     (zeroOrMore(sequence('a'..'c')),

      except('b'..'d')  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     );

    ok  $dfa->parser->accepts(qw(a b c a ));
    ok !$dfa->parser->accepts(qw(a b c a b));
    ok !$dfa->parser->accepts(qw(a b c a c));
    ok !$dfa->parser->accepts(qw(a c c a b c));


    ok $dfa->print(q(Test)) eq <<END;                                             # Print renumbered DFA
  Test
     State  Final  Symbol  Target  Final
  1      0         a            1      1
  2      1      1  b            2
  3      2         c            0
  END


This is a static method and so should either be imported or invoked as:

  Data::DFA::except


=head2 fromExpr(@expression)

Create a DFA parser from a regular B<@expression>.

     Parameter    Description
  1  @expression  Regular expression

B<Example:>



    my $dfa = fromExpr                                                            # Construct DFA  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     ("a",
      oneOrMore(choice(qw(b c))),
      optional("d"),
      "e"
     );
    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols


    my $dfa = fromExpr                                                            # Construct DFA  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     (element("a"),
      oneOrMore(choice(element("b"), element("c"))),
      optional(element("d")),
      element("e")
     );
    my $parser = $dfa->parser;                                                    # New parser

    eval { $parser->accept($_) } for qw(a b a);                                   # Try to parse a b a

    is_deeply [$parser->next],     [qw(b c d e)];                                 # Next acceptable symbol
    is_deeply  $parser->processed, [qw(a b)];                                     # Symbols processed

    ok !$parser->final;                                                           # Not in a final state

    ok $dfa->dumpAsJson eq <<END, q(dumpAsJson);                                  # Dump as json
  {
     "finalStates" : {
        "0" : null,
        "1" : null,
        "2" : null,
        "4" : null,
        "5" : 1
     },
     "transitions" : {
        "0" : {
           "a" : "2"
        },
        "1" : {
           "b" : "1",
           "c" : "1",
           "d" : "4",
           "e" : "5"
        },
        "2" : {
           "b" : "1",
           "c" : "1"
        },
        "4" : {
           "e" : "5"
        }
     }
  }
  END


This is a static method and so should either be imported or invoked as:

  Data::DFA::fromExpr


=head2 univalent($dfa)

Check that the L<DFA|https://metacpan.org/pod/Data::DFA> is univalent: a univalent L<DFA|https://metacpan.org/pod/Data::DFA> has a mapping from symbols to states. Returns a hash showing the mapping from symbols to states  if the L<DFA|https://metacpan.org/pod/Data::DFA> is univalent, else returns B<undfef>.

     Parameter  Description
  1  $dfa       Dfa to check

=head1 Print

Pritn the Dfa in various ways.

=head2 print($dfa, $title)

Print the specified B<$dfa> using the specified B<$title>.

     Parameter  Description
  1  $dfa       DFA
  2  $title     Optional title

B<Example:>


    my $dfa = fromExpr                                                            # Construct DFA
     (zeroOrMore(sequence('a'..'c')),
      except('b'..'d')
     );

    ok  $dfa->parser->accepts(qw(a b c a ));
    ok !$dfa->parser->accepts(qw(a b c a b));
    ok !$dfa->parser->accepts(qw(a b c a c));
    ok !$dfa->parser->accepts(qw(a c c a b c));



    ok $dfa->print(q(Test)) eq <<END;                                             # Print renumbered DFA  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  Test
     State  Final  Symbol  Target  Final
  1      0         a            1      1
  2      1      1  b            2
  3      2         c            0
  END


=head2 symbols($dfa)

Return an array of all the symbols accepted by a B<$dfa>.

     Parameter  Description
  1  $dfa       DFA

B<Example:>


    my $dfa = fromExpr                                                            # Construct DFA
     ("a",
      oneOrMore(choice(qw(b c))),
      optional("d"),
      "e"
     );

    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head2 parser($dfa, $observer)

Create a parser from a B<$dfa> constructed from a regular expression.

     Parameter  Description
  1  $dfa       Deterministic finite state automaton
  2  $observer  Optional observer

B<Example:>


    my $dfa = fromExpr                                                            # Construct DFA
     ("a",
      oneOrMore(choice(qw(b c))),
      optional("d"),
      "e"
     );
    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols

    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),
      oneOrMore(choice(element("b"), element("c"))),
      optional(element("d")),
      element("e")
     );

    my $parser = $dfa->parser;                                                    # New parser  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



    eval { $parser->accept($_) } for qw(a b a);                                   # Try to parse a b a  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



    is_deeply [$parser->next],     [qw(b c d e)];                                 # Next acceptable symbol  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply  $parser->processed, [qw(a b)];                                     # Symbols processed  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



    ok !$parser->final;                                                           # Not in a final state  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok $dfa->dumpAsJson eq <<END, q(dumpAsJson);                                  # Dump as json
  {
     "finalStates" : {
        "0" : null,
        "1" : null,
        "2" : null,
        "4" : null,
        "5" : 1
     },
     "transitions" : {
        "0" : {
           "a" : "2"
        },
        "1" : {
           "b" : "1",
           "c" : "1",
           "d" : "4",
           "e" : "5"
        },
        "2" : {
           "b" : "1",
           "c" : "1"
        },
        "4" : {
           "e" : "5"
        }
     }
  }
  END


=head2 dumpAsJson($dfa)

Create a JSON string representing a B<$dfa>.

     Parameter  Description
  1  $dfa       Deterministic finite state automaton generated from an expression

B<Example:>


    my $dfa = fromExpr                                                            # Construct DFA
     ("a",
      oneOrMore(choice(qw(b c))),
      optional("d"),
      "e"
     );
    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols


=head2 printAsExpr($dfa)

Print a B<$dfa> as an expression.

     Parameter  Description
  1  $dfa       DFA

B<Example:>


  if (1)
   {my $e = q/element(q(a)), zeroOrMore(choice(element(q(b)), element(q(c)))), element(q(d))/;
    my $d = eval qq/fromExpr($e)/;
    confess $@ if $@;


    my $E = $d->printAsExpr;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok $e eq $E;

    my $R = $d->printAsRe;
    ok $R eq q(a (b | c)* d);

    my $D = parseDtdElement(q(a, (b | c)*, d));

    my $S = $D->printAsExpr;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok $e eq $S;
   }


=head2 printAsRe($dfa)

Print a B<$dfa> as a regular expression.

     Parameter  Description
  1  $dfa       DFA

B<Example:>


  if (1)
   {my $e = q/element(q(a)), zeroOrMore(choice(element(q(b)), element(q(c)))), element(q(d))/;
    my $d = eval qq/fromExpr($e)/;
    confess $@ if $@;

    my $E = $d->printAsExpr;
    ok $e eq $E;


    my $R = $d->printAsRe;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok $R eq q(a (b | c)* d);

    my $D = parseDtdElement(q(a, (b | c)*, d));
    my $S = $D->printAsExpr;
    ok $e eq $S;
   }


=head2 parseDtdElementAST($string)

Convert the Dtd Element definition in B<$string> to a parse tree.

     Parameter  Description
  1  $string    String representation of DTD element expression

B<Example:>


  if (1)

   {is_deeply unbless(parseDtdElementAST(q(a, (b | c)*, d))),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     ["sequence",
       ["sequence",
          ["element", "a"],
          ["zeroOrMore", ["choice", ["element", "b"], ["element", "c"]]],
       ],
       ["element", "d"],
     ];
   }


=head2 parseDtdElement($string)

Convert the L<Xml|https://en.wikipedia.org/wiki/XML> <>DTD> Element definition in the specified B<$string> to a DFA.

     Parameter  Description
  1  $string    DTD element expression string

B<Example:>


  if (1)
   {my $e = q/element(q(a)), zeroOrMore(choice(element(q(b)), element(q(c)))), element(q(d))/;
    my $d = eval qq/fromExpr($e)/;
    confess $@ if $@;

    my $E = $d->printAsExpr;
    ok $e eq $E;

    my $R = $d->printAsRe;
    ok $R eq q(a (b | c)* d);


    my $D = parseDtdElement(q(a, (b | c)*, d));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    my $S = $D->printAsExpr;
    ok $e eq $S;
   }


=head1 Paths

Find paths in a DFA.

=head2 shortPaths($dfa)

Find a set of paths that reach every state in the DFA with each path terminating in a final state.

     Parameter  Description
  1  $dfa       DFA

B<Example:>


  if (1)
   {my $dfa = fromExpr
     (zeroOrMore("a"),
       oneOrMore("b"),
        optional("c"),
                 "d"
     );

    ok !$dfa->parser->accepts(qw());
    ok !$dfa->parser->accepts(qw(a));
    ok !$dfa->parser->accepts(qw(b));
    ok !$dfa->parser->accepts(qw(c));
    ok !$dfa->parser->accepts(qw(d));
    ok  $dfa->parser->accepts(qw(b c d));
    ok  $dfa->parser->accepts(qw(b d));
    ok !$dfa->parser->accepts(qw(b a));
    ok  $dfa->parser->accepts(qw(b b d));


    is_deeply shortPaths    ($dfa), { "b c d" => ["b", "c", "d"], "b d" => ["b", "d"] };  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply longPaths($dfa),
   {"a b b c d" => ["a", "b", "b", "c", "d"],
    "a b b d"   => ["a", "b", "b", "d"],
    "a b c d"   => ["a" .. "d"],
    "a b d"     => ["a", "b", "d"],
    "b b c d"   => ["b", "b", "c", "d"],
    "b b d"     => ["b", "b", "d"],
    "b c d"     => ["b", "c", "d"],
    "b d"       => ["b", "d"]};
   }


=head2 longPaths($dfa)

Find a set of paths that traverse each transition in the DFA with each path terminating in a final state.

     Parameter  Description
  1  $dfa       DFA

B<Example:>


  if (1)
   {my $dfa = fromExpr
     (zeroOrMore("a"),
       oneOrMore("b"),
        optional("c"),
                 "d"
     );

    ok !$dfa->parser->accepts(qw());
    ok !$dfa->parser->accepts(qw(a));
    ok !$dfa->parser->accepts(qw(b));
    ok !$dfa->parser->accepts(qw(c));
    ok !$dfa->parser->accepts(qw(d));
    ok  $dfa->parser->accepts(qw(b c d));
    ok  $dfa->parser->accepts(qw(b d));
    ok !$dfa->parser->accepts(qw(b a));
    ok  $dfa->parser->accepts(qw(b b d));

    is_deeply shortPaths    ($dfa), { "b c d" => ["b", "c", "d"], "b d" => ["b", "d"] };

    is_deeply longPaths($dfa),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   {"a b b c d" => ["a", "b", "b", "c", "d"],
    "a b b d"   => ["a", "b", "b", "d"],
    "a b c d"   => ["a" .. "d"],
    "a b d"     => ["a", "b", "d"],
    "b b c d"   => ["b", "b", "c", "d"],
    "b b d"     => ["b", "b", "d"],
    "b c d"     => ["b", "c", "d"],
    "b d"       => ["b", "d"]};
   }


=head2 loops($dfa)

Find the non repeating loops from each state.

     Parameter  Description
  1  $dfa       DFA

B<Example:>


  if (1)
   {my $d = fromExpr choice
      oneOrMore "a",
        oneOrMore "b",
          oneOrMore "c",
            oneOrMore "d";

    is_deeply $d->print("(a(b(c(d)+)+)+)+"), <<END;
  (a(b(c(d)+)+)+)+
     State  Final  Symbol  Target  Final
  1      0         a            3
  2      1         d            2      1
  3      2      1  a            3
  4                b            4
  5                c            1
  6                d            2      1
  7      3         b            4
  8      4         c            1
  END

    ok !$d->parser->accepts(qw());
    ok !$d->parser->accepts(qw(a b c));
    ok  $d->parser->accepts(qw(a b c d));
    ok  $d->parser->accepts(qw(a b c d b c d d));
    ok !$d->parser->accepts(qw(a b c b d c d d));
    ok !$d->parser->accepts(qw(a b c d a));


    is_deeply $d->loops, {  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    1 => [["d", "a", "b", "c"], ["d", "b", "c"], ["d", "c"]],
    2 => [["a" .. "d"],         ["b", "c", "d"], ["c", "d"], ["d"]],
    3 => [["b", "c", "d", "a"]],
    4 => [["c", "d", "a", "b"], ["c", "d", "b"]]};

    is_deeply shortPaths($d), {"a b c d" => ["a" .. "d"]};
    is_deeply longPaths ($d), { "a b c d" => ["a" .. "d"], "a b c d d" => ["a" .. "d", "d"] };

    #say STDERR $d->printAsExpr;
   }


=head1 Parser methods

Use the DFA to parse a sequence of symbols

=head2 Data::DFA::Parser::accept($parser, $symbol)

Using the specified B<$parser>, accept the next symbol drawn from the symbol set if possible by moving to a new state otherwise confessing with a helpful message that such a move is not possible.

     Parameter  Description
  1  $parser    DFA Parser
  2  $symbol    Next symbol to be processed by the finite state automaton

B<Example:>


    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),
      oneOrMore(choice(element("b"), element("c"))),
      optional(element("d")),
      element("e")
     );
    my $parser = $dfa->parser;                                                    # New parser

    eval { $parser->accept($_) } for qw(a b a);                                   # Try to parse a b a

    is_deeply [$parser->next],     [qw(b c d e)];                                 # Next acceptable symbol
    is_deeply  $parser->processed, [qw(a b)];                                     # Symbols processed

    ok !$parser->final;                                                           # Not in a final state

    ok $dfa->dumpAsJson eq <<END, q(dumpAsJson);                                  # Dump as json
  {
     "finalStates" : {
        "0" : null,
        "1" : null,
        "2" : null,
        "4" : null,
        "5" : 1
     },
     "transitions" : {
        "0" : {
           "a" : "2"
        },
        "1" : {
           "b" : "1",
           "c" : "1",
           "d" : "4",
           "e" : "5"
        },
        "2" : {
           "b" : "1",
           "c" : "1"
        },
        "4" : {
           "e" : "5"
        }
     }
  }
  END

    my $dfa = fromExpr                                                            # Construct DFA
     (zeroOrMore(sequence('a'..'c')),
      except('b'..'d')
     );

    ok  $dfa->parser->accepts(qw(a b c a ));
    ok !$dfa->parser->accepts(qw(a b c a b));
    ok !$dfa->parser->accepts(qw(a b c a c));
    ok !$dfa->parser->accepts(qw(a c c a b c));


    ok $dfa->print(q(Test)) eq <<END;                                             # Print renumbered DFA
  Test
     State  Final  Symbol  Target  Final
  1      0         a            1      1
  2      1      1  b            2
  3      2         c            0
  END


=head2 Data::DFA::Parser::final($parser)

Returns whether the specified B<$parser> is in a final state or not.

     Parameter  Description
  1  $parser    DFA Parser

B<Example:>


    my $dfa = fromExpr                                                            # Construct DFA
     (zeroOrMore(sequence('a'..'c')),
      except('b'..'d')
     );

    ok  $dfa->parser->accepts(qw(a b c a ));
    ok !$dfa->parser->accepts(qw(a b c a b));
    ok !$dfa->parser->accepts(qw(a b c a c));
    ok !$dfa->parser->accepts(qw(a c c a b c));


    ok $dfa->print(q(Test)) eq <<END;                                             # Print renumbered DFA
  Test
     State  Final  Symbol  Target  Final
  1      0         a            1      1
  2      1      1  b            2
  3      2         c            0
  END


=head2 Data::DFA::Parser::next($parser)

Returns an array of symbols that would be accepted in the current state by the specified B<$parser>.

     Parameter  Description
  1  $parser    DFA Parser

B<Example:>


    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),
      oneOrMore(choice(element("b"), element("c"))),
      optional(element("d")),
      element("e")
     );
    my $parser = $dfa->parser;                                                    # New parser

    eval { $parser->accept($_) } for qw(a b a);                                   # Try to parse a b a

    is_deeply [$parser->next],     [qw(b c d e)];                                 # Next acceptable symbol
    is_deeply  $parser->processed, [qw(a b)];                                     # Symbols processed

    ok !$parser->final;                                                           # Not in a final state

    ok $dfa->dumpAsJson eq <<END, q(dumpAsJson);                                  # Dump as json
  {
     "finalStates" : {
        "0" : null,
        "1" : null,
        "2" : null,
        "4" : null,
        "5" : 1
     },
     "transitions" : {
        "0" : {
           "a" : "2"
        },
        "1" : {
           "b" : "1",
           "c" : "1",
           "d" : "4",
           "e" : "5"
        },
        "2" : {
           "b" : "1",
           "c" : "1"
        },
        "4" : {
           "e" : "5"
        }
     }
  }
  END


=head2 Data::DFA::Parser::accepts($parser, @symbols)

Confirm that the specified B<$parser> accepts an array representing a sequence of symbols.

     Parameter  Description
  1  $parser    DFA Parser
  2  @symbols   Array of symbols

B<Example:>


    my $dfa = fromExpr                                                            # Construct DFA
     ("a",
      oneOrMore(choice(qw(b c))),
      optional("d"),
      "e"
     );
    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols

    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),
      oneOrMore(choice(element("b"), element("c"))),
      optional(element("d")),
      element("e")
     );
    my $parser = $dfa->parser;                                                    # New parser

    eval { $parser->accept($_) } for qw(a b a);                                   # Try to parse a b a

    is_deeply [$parser->next],     [qw(b c d e)];                                 # Next acceptable symbol
    is_deeply  $parser->processed, [qw(a b)];                                     # Symbols processed

    ok !$parser->final;                                                           # Not in a final state

    ok $dfa->dumpAsJson eq <<END, q(dumpAsJson);                                  # Dump as json
  {
     "finalStates" : {
        "0" : null,
        "1" : null,
        "2" : null,
        "4" : null,
        "5" : 1
     },
     "transitions" : {
        "0" : {
           "a" : "2"
        },
        "1" : {
           "b" : "1",
           "c" : "1",
           "d" : "4",
           "e" : "5"
        },
        "2" : {
           "b" : "1",
           "c" : "1"
        },
        "4" : {
           "e" : "5"
        }
     }
  }
  END


=head1 Data Structures

Data structures used by this package.


=head2 Data::DFA Definition


DFA State




=head3 Output fields


=head4 final

Whether this state is final

=head4 nfaStates

Hash whose keys are the NFA states that contributed to this super state

=head4 pump

Pumping lemmas for this state

=head4 sequence

Sequence of states to final state minus pumped states

=head4 state

Name of the state - the join of the NFA keys

=head4 transitions

Transitions from this state



=head2 Data::DFA::Parser Definition


Parse a sequence of symbols with a DFA




=head3 Output fields


=head4 dfa

DFA being used

=head4 fail

Symbol on which we failed

=head4 observer

Optional sub($parser, $symbol, $target) to observe transitions.

=head4 processed

Symbols processed

=head4 state

Current state



=head2 Data::DFA::State Definition


DFA State




=head3 Output fields


=head4 final

Whether this state is final

=head4 nfaStates

Hash whose keys are the NFA states that contributed to this super state

=head4 pump

Pumping lemmas for this state

=head4 sequence

Sequence of states to final state minus pumped states

=head4 state

Name of the state - the join of the NFA keys

=head4 transitions

Transitions from this state



=head1 Private Methods

=head2 newDFA()

Create a new DFA.


=head2 newState(%options)

Create a new DFA state with the specified options.

     Parameter  Description
  1  %options   DFA state as hash

=head2 fromNfa($nfa)

Create a DFA parser from an NFA.

     Parameter  Description
  1  $nfa       Nfa

=head2 finalState($nfa, $reach)

Check whether, in the specified B<$nfa>, any of the states named in the hash reference B<$reach> are final. Final states that refer to reduce rules are checked for reduce conflicts.

     Parameter  Description
  1  $nfa       NFA
  2  $reach     Hash of states in the NFA

=head2 superState($dfa, $superStateName, $nfa, $symbols, $nfaSymbolTransitions)

Create super states from existing superstate.

     Parameter              Description
  1  $dfa                   DFA
  2  $superStateName        Start state in DFA
  3  $nfa                   NFA we are converting
  4  $symbols               Symbols in the NFA we are converting
  5  $nfaSymbolTransitions  States reachable from each state by symbol

=head2 superStates($dfa, $SuperStateName, $nfa)

Create super states from existing superstate.

     Parameter        Description
  1  $dfa             DFA
  2  $SuperStateName  Start state in DFA
  3  $nfa             NFA we are tracking

=head2 transitionOnSymbol($dfa, $superStateName, $symbol)

The super state reached by transition on a symbol from a specified state.

     Parameter        Description
  1  $dfa             DFA
  2  $superStateName  Start state in DFA
  3  $symbol          Symbol

=head2 renumberDfa($dfa, $initialStateName)

Renumber the states in the specified B<$dfa>.

     Parameter          Description
  1  $dfa               DFA
  2  $initialStateName  Initial super state name

B<Example:>


    my $dfa = fromExpr                                                            # Construct DFA
     (zeroOrMore(sequence('a'..'c')),
      except('b'..'d')
     );

    ok  $dfa->parser->accepts(qw(a b c a ));
    ok !$dfa->parser->accepts(qw(a b c a b));
    ok !$dfa->parser->accepts(qw(a b c a c));
    ok !$dfa->parser->accepts(qw(a c c a b c));


    ok $dfa->print(q(Test)) eq <<END;                                             # Print renumbered DFA
  Test
     State  Final  Symbol  Target  Final
  1      0         a            1      1
  2      1      1  b            2
  3      2         c            0
  END


=head2 printFinal($final)

Print a final state

     Parameter  Description
  1  $final     Final State

=head2 removeDuplicatedStates($dfa)

Remove duplicated states in a B<$dfa>.

     Parameter  Description
  1  $dfa       Deterministic finite state automaton generated from an expression

=head2 removeUnreachableStates($dfa)

Remove unreachable states in a B<$dfa>.

     Parameter  Description
  1  $dfa       Deterministic finite state automaton generated from an expression

=head2 printAsExpr2($dfa, %options)

Print a DFA B<$dfa_> in an expression form determined by the specified B<%options>.

     Parameter  Description
  1  $dfa       Dfa
  2  %options   Options.

=head2 subArray($A, $B)

Whether the second array is contained within the first.

     Parameter  Description
  1  $A         Exterior array
  2  $B         Interior array

=head2 removeLongerPathsThatContainShorterPaths($paths)

Remove longer paths that contain shorter paths.

     Parameter  Description
  1  $paths     Paths


=head1 Index


1 L<choice|/choice> - Choice from amongst one or more elements.

2 L<Data::DFA::Parser::accept|/Data::DFA::Parser::accept> - Using the specified B<$parser>, accept the next symbol drawn from the symbol set if possible by moving to a new state otherwise confessing with a helpful message that such a move is not possible.

3 L<Data::DFA::Parser::accepts|/Data::DFA::Parser::accepts> - Confirm that the specified B<$parser> accepts an array representing a sequence of symbols.

4 L<Data::DFA::Parser::final|/Data::DFA::Parser::final> - Returns whether the specified B<$parser> is in a final state or not.

5 L<Data::DFA::Parser::next|/Data::DFA::Parser::next> - Returns an array of symbols that would be accepted in the current state by the specified B<$parser>.

6 L<dumpAsJson|/dumpAsJson> - Create a JSON string representing a B<$dfa>.

7 L<element|/element> - One element.

8 L<except|/except> - Choice from amongst all symbols except the ones mentioned

9 L<finalState|/finalState> - Check whether, in the specified B<$nfa>, any of the states named in the hash reference B<$reach> are final.

10 L<fromExpr|/fromExpr> - Create a DFA parser from a regular B<@expression>.

11 L<fromNfa|/fromNfa> - Create a DFA parser from an NFA.

12 L<longPaths|/longPaths> - Find a set of paths that traverse each transition in the DFA with each path terminating in a final state.

13 L<loops|/loops> - Find the non repeating loops from each state.

14 L<newDFA|/newDFA> - Create a new DFA.

15 L<newState|/newState> - Create a new DFA state with the specified options.

16 L<oneOrMore|/oneOrMore> - One or more repetitions of a sequence of elements.

17 L<optional|/optional> - An optional sequence of element.

18 L<parseDtdElement|/parseDtdElement> - Convert the L<Xml|https://en.wikipedia.org/wiki/XML> <>DTD> Element definition in the specified B<$string> to a DFA.

19 L<parseDtdElementAST|/parseDtdElementAST> - Convert the Dtd Element definition in B<$string> to a parse tree.

20 L<parser|/parser> - Create a parser from a B<$dfa> constructed from a regular expression.

21 L<print|/print> - Print the specified B<$dfa> using the specified B<$title>.

22 L<printAsExpr|/printAsExpr> - Print a B<$dfa> as an expression.

23 L<printAsExpr2|/printAsExpr2> - Print a DFA B<$dfa_> in an expression form determined by the specified B<%options>.

24 L<printAsRe|/printAsRe> - Print a B<$dfa> as a regular expression.

25 L<printFinal|/printFinal> - Print a final state

26 L<removeDuplicatedStates|/removeDuplicatedStates> - Remove duplicated states in a B<$dfa>.

27 L<removeLongerPathsThatContainShorterPaths|/removeLongerPathsThatContainShorterPaths> - Remove longer paths that contain shorter paths.

28 L<removeUnreachableStates|/removeUnreachableStates> - Remove unreachable states in a B<$dfa>.

29 L<renumberDfa|/renumberDfa> - Renumber the states in the specified B<$dfa>.

30 L<sequence|/sequence> - Sequence of elements.

31 L<shortPaths|/shortPaths> - Find a set of paths that reach every state in the DFA with each path terminating in a final state.

32 L<subArray|/subArray> - Whether the second array is contained within the first.

33 L<superState|/superState> - Create super states from existing superstate.

34 L<superStates|/superStates> - Create super states from existing superstate.

35 L<symbols|/symbols> - Return an array of all the symbols accepted by a B<$dfa>.

36 L<transitionOnSymbol|/transitionOnSymbol> - The super state reached by transition on a symbol from a specified state.

37 L<univalent|/univalent> - Check that the L<DFA|https://metacpan.org/pod/Data::DFA> is univalent: a univalent L<DFA|https://metacpan.org/pod/Data::DFA> has a mapping from symbols to states.

38 L<zeroOrMore|/zeroOrMore> - Zero or more repetitions of a sequence of elements.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Data::DFA

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
require v5.26;
use Time::HiRes qw(time);
use Test::More tests=>178;

my $startTime = time();
my $localTest = ((caller(1))[0]//'Data::DFA') eq "Data::DFA";                   # Local testing mode
Test::More->builder->output("/dev/null") if $localTest;                         # Suppress output in local testing mode

#goto latestTest;

if (1)
 {my $d = fromExpr(zeroOrMore(choice(element("a"))),
                   zeroOrMore(choice(element("a"))));

  is_deeply $d->print("a*a*"), <<END;
a*a*
   State  Final  Symbol  Target  Final
1      0      1  a            0      1
END

  ok  $d->parser->accepts(qw());
  ok  $d->parser->accepts(qw(a));
  ok  $d->parser->accepts(qw(a a));
  ok !$d->parser->accepts(qw(b));
  ok !$d->parser->accepts(qw(a b));
  ok !$d->parser->accepts(qw(a a b));
 }

if (1)
 {my $s = q(zeroOrMore(choice(element("a"))));
  my $S = join ', ', ($s) x 4;
  my $d = eval qq(fromExpr(&sequence($S)));
  is_deeply $d->print("a*a* 4:"), <<END;
a*a* 4:
   State  Final  Symbol  Target  Final
1      0      1  a            0      1
END

  ok  $d->parser->accepts(qw(a a a));
  ok !$d->parser->accepts(qw(a b a));
 }

if (1)
 {my $dfa = fromExpr                                                            # Synopsis
   ("a",
    oneOrMore(choice(qw(b c))),
    optional("d"),
    "e"
   );

  ok  $dfa->parser->accepts(qw(a b e));
  ok  $dfa->parser->accepts(qw(a b c e));
  ok !$dfa->parser->accepts(qw(a d));
  ok !$dfa->parser->accepts(qw(a c d));
  ok  $dfa->parser->accepts(qw(a c d e));

  is_deeply ['a'..'e'], [$dfa->symbols];

  is_deeply $dfa->print("a(b|c)+d?e"), <<END;
a(b|c)+d?e
   State  Final  Symbol  Target  Final
1      0         a            4
2      1         b            1
3                c            1
4                d            2
5                e            3      1
6      2         e            3      1
7      3      1                      1
8      4         b            1
9                c            1
END

  my $parser = $dfa->parser;

  eval { $parser->accept($_) } for qw(a b a);

  is_deeply $@, <<END;
Already processed: a b
Expected one of  : b c d e
But found        : a
END

  is_deeply  $parser->fail,      q(a);
  is_deeply [$parser->next],     [qw(b c d e)];
  is_deeply  $parser->processed, [qw(a b)];
  ok !$parser->final;
 }

if (1) {                                                                        #Tsymbols #TfromExpr #Toptional #Telement #ToneOrMore #Tchoice #TData::DFA::Parser::accepts  #TdumpAsJson #Tnext #Tparser
  my $dfa = fromExpr                                                            # Construct DFA
   ("a",
    oneOrMore(choice(qw(b c))),
    optional("d"),
    "e"
   );
  is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols
 }

if (0) {                                                                        #TfromExpr #Toptional #Telement #ToneOrMore #Tchoice #TData::DFA::Parser::symbols #TData::DFA::Parser::accepts #TData::DFA::Parser::accept  #TData::DFA::Parser::next #Tparser
  my $dfa = fromExpr                                                            # Construct DFA
   (element("a"),
    oneOrMore(choice(element("b"), element("c"))),
    optional(element("d")),
    element("e")
   );
  my $parser = $dfa->parser;                                                    # New parser

  eval { $parser->accept($_) } for qw(a b a);                                   # Try to parse a b a

  is_deeply [$parser->next],     [qw(b c d e)];                                 # Next acceptable symbol
  is_deeply  $parser->processed, [qw(a b)];                                     # Symbols processed

  ok !$parser->final;                                                           # Not in a final state

  ok $dfa->dumpAsJson eq <<END, q(dumpAsJson);                                  # Dump as json
{
   "finalStates" : {
      "0" : null,
      "1" : null,
      "2" : null,
      "4" : null,
      "5" : 1
   },
   "transitions" : {
      "0" : {
         "a" : "2"
      },
      "1" : {
         "b" : "1",
         "c" : "1",
         "d" : "4",
         "e" : "5"
      },
      "2" : {
         "b" : "1",
         "c" : "1"
      },
      "4" : {
         "e" : "5"
      }
   }
}
END
 }

if (1) {                                                                        #TzeroOrMore #Texcept #Tsequence #TData::DFA::Parser::final #TData::DFA::Parser::accept #Tprint #TrenumberDfa
  my $dfa = fromExpr                                                            # Construct DFA
   (zeroOrMore(sequence('a'..'c')),
    except('b'..'d')
   );

  ok  $dfa->parser->accepts(qw(a b c a ));
  ok !$dfa->parser->accepts(qw(a b c a b));
  ok !$dfa->parser->accepts(qw(a b c a c));
  ok !$dfa->parser->accepts(qw(a c c a b c));


  ok $dfa->print(q(Test)) eq <<END;                                             # Print renumbered DFA
Test
   State  Final  Symbol  Target  Final
1      0         a            1      1
2      1      1  b            2
3      2         c            0
END
 }

if (1)
 {my $e = q/element(q(a)), zeroOrMore(element(q(b))), element(q(c))/;

  my $d = eval qq/fromExpr($e)/;

  is_deeply $d->printAsExpr, $e;
  is_deeply $d->printAsRe,  q(a b* c);
  is_deeply parseDtdElement(q(a,  b*,  c))->printAsExpr, $e;
 }

if (1)                                                                          #TprintAsExpr #TprintAsRe #TparseDtdElement
 {my $e = q/element(q(a)), zeroOrMore(choice(element(q(b)), element(q(c)))), element(q(d))/;
  my $d = eval qq/fromExpr($e)/;
  confess $@ if $@;

  my $E = $d->printAsExpr;
  ok $e eq $E;

  my $R = $d->printAsRe;
  ok $R eq q(a (b | c)* d);

  my $D = parseDtdElement(q(a, (b | c)*, d));
  my $S = $D->printAsExpr;
  ok $e eq $S;
 }

if (1)                                                                          # bypass
 {my $n = Data::NFA::newNfa;
  Data::NFA::addNewState($n) for 0..2;

  $$n{0}->jumps->{$_}++ for 1..2;
  $$n{1}->transitions->{a} = 2;
  $$n{2}->final = 1;

  my $d = fromNfa($n);

  ok $d->print eq <<END;
   State  Final  Symbol  Target  Final
1      0      1  a            1      1
2      1      1                      1
END
 }

if (1) {
  my $d = fromExpr(zeroOrMore(choice(map{element("$_")} 'a'..'b')));
  ok $d->print("(a|b)*") eq <<END;
(a|b)*
   State  Final  Symbol  Target  Final
1      0      1  a            0      1
2                b            0      1
END
 }

if (1) {
  my $d = fromExpr(zeroOrMore(choice(map{element("$_")} 'a'..'e')));
  is_deeply $d->print("(a|b|c|d|e)*"), <<END;
(a|b|c|d|e)*
   State  Final  Symbol  Target  Final
1      0      1  a            0      1
2                b            0      1
3                c            0      1
4                d            0      1
5                e            0      1
END
 }

if (0) {
  my $d = parseDtdElement('(#PCDATA | dl | parml | div | equation-block | fig | imagemap | syntaxdiagram | equation-figure | image | lines | lq | note | hazardstatement | object | ol | pre | codeblock | msgblock | screen | simpletable | sl | table | ul | boolean | cite | keyword | markupname | apiname | option | parmname | cmdname | msgnum | varname | wintitle | numcharref | parameterentity | textentity | xmlatt | xmlelement | xmlnsname | xmlpi | ph | b | i | line-through | overline | sup | sub | tt | u | codeph | synph | filepath | msgph | systemoutput | userinput | menucascade | uicontrol | equation-inline | q | term | abbreviated-form | text | tm | xref | state | data | sort-as | data-about | foreign | svg-d-foreign | mathml-d-foreign | unknown | draft-comment | fn | indextermref | indexterm | required-cleanup)*');
  is_deeply $d->print("p"), <<END;
p
    State  Final  Symbol            Target  Final
 1      0      1  PCDATA                 0      1
 2                abbreviated-form       0      1
 3                apiname                0      1
 4                b                      0      1
 5                boolean                0      1
 6                cite                   0      1
 7                cmdname                0      1
 8                codeblock              0      1
 9                codeph                 0      1
10                data                   0      1
11                data-about             0      1
12                div                    0      1
13                dl                     0      1
14                draft-comment          0      1
15                equation-block         0      1
16                equation-figure        0      1
17                equation-inline        0      1
18                fig                    0      1
19                filepath               0      1
20                fn                     0      1
21                foreign                0      1
22                hazardstatement        0      1
23                i                      0      1
24                image                  0      1
25                imagemap               0      1
26                indexterm              0      1
27                indextermref           0      1
28                keyword                0      1
29                line-through           0      1
30                lines                  0      1
31                lq                     0      1
32                markupname             0      1
33                mathml-d-foreign       0      1
34                menucascade            0      1
35                msgblock               0      1
36                msgnum                 0      1
37                msgph                  0      1
38                note                   0      1
39                numcharref             0      1
40                object                 0      1
41                ol                     0      1
42                option                 0      1
43                overline               0      1
44                parameterentity        0      1
45                parml                  0      1
46                parmname               0      1
47                ph                     0      1
48                pre                    0      1
49                q                      0      1
50                required-cleanup       0      1
51                screen                 0      1
52                simpletable            0      1
53                sl                     0      1
54                sort-as                0      1
55                state                  0      1
56                sub                    0      1
57                sup                    0      1
58                svg-d-foreign          0      1
59                synph                  0      1
60                syntaxdiagram          0      1
61                systemoutput           0      1
62                table                  0      1
63                term                   0      1
64                text                   0      1
65                textentity             0      1
66                tm                     0      1
67                tt                     0      1
68                u                      0      1
69                uicontrol              0      1
70                ul                     0      1
71                unknown                0      1
72                userinput              0      1
73                varname                0      1
74                wintitle               0      1
75                xmlatt                 0      1
76                xmlelement             0      1
77                xmlnsname              0      1
78                xmlpi                  0      1
79                xref                   0      1
END
 }

if (1)
 {my sub test($@)
   {my ($e, @t) = @_;
    is_deeply printAsRe(fromExpr(@t)), $e;
   };

  my $a   = element("a");
  my $b   = element("b");
  my $sab = sequence($a, $b);

  test q(a*),                   zeroOrMore($a);
  test q(a+),                    oneOrMore($a);
  test q(a+),   $a,             zeroOrMore($a);
  test q(a a+), $a,              oneOrMore($a);
  test q(a*),   zeroOrMore($a), zeroOrMore($a);
  test q(a+),   zeroOrMore($a),  oneOrMore($a);
  test q(a+),    oneOrMore($a), zeroOrMore($a);
  test q(a a+),  oneOrMore($a),  oneOrMore($a);
 }

if (0) # !!!!
 {say STDERR fromExpr(zeroOrMore("a", "b"))->print;
  is_deeply printAsRe(fromExpr(zeroOrMore("a", "b"))), '';
#  is_deeply printAsRe(fromExpr( oneOrMore($a, $b))), '';
 }

ok  subArray([qw(a b c d e)], []);
ok  subArray([qw(a b c d e)], [qw(a)]);
ok  subArray([qw(a b c d e)], [qw(b)]);
ok  subArray([qw(a b c d e)], [qw(e)]);
ok  subArray([qw(a b c d e)], [qw(b d)]);
ok  subArray([qw(a b c d e)], [qw(a b c d e)]);
ok  subArray([qw(a a c)],     [qw(a c)]);
ok  subArray([qw(b b c d)],   [qw(b c d)]);
ok  subArray([qw(b b c d)],   [qw(b b d)]);
ok !subArray([qw(b b c d)],   [qw(b d b)]);
ok !subArray([qw(b b c d)],   [qw(b b b d)]);

if (1)
 {my $dfa = fromExpr(zeroOrMore("a"), "b");

  ok !$dfa->parser->accepts(qw());
  ok !$dfa->parser->accepts(qw(a));
  ok  $dfa->parser->accepts(qw(b));
  ok  $dfa->parser->accepts(qw(a b));
  ok  $dfa->parser->accepts(qw(a a b));
  ok !$dfa->parser->accepts(qw(b a));
  ok !$dfa->parser->accepts(qw(b b));

  is_deeply shortPaths($dfa), {b => ["b"]};
  is_deeply longPaths ($dfa), { "a b" => ["a", "b"], "b" => ["b"] };
 }

if (1)
 {my $dfa = fromExpr
   (choice
     (oneOrMore("a"),
      oneOrMore("b"),
     ),
   );

  ok !$dfa->parser->accepts(qw());
  ok  $dfa->parser->accepts(qw(a));
  ok  $dfa->parser->accepts(qw(b));
  ok  $dfa->parser->accepts(qw(a a));
  ok !$dfa->parser->accepts(qw(a b));
  ok !$dfa->parser->accepts(qw(b a));
  ok  $dfa->parser->accepts(qw(b b));

  is_deeply shortPaths($dfa), {a => ["a"],                      b => ["b"]};
  is_deeply longPaths ($dfa), {a => ["a"], "a a" => ["a", "a"], b => ["b"], "b b" => ["b", "b"] };
 }

if (1)
 {my $dfa = fromExpr
   (choice
     (oneOrMore("a"),
      oneOrMore("b"),
     ),
    "c"
   );

  ok !$dfa->parser->accepts(qw());
  ok !$dfa->parser->accepts(qw(a));
  ok !$dfa->parser->accepts(qw(b));
  ok  $dfa->parser->accepts(qw(a c));
  ok  $dfa->parser->accepts(qw(b c));
  ok  $dfa->parser->accepts(qw(a a c));
  ok !$dfa->parser->accepts(qw(a b c));
  ok !$dfa->parser->accepts(qw(b a c));
  ok  $dfa->parser->accepts(qw(b b c));

  is_deeply shortPaths    ($dfa), { "a c"   => ["a", "c"], "b c" => ["b", "c"] };
  is_deeply longPaths($dfa),
 {"a a c" => ["a", "a", "c"],
  "a c"   => ["a", "c"],
  "b b c" => ["b", "b", "c"],
  "b c"   => ["b", "c"]};
 }

if (1)                                                                          #TshortPaths #TlongPaths
 {my $dfa = fromExpr
   (zeroOrMore("a"),
     oneOrMore("b"),
      optional("c"),
               "d"
   );

  ok !$dfa->parser->accepts(qw());
  ok !$dfa->parser->accepts(qw(a));
  ok !$dfa->parser->accepts(qw(b));
  ok !$dfa->parser->accepts(qw(c));
  ok !$dfa->parser->accepts(qw(d));
  ok  $dfa->parser->accepts(qw(b c d));
  ok  $dfa->parser->accepts(qw(b d));
  ok !$dfa->parser->accepts(qw(b a));
  ok  $dfa->parser->accepts(qw(b b d));

  is_deeply shortPaths    ($dfa), { "b c d" => ["b", "c", "d"], "b d" => ["b", "d"] };
  is_deeply longPaths($dfa),
 {"a b b c d" => ["a", "b", "b", "c", "d"],
  "a b b d"   => ["a", "b", "b", "d"],
  "a b c d"   => ["a" .. "d"],
  "a b d"     => ["a", "b", "d"],
  "b b c d"   => ["b", "b", "c", "d"],
  "b b d"     => ["b", "b", "d"],
  "b c d"     => ["b", "c", "d"],
  "b d"       => ["b", "d"]};
 }


if (1)
 {my $dfa = fromExpr
   (choice
     (zeroOrMore("a"),
       oneOrMore("b"),
        optional("c"),
                 "d"
     ),
   );

  ok  $dfa->parser->accepts(qw());
  ok  $dfa->parser->accepts(qw(a));
  ok  $dfa->parser->accepts(qw(b));
  ok  $dfa->parser->accepts(qw(c));
  ok  $dfa->parser->accepts(qw(d));
  ok !$dfa->parser->accepts(qw(a b));
  ok !$dfa->parser->accepts(qw(a c));
  ok !$dfa->parser->accepts(qw(a d));

  is_deeply shortPaths($dfa),  { "" => [], "a" => ["a"], "b" => ["b"], "c" => ["c"], "d" => ["d"] };
  is_deeply longPaths ($dfa),
 {""    => [],
  "a"   => ["a"],
  "a a" => ["a", "a"],
  "b"   => ["b"],
  "b b" => ["b", "b"],
  "c"   => ["c"],
  "d"   => ["d"]};
 }

if (1)
 {my $dfa = fromExpr
   (choice
     (sequence(qw(a b c)),
      sequence(qw(A B C)),
     ),
   );

  ok  $dfa->parser->accepts(qw(a b c));
  ok !$dfa->parser->accepts(qw(a b));
  ok !$dfa->parser->accepts(qw(a c));
  ok  $dfa->parser->accepts(qw(A B C));
  ok !$dfa->parser->accepts(qw(A B));
  ok !$dfa->parser->accepts(qw(A C));
  ok !$dfa->parser->accepts(qw(a B C));
  ok !$dfa->parser->accepts(qw(A b C));
  ok !$dfa->parser->accepts(qw(A B c));

  is_deeply shortPaths    ($dfa), {"a b c" => ["a", "b", "c"], "A B C" => ["A", "B", "C"]};
  is_deeply longPaths($dfa), {"a b c" => ["a", "b", "c"], "A B C" => ["A", "B", "C"]};
 }

if (1)
 {my $dfa = fromExpr
   (choice
     (sequence(element("a"), element("b"), element("c")),
      sequence(element("A"), zeroOrMore(element("B")), element("C")),
     ),
   );

  ok  $dfa->parser->accepts(qw(a b c));
  ok !$dfa->parser->accepts(qw(a b));
  ok !$dfa->parser->accepts(qw(a c));
  ok !$dfa->parser->accepts(qw(A B));
  ok  $dfa->parser->accepts(qw(A C));
  ok  $dfa->parser->accepts(qw(A B C));
  ok  $dfa->parser->accepts(qw(A B B C));
  ok !$dfa->parser->accepts(qw(a B C));
  ok !$dfa->parser->accepts(qw(A b C));
  ok !$dfa->parser->accepts(qw(A B c));

  is_deeply shortPaths    ($dfa), {"a b c" => ["a", "b", "c"], "A C"   => ["A", "C"]};
  is_deeply longPaths($dfa),
 {"a b c" => ["a", "b", "c"],
  "A B C" => ["A", "B", "C"],
  "A C"   => ["A", "C"]};
 }

if (1)
 {my $d = fromExpr choice zeroOrMore("a"), oneOrMore("b");

  ok  $d->parser->accepts(qw());
  ok  $d->parser->accepts(qw(a));
  ok  $d->parser->accepts(qw(b));
  ok  $d->parser->accepts(qw(a a));
  ok !$d->parser->accepts(qw(a b));
  ok !$d->parser->accepts(qw(b a));
  ok  $d->parser->accepts(qw(b b));
 }

if (1)
 {my $d = fromExpr oneOrMore choice "a", "b";

  ok !$d->parser->accepts(qw());
  ok  $d->parser->accepts(qw(a));
  ok  $d->parser->accepts(qw(b));
  ok  $d->parser->accepts(qw(a a));
  ok  $d->parser->accepts(qw(a b));
  ok  $d->parser->accepts(qw(b a));
  ok  $d->parser->accepts(qw(b b));
 }

if (1)
 {my $dfa = fromExpr
   (choice(sequence(qw(a)), sequence(qw(a b)), sequence(qw(a b c)))
   );

  is_deeply shortPaths ($dfa), { "a" => ["a"], "a b" => ["a", "b"], "a b c" => ["a", "b", "c"] };
  is_deeply longPaths  ($dfa), { "a" => ["a"], "a b" => ["a", "b"], "a b c" => ["a", "b", "c"] };
 }

if (1)
 {my $d = fromExpr choice zeroOrMore("a"), oneOrMore("b");

  is_deeply $d->print("a*|b+"), <<END;
a*|b+
   State  Final  Symbol  Target  Final
1      0      1  a            1      1
2                b            2      1
3      1      1  a            1      1
4      2      1  b            2      1
END

  is_deeply $d->loops, { 1 => [["a"]], 2 => [["b"]] };
 }

if (1)                                                                          #Tloops
 {my $d = fromExpr choice
    oneOrMore "a",
      oneOrMore "b",
        oneOrMore "c",
          oneOrMore "d";

  is_deeply $d->print("(a(b(c(d)+)+)+)+"), <<END;
(a(b(c(d)+)+)+)+
   State  Final  Symbol  Target  Final
1      0         a            3
2      1         d            2      1
3      2      1  a            3
4                b            4
5                c            1
6                d            2      1
7      3         b            4
8      4         c            1
END

  ok !$d->parser->accepts(qw());
  ok !$d->parser->accepts(qw(a b c));
  ok  $d->parser->accepts(qw(a b c d));
  ok  $d->parser->accepts(qw(a b c d b c d d));
  ok !$d->parser->accepts(qw(a b c b d c d d));
  ok !$d->parser->accepts(qw(a b c d a));

  is_deeply $d->loops, {
  1 => [["d", "a", "b", "c"], ["d", "b", "c"], ["d", "c"]],
  2 => [["a" .. "d"],         ["b", "c", "d"], ["c", "d"], ["d"]],
  3 => [["b", "c", "d", "a"]],
  4 => [["c", "d", "a", "b"], ["c", "d", "b"]]};

  is_deeply shortPaths($d), {"a b c d" => ["a" .. "d"]};
  is_deeply longPaths ($d), { "a b c d" => ["a" .. "d"], "a b c d d" => ["a" .. "d", "d"] };

  #say STDERR $d->printAsExpr;
 }

if (1)                                                                          #TprintExpr
 {my $d = fromExpr choice(
    sequence(
      sequence(
        element(q(a)), zeroOrMore(sequence(element(q(b)), element(q(c)), element(q(d)), element(q(a)))),
        element(q(b)), zeroOrMore(sequence(element(q(c)), element(q(d)), element(q(b)))),
        element(q(c)), zeroOrMore(sequence(element(q(d)), element(q(c)))),
        oneOrMore(element(q(d))))),
    sequence(
      sequence(
        element(q(a)), zeroOrMore(sequence(element(q(b)), element(q(c)), element(q(d)),   element(q(a)))),
        element(q(b)), zeroOrMore(sequence(element(q(c)), element(q(d)), element(q(b)))),
        element(q(c)), zeroOrMore(sequence(element(q(d)), element(q(c)))),
        oneOrMore(element(q(d))))));

  is_deeply $d->print("(a(b(c(d)+)+)+)+"), <<END;
(a(b(c(d)+)+)+)+
    State  Final  Symbol  Target  Final
 1      0         a            7
 2      1         c            5
 3      2         d            3      1
 4      3      1  c            2
 5                d            4      1
 6      4      1  d            4      1
 7      5         d            6      1
 8      6      1  a            7
 9                b            8
10                c            2
11                d            4      1
12      7         b            1
13      8         c            9
14      9         d           10      1
15     10      1  b            8
16                c            2
17                d            4      1
END

  ok !$d->parser->accepts(qw());
  ok !$d->parser->accepts(qw(a b c));
  ok  $d->parser->accepts(qw(a b c d));
  ok  $d->parser->accepts(qw(a b c d b c d d));
  ok !$d->parser->accepts(qw(a b c b d c d d));
  ok !$d->parser->accepts(qw(a b c d a));

  is_deeply $d->loops,
 {1  => [["c", "d", "a", "b"]],
  2  => [["d", "c"]],
  3  => [["c", "d"]],
  4  => [["d"]],
  5  => [["d", "a", "b", "c"]],
  6  => [["a" .. "d"]],
  7  => [["b", "c", "d", "a"]],
  8  => [["c", "d", "b"]],
  9  => [["d", "b", "c"]],
  10 => [["b", "c", "d"]],
};
 }

if (1)                                                                          #TparseDtdElementAST
 {is_deeply unbless(parseDtdElementAST(q(a, (b | c)*, d))),
   ["sequence",
     ["sequence",
        ["element", "a"],
        ["zeroOrMore", ["choice", ["element", "b"], ["element", "c"]]],
     ],
     ["element", "d"],
   ];
 }

if (1)
 {my $d = fromExpr zeroOrMore("a"), oneOrMore("a");
is_deeply $d->print, <<END;
   State  Final  Symbol  Target  Final
1      0         a            1      1
2      1      1  a            1      1
END
  is_deeply $d->univalent, { a => 1 };
 }

if (1)
 {my $d = fromExpr oneOrMore("a", oneOrMore("b"), oneOrMore("c"), optional("d"));
is_deeply $d->print, <<END;
   State  Final  Symbol  Target  Final
1      0         a            3
2      1      1  a            3
3                c            1      1
4                d            2      1
5      2      1  a            3
6      3         b            4
7      4         b            4
8                c            1      1
END

  is_deeply $d->univalent, { a => 3, b => 4, c => 1, d => 2 };
 }

if (1)
 {my $d = fromExpr oneOrMore("a", oneOrMore("b"), oneOrMore("c"), optional("a"));
is_deeply $d->print, <<END;
   State  Final  Symbol  Target  Final
1      0         a            3
2      1      1  a            2      1
3                c            1      1
4      2      1  a            3
5                b            4
6      3         b            4
7      4         b            4
8                c            1      1
END

  ok !$d->univalent;
 }

if (1)
 {my $d = fromExpr oneOrMore("a"), oneOrMore("a");
is_deeply $d->print, <<END;
   State  Final  Symbol  Target  Final
1      0         a            1
2      1         a            2      1
3      2      1  a            2      1
END
  ok !$d->univalent;
 }

latestTest:

if (1)
 {my $d = fromExpr oneOrMore(qw(a b c));
is_deeply $d->print, <<END;
   State  Final  Symbol  Target  Final
1      0         a            2
2      1      1  a            2
3      2         b            3
4      3         c            1      1
END

  my @t;

  ok $d->univalent;
  ok $d->parser(sub
   {my ($p, $s, $t) = @_;
    push @t, [$p->state, $s, $t]
   })
   ->accepts(qw(a b c a b c));

  is_deeply \@t, [
  [0, "a", 2],
  [2, "b", 3],
  [3, "c", 1],
  [1, "a", 2],
  [2, "b", 3],
  [3, "c", 1],
];
 }

done_testing;

if ($localTest)
 {say "DD finished in ", (time() - $startTime), " seconds";
 }

#   owf(q(/home/phil/z/z/z/zzz.txt), $dfa->dumpAsJson);
