#!/usr/bin/perl -I/home/phil/perl/cpan/DataNFA/lib/
#-------------------------------------------------------------------------------
# Deterministic finite state parser from a regular expression
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2018-2019
#-------------------------------------------------------------------------------
# podDocumentation
package Data::DFA;
our $VERSION = "20191030";
require v5.26;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::NFA;
use Data::Table::Text qw(:all);
use utf8;

#  dfa: {state=>state name, transitions=>{symbol=>state}, final state=>reduction sub, pumps=>[[pumping lemmas]]}

#D1 Construct regular expression                                                # Construct a regular expression that defines the language to be parsed using the following combining operations which can all be imported:

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

sub newDFA                                                                      #P Create a new DFA
 {genHash(q(Data::DFA));                                                        # DFA State
 }

sub newState(%)                                                                 #P Create a new DFA state
 {my (%options) = @_;                                                           # DFA state as hash

  my $r = genHash(q(Data::DFA::State),                                          # DFA State
    state       => undef,                                                       # Name of the state - the join of the NFA keys
    nfaStates   => {},                                                          # Hash whose keys are the NFA states that contributed to this super state
    transitions => {},                                                          # Transitions from this state
    final       => undef,                                                       # Whether this state is final
    pump        => [],                                                          # Pumping lemmas for this state
    sequence    => [],                                                          # Sequence of states to final state minus pumped states
    return      => undef,                                                       # Return state
   );

  %$r = (%$r, %options);

  $r
 }

sub fromNfa($)                                                                  #P Create a DFA from an NFA.
 {my ($nfa) = @_;                                                               # Nfa

  my $dfa       = newDFA;                                                       # A DFA is a hash of states

  $$dfa{0}      = newState(                                                     # Start state
    state       => 0,                                                           # Name of the state - the join of the NFA keys
    nfaStates   => {0=>1},                                                      # Hash whose keys are the NFA states that contributed to this super state
    final       => $nfa->isFinal(0),                                            # Whether this state is final
   );

  $dfa->superStates(0, $nfa);                                                   # Create DFA superstates
  my $cfa = $dfa->compress;                                                     # Rename states so that they occupy less space and remove NFA states as no longer needed
  return $cfa->removeDuplicatedStates;                                          # Compressed DFA
  $cfa
 }

sub fromExpr(@)                                                                 #S Create a DFA from a regular expression.
 {my (@expr) = @_;                                                              # Expression
  fromNfa(Data::NFA::fromExpr(@expr))
 }

sub finalState($$)                                                              #P Check whether any of the specified states in the L<NFA> are final
 {my ($nfa, $reach) = @_;                                                       # NFA, hash of states in the NFA
  for my $state(sort keys %$reach)
   {my $f = $nfa->isFinal($state);
    return $f if $f;
   }
  undef
 }

sub superState($$$$$)                                                           #P Create super states from existing superstate
 {my ($dfa, $superStateName, $nfa, $symbols, $nfaSymbolTransitions) = @_;       # DFA, start state in DFA, NFA we are converting, symbols in the NFA we are converting, states reachable from each state by symbol
  my $superState  = $$dfa{$superStateName};
  my $nfaStates   = $superState->nfaStates;

  my @created;                                                                  # New super states created
  for my $symbol(@$symbols)                                                     # Each symbol
   {my $reach = {};                                                             # States in NFS reachable from start state in dfa
    for my $nfaState(sort keys %$nfaStates)                                     # Each NFA state in the dfa start state
     {if (my $r = $$nfaSymbolTransitions{$nfaState}{$symbol})                   # States in the NFA reachable on the symbol
       {$$reach{$_}++ for @$r;                                                  # Accumulate NFA reachable NFA states
       }
     }
    if (keys %$reach)                                                           # Current symbol takes us somewhere
     {my $newSuperStateName = join ' ', sort keys %$reach;                      # Name of the super state reached from the start state via the current symbol
      if (!$$dfa{$newSuperStateName})                                           # Super state does not exists so create it
       {my $newState = $$dfa{$newSuperStateName} = newState
         (nfaStates   => $reach,
          transitions => {},
          final       => finalState($nfa, $reach),
         );
        push @created, $newSuperStateName;                                      # Find all its transitions
       }
      $$dfa{$superStateName}->transitions->{$symbol} = $newSuperStateName;
     }
   }
  @created
 }

sub superStates($$$)                                                            #P Create super states from existing superstate
 {my ($dfa, $SuperStateName, $nfa) = @_;                                        # DFA, start state in DFA, NFA we are tracking
  my $symbols = [$nfa->symbols];                                                # Symbols in nfa
  my $nfaSymbolTransitions = $nfa->allTransitions;                              # Precompute transitions in the NFA
  my @fix = ($SuperStateName);
  while(@fix)                                                                   # Create each superstate as the set of all nfa states we could be in after each transition on a symbol
   {push @fix, superState($dfa, pop @fix, $nfa, $symbols,$nfaSymbolTransitions);
   }
 }

sub transitionOnSymbol($$$)                                                     #P The super state reached by transition on a symbol from a specified state
 {my ($dfa, $superStateName, $symbol) = @_;                                     # DFA, start state in DFA, symbol
  my $superState  = $$dfa{$superStateName};
  my $transitions = $superState->transitions;

  $$transitions{$symbol}
 }

sub compress($)                                                                 # Compress the L<DFA> by removing duplicate states and deleting no longer needed L<NFA> states
 {my ($dfa) = @_;                                                               # DFA
  my %rename;
  my $cfa = newDFA;

  for my $superStateName(sort keys %$dfa)                                       # Each state
   {$rename{$superStateName} = scalar keys %rename;                             # Rename state
   }

  for my $superStateName(sort keys %$dfa)                                       # Each state
   {my $sourceState = $rename{$superStateName};
    my $s = $$cfa{$sourceState} = newState;
    my $superState  = $$dfa{$superStateName};

    my $transitions = $superState->transitions;
    my $final       = $superState->final;

    for my $symbol(sort keys %$transitions)                                     # Rename the target of every transition
     {$s->transitions->{$symbol} = $rename{$$transitions{$symbol}};
     }

    $s->final = $final;
   }

  $cfa
 }

sub print($$;$)                                                                 # Print DFA to a string and optionally to STDERR or STDOUT
 {my ($dfa, $title, $print) = @_;                                               # DFA, title, 1 - STDOUT or 2 - STDERR

  my @out;
  for my $superStateName(sort keys %$dfa)                                       # Each state
   {my $superState  = $$dfa{$superStateName};
    my $transitions = $superState->transitions;
    my $Final       = $superState->final;

    my @s = sort keys %$transitions;
    if (@s > 0)
     {my $s = $s[0];
      my $S = $dfa->transitionOnSymbol($superStateName, $s);
      my $final = $$dfa{$S}->final || 0;
      push @out, [$superStateName, $Final, $s, $$transitions{$s}, $final];
      for(1..$#s)
       {my $s = $s[$_];
        my $S = $dfa->transitionOnSymbol($superStateName, $s);
        my $final = $$dfa{$S}->final || 0;
        push @out, ['', '', $s, $$transitions{$s}, $final];
       }
     }
   }

  if (@out)
   {my $s = "$title\n".formatTable([@out], [qw(State Final Symbol Target Final)])."\n";
    say STDOUT $s if $print and $print == 1;
    say STDERR $s if $print and $print == 2;
    $s =~ s(\s*\Z) ()gs;
    return "$s\n";
   }

  "$title: No states in Dfa";
 }

sub symbols($)                                                                  # Return an array of all the symbols accepted by the DFA
 {my ($dfa) = @_;                                                               # DFA
  my %symbols;
  for my $superStateName(keys %$dfa)                                            # Each state
   {my $superState  = $$dfa{$superStateName};
    my $transitions = $superState->transitions;

    $symbols{$_}++ for keys %$transitions;                                      # Symbol for each transition
   }

  sort keys %symbols;
 }

sub parser($)                                                                   # Create a parser from a deterministic finite state automaton constructed from a regular expression.
 {my ($dfa) = @_;                                                               # Deterministic finite state automaton generated from an expression
  return genHash(q(Data::DFA::Parser),
    dfa       => $dfa,
    state     => 0,
    processed => []
   );
 }

sub dumpAsJson($)                                                               # Create a JSON representation {transitions=>{symbol=>state}, finalStates=>{state=>1}}
 {my ($dfa) = @_;                                                               # Deterministic finite state automaton generated from an expression
  my $jfa;
  for my $state(sort keys %$dfa)                                                # Each state
   {my $transitions = $$dfa{$state}->transitions;                               # Transitions
    for my $t(sort keys %$transitions)
     {$$jfa{transitions}{$state}{$t} = $$transitions{$t};                       # Clone transitions
     }
    $$jfa{finalStates}{$state} = $$dfa{$state}->final ? 1 : 0;                  # Final states
   }
  encodeJson($jfa);
 }

sub removeDuplicatedStates($)                                                   #P Remove duplicated states in a DFA
 {my ($dfa)   = @_;                                                             # Deterministic finite state automaton generated from an expression

  for(1..10)                                                                    # Keep squeezing out duplicates
   {my %d;
    for my $state(sort keys %$dfa)                                              # Each state
     {my $c = dump($$dfa{$state});                                              # State content
      push $d{$c}->@*, $state;
     }

    my %m;                                                                      # Map deleted duplicated states back to undeleted original
    for my $d(sort keys %d)                                                     # Delete unitary states
     {my ($b, @d) = $d{$d}->@*;
      if (@d)
       {for my $r(@d)                                                           # Map duplicated states to base unduplicated state
         {$m{$r} = $b;                                                          # Map
          delete $$dfa{$r};                                                     # Remove duplicated state from DFA
         }
       }
     }

    if (keys %m)
     {for my $state(sort keys %$dfa)                                            # Each state

       {my $transitions = $$dfa{$state}->transitions;
        my $final       = $$dfa{$state}->final;

        for my $symbol(keys %$transitions)
         {my $state = $$transitions{$symbol};
          if (defined $m{$state})
           {$$transitions{$symbol} = $m{$state};
           }
         }
       }
     }
    else {last};
   }

  compress($dfa);                                                               # Renumber states
 }

# Trace from the start node through to each node remembering the long path.  If
# we reach a node we have already visited then add a pumping lemma to it as the
# long path minus the short path used to reach the node the first time.
#
# Trace from start node to final states without revisiting nodes. Write the
# expressions so obtained as a choice of sequences with pumping lemmas.

sub printAsExpr2($%)                                                            #P Print a DFA B<$dfa_> in expression form
 {my ($dfa, %options) = @_;                                                     # Dfa, options

  checkKeys(\%options,                                                          # Check options
   {element    => q(Format a single element),
    choice     => q(Format a choice of expressions),
    sequence   => q(Format a sequence of expressions),
    zeroOrMore => q(Format zero or more instances of a single expression),
   });

  my ($fe, $fc, $fs, $fz) = @options{qw(element choice sequence zeroOrMore)};

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
    if (!defined $visited{$state})                                              # States not yet visited
     {my $transitions = $$dfa{$state}->transitions;                             # Transitions hash
      push $$dfa{$state}->sequence->@*, [@path] if @path and $$dfa{$state}->final;
      $visited{$state} = [@path];
      for my $symbol(sort keys %$transitions)                                   # Visit each adjacent states
       {my $s = $$transitions{$symbol};                                         # Adjacent state
        &$visit($$transitions{$symbol}, @path, [$state, $symbol, $s]);          # Visit adjacent state
       }
      delete $visited{$state};
     }
   };

  &$visit(0);                                                                   # Find unpumped paths

  my @choices;                                                                  # Construct expression as choices amongst pumped paths
  for my $state(sort keys %$dfa)                                                # Each state
   {if ($$dfa{$state}->final)                                                   # Final state
     {my $paths = $$dfa{$state}->sequence;                                      # Path to this final state
      for my $path(@$paths)                                                     # Each path to this state
       {my @seq;
        for my $step(@$path)                                                    # Current state, sequence to get here
         {my ($from, $symbol, $to) = @$step;                                    # States not yet visited
          push @seq, &$fe($symbol);                                             # Element
          if (my $pump = $$dfa{$to}->pump)                                      # Add pumping lemmas
           {my @c;
            for my $p(@$pump)                                                   # Add each pumping lemma for this state
             {if (@$p == 1)
               {push @c, map {&$fe($_)} @$p;
               }
              else
               {push @c, &$fs(join ', ', map {&$fe($_)} @$p);
               }
             }
            if (@c == 1)                                                        # Combine pumping lemmas
             {my ($c) = @c;
              push @seq, &$fz($c);
             }
            else
             {if (!@c) {}
              elsif (@c == 1)
               {push @seq, @c;
               }
              else
               {push @seq, &$fz(&$fc(@c));
               }
             }
           }
         }
        push @choices, join ', ', @seq;                                         # Combine choice of sequences from start state
       }
     }
   };

  return $choices[0] if @choices == 1;                                          # No wrapping needed if only one choice
  &$fc(map {&$fs($_)} @choices)
 } # printAsExpr2

sub printAsExpr($)                                                              # Print a B<$dfa> as an expression
 {my ($dfa) = @_;                                                               # DFA

  my %options =                                                                 # Formatting methods
   (element    => sub {my ($e) = @_; qq/element(q($e))/},
    choice     => sub {my $c = join ', ', @_; qq/choice($c)/},
    sequence   => sub {my $s = join ', ', @_; qq/sequence($s)/},
    zeroOrMore => sub {my ($z) = @_; qq/zeroOrMore($z)/},
   );

  printAsExpr2($dfa, %options);                                                 # Create an expression for the DFA
 }

sub printAsRe($)                                                                # Print a B<$dfa> as a regular expression
 {my ($dfa) = @_;                                                               # DFA

  my %options =                                                                 # Formatting methods
   (element    => sub {my ($e) = @_; $e},
    zeroOrMore => sub {my ($z) = @_; qq/$z*/},
    choice     => sub
     {my %c = map {$_=>1} @_;
      my @c = sort keys %c;
      #return $c[0] if @c == 1;
      my $c = join ' | ', @c;
      qq/($c)/
     },
    sequence   => sub
     {#return $_[0] if @_ == 1;
      my $s = join ' | ', @_;
      qq/($s)/
     },
   );

  printAsExpr2($dfa, %options);                                                 # Create an expression for the DFA
 }

sub parseDtdElement($)                                                          # Convert the Dtd Element definition in B<$string>to a DFA
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
      return q(OneOrMore)  if $r eq q(+);
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
   {my ($s) = @_;                                                               # String
    $s =~ s(((\w|-)+))    (element(q($1)))gs;                                   # Word
    $s =~ s(\)\s*([*+?])) (\) ** q($1))gs;
    $s =~ s(\|)           (*)gs;
    $s =~ s(\,)           (+)gs;
    my $r = eval $s;
    say STDERR "$@" if $@;
    $r
   }

  my $r = parse($string);
  Data::DFA::fromExpr($r);
 }

#D1 Parser methods                                                              # Use the DFA to parse a sequence of symbols

sub Data::DFA::Parser::accept($$)                                               # Accept the next symbol drawn from the symbol set if possible by moving to a new state otherwise confessing with a helpful message
 {my ($parser, $symbol) = @_;                                                   # DFA Parser, next symbol to be processed by the finite state automaton
  my $dfa = $parser->dfa;
  my $transitions = $$dfa{$parser->state}->transitions;
  my $nextState = $$transitions{$symbol};
  if (defined $nextState)
   {$parser->state = $nextState;
    push @{$parser->processed}, $symbol;
    return 1;
   }
  else
   {my @next        = sort keys %$transitions;
    my @processed   = @{$parser->processed};
    $parser->{next} = [@next];
    my $next = join ' ', @next;

    push my @m, "Already processed: ". join(' ', @processed);

    if (scalar(@next) > 0)
     {push  @m, "Expected one of  : ". join(' ', @next);
     }
    else
     {push  @m, "Expected nothing more.";
     }

    push    @m, "But found        : ". $symbol, "";

    die join "\n", @m;
   }
 }

sub Data::DFA::Parser::final($)                                                 # Returns whether we are currently in a final state or not
 {my ($parser) = @_;                                                            # DFA Parser
  my $dfa = $parser->dfa;
  my $state = $parser->state;
  return 1 if $$dfa{$state}->final;
  0
 }

sub Data::DFA::Parser::next($)                                                  # Returns an array of symbols that would be accepted in the current state
 {my ($parser) = @_;                                                            # DFA Parser
  my $dfa = $parser->dfa;
  my $state = $parser->state;
  my $transitions = $$dfa{$state}->transitions;
  sort keys %$transitions
 }

sub Data::DFA::Parser::accepts($@)                                              # Confirm that a DFA accepts an array representing a sequence of symbols
 {my ($parser, @symbols) = @_;                                                  # DFA Parser, array of symbols
  for my $symbol(@symbols)                                                      # Parse the symbols
   {eval {$parser->accept($symbol)};                                            # Try to accept a symbol
    return 0 if $@;                                                             # Failed
   }
  $parser->final                                                                # Confirm we are in an end state
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

Data::DFA - Deterministic finite state parser from regular expression

=head1 Synopsis

Create a deterministic finite state parser to recognize sequences of symbols
that match a given regular expression.

To recognize sequences of symbols drawn from B<'a'..'e'> that match
the regular expression: B<a (b|c)+ d? e>:

# Construct a deterministic finite state automaton from the regular expression:

  use Data::DFA qw(:all);
  use Data::Table::Text qw(:all);
  use Test::More qw(no_plan);

  my $dfa = fromExpr
   (element("a"),
    oneOrMore(choice(element("b"), element("c"))),
    optional(element("d")),
    element("e")
   );

  ok  $dfa->parser->accepts(qw(a b e));
  ok !$dfa->parser->accepts(qw(a d));

# Print the symbols used and the transitions table:

  is_deeply ['a'..'e'], [$dfa->symbols];

  ok $dfa->print("Dfa for a(b|c)+d?e :") eq nws <<END;
Dfa for a(b|c)+d?e :
    State        Final  Symbol  Target       Final
1   0                   a       1 3          0
2   1 2 3 4 5 6  0      b       1 2 3 4 5 6  0
3                       c       1 3 4 5 6    0
4                       d       6            0
5                       e       7            1
6   1 3          0      b       1 2 3 4 5 6  0
7                       c       1 3 4 5 6    0
8   1 3 4 5 6    0      b       1 2 3 4 5 6  0
9                       c       1 3 4 5 6    0
10                      d       6            0
11                      e       7            1
12  6            0      e       7            1
END

# Create a parser and use it to parse a sequence of symbols

  my $parser = $dfa->parser;                                                    # New parser

  eval { $parser->accept($_) } for qw(a b a);                                   # Try to parse a b a

# Create a parser and use it to parse a sequence of symbols

  my $parser = $dfa->parser;

  eval { $parser->accept($_) } for qw(a b a);
  my $r = $@;
  ok $r =~ m(Already processed: a b);
  ok $r =~ m(Expected one of  : b c d e);
  ok $r =~ m(But found        : a);

  is_deeply [$parser->next],     [qw(b c d e)];
  is_deeply  $parser->processed, [qw(a b)];
  ok !$parser->final;

To construct and parse regular expressions in the format used by B<!ELEMENT>
definitions in L<DTD>s:

 {my $e = q/element(q(a)), zeroOrMore(choice(element(q(b)), element(q(c)))), element(q(d))/;
  my $d = eval qq/fromExpr($e)/;

  my $E = $d->printAsExpr;
  ok $e eq $E;

  my $R = $d->printAsRe;
  ok $R eq q(a, (b | c)*, d);                                                   # Print as DTD regular expression

  my $D = parseDtdElement($R);                                                  # Parse DTD regular expression
  my $S = $D->printAsExpr;
  ok $e eq $S;
 }

=head1 Description

Deterministic finite state parser from regular expression


Version "20191029".


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Construct regular expression

Construct a regular expression that defines the language to be parsed using the following combining operations which can all be imported:

=head2 element($)

One element.

     Parameter  Description
  1  $label     Transition symbol

B<Example:>


  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (𝗲𝗹𝗲𝗺𝗲𝗻𝘁("a"),
      oneOrMore(choice(𝗲𝗹𝗲𝗺𝗲𝗻𝘁("b"), 𝗲𝗹𝗲𝗺𝗲𝗻𝘁("c"))),
      optional(𝗲𝗹𝗲𝗺𝗲𝗻𝘁("d")),
      𝗲𝗹𝗲𝗺𝗲𝗻𝘁("e")
     );

    ok  $dfa->parser->accepts(qw(a b e));                                         # Accept symbols
    ok !$dfa->parser->accepts(qw(a d));

    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols

    ok $dfa->print("Dfa for a(b|c)+d?e :") eq <<END;                              # Print compressed DFA
  Dfa for a(b|c)+d?e :
     State  Final  Symbol  Target  Final
  1      0         a            2      0
  2      1         b            1      0
  3                c            1      0
  4                d            3      0
  5                e            4      1
  6      2         b            1      0
  7                c            1      0
  8      3         e            4      1
  END
   }

  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (𝗲𝗹𝗲𝗺𝗲𝗻𝘁("a"),
      oneOrMore(choice(𝗲𝗹𝗲𝗺𝗲𝗻𝘁("b"), 𝗲𝗹𝗲𝗺𝗲𝗻𝘁("c"))),
      optional(𝗲𝗹𝗲𝗺𝗲𝗻𝘁("d")),
      𝗲𝗹𝗲𝗺𝗲𝗻𝘁("e")
     );
    my $parser = $dfa->parser;                                                    # New parser

    eval { $parser->accept($_) } for qw(a b a);                                   # Try to parse a b a

    is_deeply [$parser->next],     [qw(b c d e)];                                 # Next acceptable symbol
    is_deeply  $parser->processed, [qw(a b)];                                     # Symbols processed

    ok !$parser->final;                                                           # Not in a final state

    ok $dfa->dumpAsJson eq <<END;                                                 # Dump as json
  {
     "finalStates" : {
        "0" : 0,
        "1" : 0,
        "2" : 0,
        "3" : 0,
        "4" : 1
     },
     "transitions" : {
        "0" : {
           "a" : 2
        },
        "1" : {
           "b" : 1,
           "c" : 1,
           "d" : 3,
           "e" : 4
        },
        "2" : {
           "b" : 1,
           "c" : 1
        },
        "3" : {
           "e" : 4
        }
     }
  }
  END

   }


This is a static method and so should be invoked as:

  Data::DFA::element


=head2 sequence(@)

Sequence of elements.

     Parameter  Description
  1  @elements  Elements

B<Example:>


  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (zeroOrMore(𝘀𝗲𝗾𝘂𝗲𝗻𝗰𝗲('a'..'g')),
      except('d'..'g')
     );

    ok  $dfa->parser->accepts(qw(a b c d e f g a b c d e f g a));                 # Accept symbols
    ok !$dfa->parser->accepts(qw(a b c d e f g a b c d e f g g));                 # Fail to accept symbols

    my $parser = $dfa->parser;
    $parser->accept(qw(a b c d e f g a b c d e f g a));
    ok $parser->final;

    ok $dfa->print(q(Test)) eq <<END;                                             # Print compressed DFA
  Test
     State  Final  Symbol  Target  Final
  1      0         a            1      1
  2                b            2      1
  3                c            2      1
  4      1      1  b            3      0
  5      3         c            4      0
  6      4         d            5      0
  7      5         e            6      0
  8      6         f            7      0
  9      7         g            0      0
  END
   }


This is a static method and so should be invoked as:

  Data::DFA::sequence


=head2 optional(@)

An optional sequence of element.

     Parameter  Description
  1  @element   Elements

B<Example:>


  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),
      oneOrMore(choice(element("b"), element("c"))),
      𝗼𝗽𝘁𝗶𝗼𝗻𝗮𝗹(element("d")),
      element("e")
     );

    ok  $dfa->parser->accepts(qw(a b e));                                         # Accept symbols
    ok !$dfa->parser->accepts(qw(a d));

    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols

    ok $dfa->print("Dfa for a(b|c)+d?e :") eq <<END;                              # Print compressed DFA
  Dfa for a(b|c)+d?e :
     State  Final  Symbol  Target  Final
  1      0         a            2      0
  2      1         b            1      0
  3                c            1      0
  4                d            3      0
  5                e            4      1
  6      2         b            1      0
  7                c            1      0
  8      3         e            4      1
  END
   }

  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),
      oneOrMore(choice(element("b"), element("c"))),
      𝗼𝗽𝘁𝗶𝗼𝗻𝗮𝗹(element("d")),
      element("e")
     );
    my $parser = $dfa->parser;                                                    # New parser

    eval { $parser->accept($_) } for qw(a b a);                                   # Try to parse a b a

    is_deeply [$parser->next],     [qw(b c d e)];                                 # Next acceptable symbol
    is_deeply  $parser->processed, [qw(a b)];                                     # Symbols processed

    ok !$parser->final;                                                           # Not in a final state

    ok $dfa->dumpAsJson eq <<END;                                                 # Dump as json
  {
     "finalStates" : {
        "0" : 0,
        "1" : 0,
        "2" : 0,
        "3" : 0,
        "4" : 1
     },
     "transitions" : {
        "0" : {
           "a" : 2
        },
        "1" : {
           "b" : 1,
           "c" : 1,
           "d" : 3,
           "e" : 4
        },
        "2" : {
           "b" : 1,
           "c" : 1
        },
        "3" : {
           "e" : 4
        }
     }
  }
  END

   }


This is a static method and so should be invoked as:

  Data::DFA::optional


=head2 zeroOrMore(@)

Zero or more repetitions of a sequence of elements.

     Parameter  Description
  1  @element   Elements

B<Example:>


  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (𝘇𝗲𝗿𝗼𝗢𝗿𝗠𝗼𝗿𝗲(sequence('a'..'g')),
      except('d'..'g')
     );

    ok  $dfa->parser->accepts(qw(a b c d e f g a b c d e f g a));                 # Accept symbols
    ok !$dfa->parser->accepts(qw(a b c d e f g a b c d e f g g));                 # Fail to accept symbols

    my $parser = $dfa->parser;
    $parser->accept(qw(a b c d e f g a b c d e f g a));
    ok $parser->final;

    ok $dfa->print(q(Test)) eq <<END;                                             # Print compressed DFA
  Test
     State  Final  Symbol  Target  Final
  1      0         a            1      1
  2                b            2      1
  3                c            2      1
  4      1      1  b            3      0
  5      3         c            4      0
  6      4         d            5      0
  7      5         e            6      0
  8      6         f            7      0
  9      7         g            0      0
  END
   }


This is a static method and so should be invoked as:

  Data::DFA::zeroOrMore


=head2 oneOrMore(@)

One or more repetitions of a sequence of elements.

     Parameter  Description
  1  @element   Elements

B<Example:>


  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),
      𝗼𝗻𝗲𝗢𝗿𝗠𝗼𝗿𝗲(choice(element("b"), element("c"))),
      optional(element("d")),
      element("e")
     );

    ok  $dfa->parser->accepts(qw(a b e));                                         # Accept symbols
    ok !$dfa->parser->accepts(qw(a d));

    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols

    ok $dfa->print("Dfa for a(b|c)+d?e :") eq <<END;                              # Print compressed DFA
  Dfa for a(b|c)+d?e :
     State  Final  Symbol  Target  Final
  1      0         a            2      0
  2      1         b            1      0
  3                c            1      0
  4                d            3      0
  5                e            4      1
  6      2         b            1      0
  7                c            1      0
  8      3         e            4      1
  END
   }

  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),
      𝗼𝗻𝗲𝗢𝗿𝗠𝗼𝗿𝗲(choice(element("b"), element("c"))),
      optional(element("d")),
      element("e")
     );
    my $parser = $dfa->parser;                                                    # New parser

    eval { $parser->accept($_) } for qw(a b a);                                   # Try to parse a b a

    is_deeply [$parser->next],     [qw(b c d e)];                                 # Next acceptable symbol
    is_deeply  $parser->processed, [qw(a b)];                                     # Symbols processed

    ok !$parser->final;                                                           # Not in a final state

    ok $dfa->dumpAsJson eq <<END;                                                 # Dump as json
  {
     "finalStates" : {
        "0" : 0,
        "1" : 0,
        "2" : 0,
        "3" : 0,
        "4" : 1
     },
     "transitions" : {
        "0" : {
           "a" : 2
        },
        "1" : {
           "b" : 1,
           "c" : 1,
           "d" : 3,
           "e" : 4
        },
        "2" : {
           "b" : 1,
           "c" : 1
        },
        "3" : {
           "e" : 4
        }
     }
  }
  END

   }


This is a static method and so should be invoked as:

  Data::DFA::oneOrMore


=head2 choice(@)

Choice from amongst one or more elements.

     Parameter  Description
  1  @elements  Elements to be chosen from

B<Example:>


  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),
      oneOrMore(𝗰𝗵𝗼𝗶𝗰𝗲(element("b"), element("c"))),
      optional(element("d")),
      element("e")
     );

    ok  $dfa->parser->accepts(qw(a b e));                                         # Accept symbols
    ok !$dfa->parser->accepts(qw(a d));

    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols

    ok $dfa->print("Dfa for a(b|c)+d?e :") eq <<END;                              # Print compressed DFA
  Dfa for a(b|c)+d?e :
     State  Final  Symbol  Target  Final
  1      0         a            2      0
  2      1         b            1      0
  3                c            1      0
  4                d            3      0
  5                e            4      1
  6      2         b            1      0
  7                c            1      0
  8      3         e            4      1
  END
   }

  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),
      oneOrMore(𝗰𝗵𝗼𝗶𝗰𝗲(element("b"), element("c"))),
      optional(element("d")),
      element("e")
     );
    my $parser = $dfa->parser;                                                    # New parser

    eval { $parser->accept($_) } for qw(a b a);                                   # Try to parse a b a

    is_deeply [$parser->next],     [qw(b c d e)];                                 # Next acceptable symbol
    is_deeply  $parser->processed, [qw(a b)];                                     # Symbols processed

    ok !$parser->final;                                                           # Not in a final state

    ok $dfa->dumpAsJson eq <<END;                                                 # Dump as json
  {
     "finalStates" : {
        "0" : 0,
        "1" : 0,
        "2" : 0,
        "3" : 0,
        "4" : 1
     },
     "transitions" : {
        "0" : {
           "a" : 2
        },
        "1" : {
           "b" : 1,
           "c" : 1,
           "d" : 3,
           "e" : 4
        },
        "2" : {
           "b" : 1,
           "c" : 1
        },
        "3" : {
           "e" : 4
        }
     }
  }
  END

   }


This is a static method and so should be invoked as:

  Data::DFA::choice


=head2 except(@)

Choice from amongst all symbols except the ones mentioned

     Parameter  Description
  1  @elements  Elements to be chosen from

B<Example:>


  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (zeroOrMore(sequence('a'..'g')),
      𝗲𝘅𝗰𝗲𝗽𝘁('d'..'g')
     );

    ok  $dfa->parser->accepts(qw(a b c d e f g a b c d e f g a));                 # Accept symbols
    ok !$dfa->parser->accepts(qw(a b c d e f g a b c d e f g g));                 # Fail to accept symbols

    my $parser = $dfa->parser;
    $parser->accept(qw(a b c d e f g a b c d e f g a));
    ok $parser->final;

    ok $dfa->print(q(Test)) eq <<END;                                             # Print compressed DFA
  Test
     State  Final  Symbol  Target  Final
  1      0         a            1      1
  2                b            2      1
  3                c            2      1
  4      1      1  b            3      0
  5      3         c            4      0
  6      4         d            5      0
  7      5         e            6      0
  8      6         f            7      0
  9      7         g            0      0
  END
   }


This is a static method and so should be invoked as:

  Data::DFA::except


=head2 fromExpr(@)

Create a DFA from a regular expression.

     Parameter  Description
  1  @expr      Expression

B<Example:>


  if (1) {
    my $dfa = 𝗳𝗿𝗼𝗺𝗘𝘅𝗽𝗿                                                            # Construct DFA
     (element("a"),
      oneOrMore(choice(element("b"), element("c"))),
      optional(element("d")),
      element("e")
     );

    ok  $dfa->parser->accepts(qw(a b e));                                         # Accept symbols
    ok !$dfa->parser->accepts(qw(a d));

    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols

    ok $dfa->print("Dfa for a(b|c)+d?e :") eq <<END;                              # Print compressed DFA
  Dfa for a(b|c)+d?e :
     State  Final  Symbol  Target  Final
  1      0         a            2      0
  2      1         b            1      0
  3                c            1      0
  4                d            3      0
  5                e            4      1
  6      2         b            1      0
  7                c            1      0
  8      3         e            4      1
  END
   }

  if (1) {
    my $dfa = 𝗳𝗿𝗼𝗺𝗘𝘅𝗽𝗿                                                            # Construct DFA
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

    ok $dfa->dumpAsJson eq <<END;                                                 # Dump as json
  {
     "finalStates" : {
        "0" : 0,
        "1" : 0,
        "2" : 0,
        "3" : 0,
        "4" : 1
     },
     "transitions" : {
        "0" : {
           "a" : 2
        },
        "1" : {
           "b" : 1,
           "c" : 1,
           "d" : 3,
           "e" : 4
        },
        "2" : {
           "b" : 1,
           "c" : 1
        },
        "3" : {
           "e" : 4
        }
     }
  }
  END

   }


This is a static method and so should be invoked as:

  Data::DFA::fromExpr


=head2 compress($)

Compress the L<DFA|https://metacpan.org/pod/Data::DFA> by removing duplicate states and deleting no longer needed L<NFA|https://metacpan.org/pod/Data::NFA> states

     Parameter  Description
  1  $dfa       DFA

B<Example:>


  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (zeroOrMore(sequence('a'..'g')),
      except('d'..'g')
     );

    ok  $dfa->parser->accepts(qw(a b c d e f g a b c d e f g a));                 # Accept symbols
    ok !$dfa->parser->accepts(qw(a b c d e f g a b c d e f g g));                 # Fail to accept symbols

    my $parser = $dfa->parser;
    $parser->accept(qw(a b c d e f g a b c d e f g a));
    ok $parser->final;

    ok $dfa->print(q(Test)) eq <<END;                                             # Print compressed DFA
  Test
     State  Final  Symbol  Target  Final
  1      0         a            1      1
  2                b            2      1
  3                c            2      1
  4      1      1  b            3      0
  5      3         c            4      0
  6      4         d            5      0
  7      5         e            6      0
  8      6         f            7      0
  9      7         g            0      0
  END
   }


=head2 print($$$)

Print DFA to a string and optionally to STDERR or STDOUT

     Parameter  Description
  1  $dfa       DFA
  2  $title     Title
  3  $print     1 - STDOUT or 2 - STDERR

B<Example:>


  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (zeroOrMore(sequence('a'..'g')),
      except('d'..'g')
     );

    ok  $dfa->parser->accepts(qw(a b c d e f g a b c d e f g a));                 # Accept symbols
    ok !$dfa->parser->accepts(qw(a b c d e f g a b c d e f g g));                 # Fail to accept symbols

    my $parser = $dfa->parser;
    $parser->accept(qw(a b c d e f g a b c d e f g a));
    ok $parser->final;

    ok $dfa->𝗽𝗿𝗶𝗻𝘁(q(Test)) eq <<END;                                             # Print compressed DFA
  Test
     State  Final  Symbol  Target  Final
  1      0         a            1      1
  2                b            2      1
  3                c            2      1
  4      1      1  b            3      0
  5      3         c            4      0
  6      4         d            5      0
  7      5         e            6      0
  8      6         f            7      0
  9      7         g            0      0
  END
   }


=head2 symbols($)

Return an array of all the symbols accepted by the DFA

     Parameter  Description
  1  $dfa       DFA

B<Example:>


  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),
      oneOrMore(choice(element("b"), element("c"))),
      optional(element("d")),
      element("e")
     );

    ok  $dfa->parser->accepts(qw(a b e));                                         # Accept 𝘀𝘆𝗺𝗯𝗼𝗹𝘀
    ok !$dfa->parser->accepts(qw(a d));

    is_deeply ['a'..'e'], [$dfa->𝘀𝘆𝗺𝗯𝗼𝗹𝘀];                                        # List 𝘀𝘆𝗺𝗯𝗼𝗹𝘀

    ok $dfa->print("Dfa for a(b|c)+d?e :") eq <<END;                              # Print compressed DFA
  Dfa for a(b|c)+d?e :
     State  Final  Symbol  Target  Final
  1      0         a            2      0
  2      1         b            1      0
  3                c            1      0
  4                d            3      0
  5                e            4      1
  6      2         b            1      0
  7                c            1      0
  8      3         e            4      1
  END
   }


=head2 parser($)

Create a parser from a deterministic finite state automaton constructed from a regular expression.

     Parameter  Description
  1  $dfa       Deterministic finite state automaton generated from an expression

B<Example:>


  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),
      oneOrMore(choice(element("b"), element("c"))),
      optional(element("d")),
      element("e")
     );

    ok  $dfa->𝗽𝗮𝗿𝘀𝗲𝗿->accepts(qw(a b e));                                         # Accept symbols
    ok !$dfa->𝗽𝗮𝗿𝘀𝗲𝗿->accepts(qw(a d));

    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols

    ok $dfa->print("Dfa for a(b|c)+d?e :") eq <<END;                              # Print compressed DFA
  Dfa for a(b|c)+d?e :
     State  Final  Symbol  Target  Final
  1      0         a            2      0
  2      1         b            1      0
  3                c            1      0
  4                d            3      0
  5                e            4      1
  6      2         b            1      0
  7                c            1      0
  8      3         e            4      1
  END
   }

  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),
      oneOrMore(choice(element("b"), element("c"))),
      optional(element("d")),
      element("e")
     );
    my $𝗽𝗮𝗿𝘀𝗲𝗿 = $dfa->𝗽𝗮𝗿𝘀𝗲𝗿;                                                    # New 𝗽𝗮𝗿𝘀𝗲𝗿

    eval { $𝗽𝗮𝗿𝘀𝗲𝗿->accept($_) } for qw(a b a);                                   # Try to parse a b a

    is_deeply [$𝗽𝗮𝗿𝘀𝗲𝗿->next],     [qw(b c d e)];                                 # Next acceptable symbol
    is_deeply  $𝗽𝗮𝗿𝘀𝗲𝗿->processed, [qw(a b)];                                     # Symbols processed

    ok !$𝗽𝗮𝗿𝘀𝗲𝗿->final;                                                           # Not in a final state

    ok $dfa->dumpAsJson eq <<END;                                                 # Dump as json
  {
     "finalStates" : {
        "0" : 0,
        "1" : 0,
        "2" : 0,
        "3" : 0,
        "4" : 1
     },
     "transitions" : {
        "0" : {
           "a" : 2
        },
        "1" : {
           "b" : 1,
           "c" : 1,
           "d" : 3,
           "e" : 4
        },
        "2" : {
           "b" : 1,
           "c" : 1
        },
        "3" : {
           "e" : 4
        }
     }
  }
  END

   }


=head2 dumpAsJson($)

Create a JSON representation {transitions=>{symbol=>state}, finalStates=>{state=>1}}

     Parameter  Description
  1  $dfa       Deterministic finite state automaton generated from an expression

B<Example:>


  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),
      oneOrMore(choice(element("b"), element("c"))),
      optional(element("d")),
      element("e")
     );

    ok  $dfa->parser->accepts(qw(a b e));                                         # Accept symbols
    ok !$dfa->parser->accepts(qw(a d));

    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols

    ok $dfa->print("Dfa for a(b|c)+d?e :") eq <<END;                              # Print compressed DFA
  Dfa for a(b|c)+d?e :
     State  Final  Symbol  Target  Final
  1      0         a            2      0
  2      1         b            1      0
  3                c            1      0
  4                d            3      0
  5                e            4      1
  6      2         b            1      0
  7                c            1      0
  8      3         e            4      1
  END
   }


=head2 printAsExpr($)

Print a B<$dfa> as an expression

     Parameter  Description
  1  $dfa       DFA

B<Example:>


  if (1)
   {my $e = q/element(q(a)), zeroOrMore(choice(element(q(b)), element(q(c)))), element(q(d))/;
    my $d = eval qq/fromExpr($e)/;
    confess $@ if $@;

    my $E = $d->𝗽𝗿𝗶𝗻𝘁𝗔𝘀𝗘𝘅𝗽𝗿;
    ok $e eq $E;

    my $R = $d->printAsRe;
    ok $R eq q(((a, (b | c)*, d)));

    my $D = parseDtdElement($R);
    my $S = $D->𝗽𝗿𝗶𝗻𝘁𝗔𝘀𝗘𝘅𝗽𝗿;
    ok $e eq $S;
   }


=head2 printAsRe($)

Print a B<$dfa> as a regular expression

     Parameter  Description
  1  $dfa       DFA

B<Example:>


  if (1)
   {my $e = q/element(q(a)), zeroOrMore(choice(element(q(b)), element(q(c)))), element(q(d))/;
    my $d = eval qq/fromExpr($e)/;
    confess $@ if $@;

    my $E = $d->printAsExpr;
    ok $e eq $E;

    my $R = $d->𝗽𝗿𝗶𝗻𝘁𝗔𝘀𝗥𝗲;
    ok $R eq q(((a, (b | c)*, d)));

    my $D = parseDtdElement($R);
    my $S = $D->printAsExpr;
    ok $e eq $S;
   }


=head2 parseDtdElement($)

Convert the Dtd Element definition in B<$string>to a DFA

     Parameter  Description
  1  $string    String representation of DTD element expression

B<Example:>


  if (1)
   {my $e = q/element(q(a)), zeroOrMore(choice(element(q(b)), element(q(c)))), element(q(d))/;
    my $d = eval qq/fromExpr($e)/;
    confess $@ if $@;

    my $E = $d->printAsExpr;
    ok $e eq $E;

    my $R = $d->printAsRe;
    ok $R eq q(((a, (b | c)*, d)));

    my $D = 𝗽𝗮𝗿𝘀𝗲𝗗𝘁𝗱𝗘𝗹𝗲𝗺𝗲𝗻𝘁($R);
    my $S = $D->printAsExpr;
    ok $e eq $S;
   }


=head1 Parser methods

Use the DFA to parse a sequence of symbols

=head2 Data::DFA::Parser::accept($$)

Accept the next symbol drawn from the symbol set if possible by moving to a new state otherwise confessing with a helpful message

     Parameter  Description
  1  $parser    DFA Parser
  2  $symbol    Next symbol to be processed by the finite state automaton

B<Example:>


  if (1) {
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

    ok $dfa->dumpAsJson eq <<END;                                                 # Dump as json
  {
     "finalStates" : {
        "0" : 0,
        "1" : 0,
        "2" : 0,
        "3" : 0,
        "4" : 1
     },
     "transitions" : {
        "0" : {
           "a" : 2
        },
        "1" : {
           "b" : 1,
           "c" : 1,
           "d" : 3,
           "e" : 4
        },
        "2" : {
           "b" : 1,
           "c" : 1
        },
        "3" : {
           "e" : 4
        }
     }
  }
  END

   }

  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (zeroOrMore(sequence('a'..'g')),
      except('d'..'g')
     );

    ok  $dfa->parser->accepts(qw(a b c d e f g a b c d e f g a));                 # Accept symbols
    ok !$dfa->parser->accepts(qw(a b c d e f g a b c d e f g g));                 # Fail to accept symbols

    my $parser = $dfa->parser;
    $parser->accept(qw(a b c d e f g a b c d e f g a));
    ok $parser->final;

    ok $dfa->print(q(Test)) eq <<END;                                             # Print compressed DFA
  Test
     State  Final  Symbol  Target  Final
  1      0         a            1      1
  2                b            2      1
  3                c            2      1
  4      1      1  b            3      0
  5      3         c            4      0
  6      4         d            5      0
  7      5         e            6      0
  8      6         f            7      0
  9      7         g            0      0
  END
   }


=head2 Data::DFA::Parser::final($)

Returns whether we are currently in a final state or not

     Parameter  Description
  1  $parser    DFA Parser

B<Example:>


  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (zeroOrMore(sequence('a'..'g')),
      except('d'..'g')
     );

    ok  $dfa->parser->accepts(qw(a b c d e f g a b c d e f g a));                 # Accept symbols
    ok !$dfa->parser->accepts(qw(a b c d e f g a b c d e f g g));                 # Fail to accept symbols

    my $parser = $dfa->parser;
    $parser->accept(qw(a b c d e f g a b c d e f g a));
    ok $parser->final;

    ok $dfa->print(q(Test)) eq <<END;                                             # Print compressed DFA
  Test
     State  Final  Symbol  Target  Final
  1      0         a            1      1
  2                b            2      1
  3                c            2      1
  4      1      1  b            3      0
  5      3         c            4      0
  6      4         d            5      0
  7      5         e            6      0
  8      6         f            7      0
  9      7         g            0      0
  END
   }


=head2 Data::DFA::Parser::next($)

Returns an array of symbols that would be accepted in the current state

     Parameter  Description
  1  $parser    DFA Parser

B<Example:>


  if (1) {
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

    ok $dfa->dumpAsJson eq <<END;                                                 # Dump as json
  {
     "finalStates" : {
        "0" : 0,
        "1" : 0,
        "2" : 0,
        "3" : 0,
        "4" : 1
     },
     "transitions" : {
        "0" : {
           "a" : 2
        },
        "1" : {
           "b" : 1,
           "c" : 1,
           "d" : 3,
           "e" : 4
        },
        "2" : {
           "b" : 1,
           "c" : 1
        },
        "3" : {
           "e" : 4
        }
     }
  }
  END

   }


=head2 Data::DFA::Parser::accepts($@)

Confirm that a DFA accepts an array representing a sequence of symbols

     Parameter  Description
  1  $parser    DFA Parser
  2  @symbols   Array of symbols

B<Example:>


  if (1) {
    my $dfa = fromExpr                                                            # Construct DFA
     (element("a"),
      oneOrMore(choice(element("b"), element("c"))),
      optional(element("d")),
      element("e")
     );

    ok  $dfa->parser->accepts(qw(a b e));                                         # Accept symbols
    ok !$dfa->parser->accepts(qw(a d));

    is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols

    ok $dfa->print("Dfa for a(b|c)+d?e :") eq <<END;                              # Print compressed DFA
  Dfa for a(b|c)+d?e :
     State  Final  Symbol  Target  Final
  1      0         a            2      0
  2      1         b            1      0
  3                c            1      0
  4                d            3      0
  5                e            4      1
  6      2         b            1      0
  7                c            1      0
  8      3         e            4      1
  END
   }

  if (1) {
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

    ok $dfa->dumpAsJson eq <<END;                                                 # Dump as json
  {
     "finalStates" : {
        "0" : 0,
        "1" : 0,
        "2" : 0,
        "3" : 0,
        "4" : 1
     },
     "transitions" : {
        "0" : {
           "a" : 2
        },
        "1" : {
           "b" : 1,
           "c" : 1,
           "d" : 3,
           "e" : 4
        },
        "2" : {
           "b" : 1,
           "c" : 1
        },
        "3" : {
           "e" : 4
        }
     }
  }
  END

   }



=head2 Data::DFA Definition


DFA State




=head3 Output fields


B<final> - Whether this state is final

B<nfaStates> - Hash whose keys are the NFA states that contributed to this super state

B<pump> - Pumping lemmas for this state

B<return> - Return state

B<sequence> - Sequence of states to final state minus pumped states

B<state> - Name of the state - the join of the NFA keys

B<transitions> - Transitions from this state



=head2 Data::DFA::State Definition


DFA State




=head3 Output fields


B<final> - Whether this state is final

B<nfaStates> - Hash whose keys are the NFA states that contributed to this super state

B<pump> - Pumping lemmas for this state

B<return> - Return state

B<sequence> - Sequence of states to final state minus pumped states

B<state> - Name of the state - the join of the NFA keys

B<transitions> - Transitions from this state



=head1 Private Methods

=head2 newDFA()

Create a new DFA


=head2 newState(%)

Create a new DFA state

     Parameter  Description
  1  %options   DFA state as hash

=head2 fromNfa($)

Create a DFA from an NFA.

     Parameter  Description
  1  $nfa       Nfa

=head2 finalState($$)

Check whether any of the specified states in the L<NFA|https://metacpan.org/pod/Data::NFA> are final

     Parameter  Description
  1  $nfa       NFA
  2  $reach     Hash of states in the NFA

=head2 superState($$$$$)

Create super states from existing superstate

     Parameter              Description
  1  $dfa                   DFA
  2  $superStateName        Start state in DFA
  3  $nfa                   NFA we are converting
  4  $symbols               Symbols in the NFA we are converting
  5  $nfaSymbolTransitions  States reachable from each state by symbol

=head2 superStates($$$)

Create super states from existing superstate

     Parameter        Description
  1  $dfa             DFA
  2  $SuperStateName  Start state in DFA
  3  $nfa             NFA we are tracking

=head2 transitionOnSymbol($$$)

The super state reached by transition on a symbol from a specified state

     Parameter        Description
  1  $dfa             DFA
  2  $superStateName  Start state in DFA
  3  $symbol          Symbol

=head2 removeDuplicatedStates($)

Remove duplicated states in a DFA

     Parameter  Description
  1  $dfa       Deterministic finite state automaton generated from an expression

=head2 printAsExpr2($%)

Print a DFA B<$dfa_> in expression form

     Parameter  Description
  1  $dfa       Dfa
  2  %options   Options


=head1 Index


1 L<choice|/choice> - Choice from amongst one or more elements.

2 L<compress|/compress> - Compress the L<DFA|https://metacpan.org/pod/Data::DFA> by removing duplicate states and deleting no longer needed L<NFA|https://metacpan.org/pod/Data::NFA> states

3 L<Data::DFA::Parser::accept|/Data::DFA::Parser::accept> - Accept the next symbol drawn from the symbol set if possible by moving to a new state otherwise confessing with a helpful message

4 L<Data::DFA::Parser::accepts|/Data::DFA::Parser::accepts> - Confirm that a DFA accepts an array representing a sequence of symbols

5 L<Data::DFA::Parser::final|/Data::DFA::Parser::final> - Returns whether we are currently in a final state or not

6 L<Data::DFA::Parser::next|/Data::DFA::Parser::next> - Returns an array of symbols that would be accepted in the current state

7 L<dumpAsJson|/dumpAsJson> - Create a JSON representation {transitions=>{symbol=>state}, finalStates=>{state=>1}}

8 L<element|/element> - One element.

9 L<except|/except> - Choice from amongst all symbols except the ones mentioned

10 L<finalState|/finalState> - Check whether any of the specified states in the L<NFA|https://metacpan.org/pod/Data::NFA> are final

11 L<fromExpr|/fromExpr> - Create a DFA from a regular expression.

12 L<fromNfa|/fromNfa> - Create a DFA from an NFA.

13 L<newDFA|/newDFA> - Create a new DFA

14 L<newState|/newState> - Create a new DFA state

15 L<oneOrMore|/oneOrMore> - One or more repetitions of a sequence of elements.

16 L<optional|/optional> - An optional sequence of element.

17 L<parseDtdElement|/parseDtdElement> - Convert the Dtd Element definition in B<$string>to a DFA

18 L<parser|/parser> - Create a parser from a deterministic finite state automaton constructed from a regular expression.

19 L<print|/print> - Print DFA to a string and optionally to STDERR or STDOUT

20 L<printAsExpr|/printAsExpr> - Print a B<$dfa> as an expression

21 L<printAsExpr2|/printAsExpr2> - Print a DFA B<$dfa_> in expression form

22 L<printAsRe|/printAsRe> - Print a B<$dfa> as a regular expression

23 L<removeDuplicatedStates|/removeDuplicatedStates> - Remove duplicated states in a DFA

24 L<sequence|/sequence> - Sequence of elements.

25 L<superState|/superState> - Create super states from existing superstate

26 L<superStates|/superStates> - Create super states from existing superstate

27 L<symbols|/symbols> - Return an array of all the symbols accepted by the DFA

28 L<transitionOnSymbol|/transitionOnSymbol> - The super state reached by transition on a symbol from a specified state

29 L<zeroOrMore|/zeroOrMore> - Zero or more repetitions of a sequence of elements.

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
use Test::More tests=>32;

#goto latestTest;

if (1)
 {my $s = q(zeroOrMore(choice(element("a"))));
  my $d = fromExpr(zeroOrMore(choice(element("a"))),
                   zeroOrMore(choice(element("a"))));

  if (1)
   {ok $d->print("a*a* 2:") eq <<END;
a*a* 2:
   State  Final  Symbol  Target  Final
1      0      1  a            0      1
END
   }
 }

if (1)
 {my $s = q(zeroOrMore(choice(element("a"))));
  my $S = join ', ', ($s) x 4;
  my $d = eval qq(fromExpr(&sequence($S)));
  ok $d->print("a*a* 4:") eq <<END;
a*a* 4:
   State  Final  Symbol  Target  Final
1      0      1  a            0      1
END

  ok  $d->parser->accepts(qw(a a a));
  ok !$d->parser->accepts(qw(a b a));
 }

if (1)
 {my $dfa = fromExpr
   (element("a"),
    oneOrMore(choice(element("b"), element("c"))),
    optional(element("d")),
    element("e")
   );

  ok  $dfa->parser->accepts(qw(a b e));
  ok !$dfa->parser->accepts(qw(a d));

  is_deeply ['a'..'e'], [$dfa->symbols];                                        # Print the symbols used and the transitions table:

  ok $dfa->print("Dfa for a(b|c)+d?e :") eq <<END;
Dfa for a(b|c)+d?e :
   State  Final  Symbol  Target  Final
1      0         a            2      0
2      1         b            1      0
3                c            1      0
4                d            3      0
5                e            4      1
6      2         b            1      0
7                c            1      0
8      3         e            4      1
END

# Create a parser and use it to parse a sequence of symbols

  my $parser = $dfa->parser;

  eval { $parser->accept($_) } for qw(a b a);
  my $r = $@;
  ok $r =~ m(Already processed: a b);
  ok $r =~ m(Expected one of  : b c d e);
  ok $r =~ m(But found        : a);

  is_deeply [$parser->next],     [qw(b c d e)];
  is_deeply  $parser->processed, [qw(a b)];
  ok !$parser->final;
 }

if (1) {                                                                        #Tsymbols #TfromExpr #Toptional #Telement #ToneOrMore #Tchoice #TData::DFA::Parser::accepts  #TdumpAsJson #Tnext #Tparser
  my $dfa = fromExpr                                                            # Construct DFA
   (element("a"),
    oneOrMore(choice(element("b"), element("c"))),
    optional(element("d")),
    element("e")
   );

  ok  $dfa->parser->accepts(qw(a b e));                                         # Accept symbols
  ok !$dfa->parser->accepts(qw(a d));

  is_deeply ['a'..'e'], [$dfa->symbols];                                        # List symbols

  ok $dfa->print("Dfa for a(b|c)+d?e :") eq <<END;                              # Print compressed DFA
Dfa for a(b|c)+d?e :
   State  Final  Symbol  Target  Final
1      0         a            2      0
2      1         b            1      0
3                c            1      0
4                d            3      0
5                e            4      1
6      2         b            1      0
7                c            1      0
8      3         e            4      1
END
 }

if (1) {                                                                        #TfromExpr #Toptional #Telement #ToneOrMore #Tchoice #TData::DFA::Parser::symbols #TData::DFA::Parser::accepts #TData::DFA::Parser::accept  #TData::DFA::Parser::next #Tparser
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

  ok $dfa->dumpAsJson eq <<END;                                                 # Dump as json
{
   "finalStates" : {
      "0" : 0,
      "1" : 0,
      "2" : 0,
      "3" : 0,
      "4" : 1
   },
   "transitions" : {
      "0" : {
         "a" : 2
      },
      "1" : {
         "b" : 1,
         "c" : 1,
         "d" : 3,
         "e" : 4
      },
      "2" : {
         "b" : 1,
         "c" : 1
      },
      "3" : {
         "e" : 4
      }
   }
}
END

 }

if (1) {                                                                        #TzeroOrMore #Texcept #Tsequence #TData::DFA::Parser::final #TData::DFA::Parser::accept #Tprint #Tcompress
  my $dfa = fromExpr                                                            # Construct DFA
   (zeroOrMore(sequence('a'..'g')),
    except('d'..'g')
   );

  ok  $dfa->parser->accepts(qw(a b c d e f g a b c d e f g a));                 # Accept symbols
  ok !$dfa->parser->accepts(qw(a b c d e f g a b c d e f g g));                 # Fail to accept symbols

  my $parser = $dfa->parser;
  $parser->accept(qw(a b c d e f g a b c d e f g a));
  ok $parser->final;

  ok $dfa->print(q(Test)) eq <<END;                                             # Print compressed DFA
Test
   State  Final  Symbol  Target  Final
1      0         a            1      1
2                b            2      1
3                c            2      1
4      1      1  b            3      0
5      3         c            4      0
6      4         d            5      0
7      5         e            6      0
8      6         f            7      0
9      7         g            0      0
END
 }

latestTest:;

if (1)
 {my $e = q/element(q(a)), zeroOrMore(element(q(b))), element(q(c))/;
  my $d = eval qq/fromExpr($e)/;
  confess $@ if $@;

  my $E = $d->printAsExpr;
  ok $e eq $E;

  my $R = $d->printAsRe;
  ok $R eq q(((a, (b)*, c)));

  my $D = parseDtdElement($R);
  my $S = $D->printAsExpr;
  ok $e eq $S;
 }

if (1)                                                                          #TprintAsExpr #TprintAsRe #TparseDtdElement
 {my $e = q/element(q(a)), zeroOrMore(choice(element(q(b)), element(q(c)))), element(q(d))/;
  my $d = eval qq/fromExpr($e)/;
  confess $@ if $@;

  my $E = $d->printAsExpr;
  ok $e eq $E;

  my $R = $d->printAsRe;
  ok $R eq q(((a, (b | c)*, d)));

  my $D = parseDtdElement($R);
  my $S = $D->printAsExpr;
  ok $e eq $S;
 }

done_testing;
#   owf(q(/home/phil/z/z/z/zzz.txt), $dfa->dumpAsJson);
