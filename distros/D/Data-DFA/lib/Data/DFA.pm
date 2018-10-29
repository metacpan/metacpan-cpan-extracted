#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Deterministic finite state parser from a regular expression
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2018
#-------------------------------------------------------------------------------
# podDocumentation

package Data::DFA;
our $VERSION = "20181027";
require v5.16;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::NFA;
use Data::Table::Text qw(:all);
use Storable qw(freeze);
use utf8;

sub StateName{0}                                                                # Constants describing a state of the finite state automaton: [{transition label=>new state}, {jump target=>1}, final state if true]
sub States{1}
sub Transitions{2}
sub Final{3}

sub compressDfa{1}                                                              # Compress the DFA once constructed - uncompressed is useful for testing

#1 Construct regular expression                                                 # Construct a regular expression that defines the language to be parsed using the following combining operations which can all be imported:

sub element($)                                                                  #ES One element.
 {my ($label) = @_;                                                             # Transition symbol
  &Data::NFA::element(@_);
 }

sub sequence(@)                                                                 #ES Sequence of elements.
 {my (@elements) = @_;                                                          # Elements
  &Data::NFA::sequence(@_);
 }

sub optional(@)                                                                 #ES An optional sequence of element.
 {my (@element) = @_;                                                           # Elements
  &Data::NFA::optional(@_);
 }

sub zeroOrMore(@)                                                               #ES Zero or more repetitions of a sequence of elements.
 {my (@element) = @_;                                                           # Elements
  &Data::NFA::zeroOrMore(@_);
 }

sub oneOrMore(@)                                                                #ES One or more repetitions of a sequence of elements.
 {my (@element) = @_;                                                           # Elements
  &Data::NFA::oneOrMore(@_);
 }

sub choice(@)                                                                   #ES Choice from amongst one or more elements.
 {my (@elements) = @_;                                                          # Elements to be chosen from
  &Data::NFA::choice(@_);
 }

sub except(@)                                                                   #ES Choice from amongst one or more elements.
 {my (@elements) = @_;                                                          # Elements to be chosen from
  &Data::NFA::except(@_);
 }

#1 Deterministic finite state parser                                            # Create a deterministic finite state automaton to parse sequences of symbols in the language defined by a regular expression.

sub fromExpr(@)                                                                 #S Create a DFA from a regular expression.
 {my (@expr) = @_;                                                              # Expression
  my $nfa = Data::NFA::fromExpr(@expr);

  my $dfa  = bless {};                                                          # States in DFA
  $$dfa{0} = bless                                                              # Start state
   [0,                                                                          # Name of the state - the join of the NFA keys
    bless({0=>1}, "Data::DFA::NfaStates"),                                      # Hash whose keys are the NFA states that contributed to this super state
    bless({},     "Data::DFA::Transitions"),                                    # Transitions from this state
    $nfa->isFinal(0)                                                            # Whether this state is final
   ], "Data::DFA::State";

  $dfa->superStates(0, $nfa);                                                   # Create DFA
  return $dfa unless compressDfa;                                               # Uncompressed DFA
  my $cfa = $dfa->compress;                                                               # Rename states so that they occupy less space and remove NFA states as no longer needed
  $cfa
 }

sub finalState($$)                                                              #P Check whether any of the specified states in the NFA are final
 {my ($nfa, $reach) = @_;                                                       # NFA, hash of states in the NFA
  for my $state(sort keys %$reach)
   {return 1 if $nfa->isFinal($state);
   }
  0
 }

sub superState($$$$$)                                                           #P Create super states from existing superstate
 {my ($dfa, $superStateName, $nfa, $symbols, $nfaSymbolTransitions) = @_;       # DFA, start state in DFA, NFA we are converting, symbols in the NFA we are converting, states reachable from each state by symbol
  my $superState = $$dfa{$superStateName};
  my (undef, $nfaStates, $transitions) = @$superState;

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
       {my $newState = $$dfa{$newSuperStateName} = bless
         [undef, #$newSuperStateName,   not needed
          bless($reach, "Data::DFA::NfaStates"),
          bless({},     "Data::DFA::Transitions"),
          finalState($nfa, $reach)], "Data::DFA::State";
        push @created, $newSuperStateName;                                      # Find all its transitions
       }
      $$dfa{$superStateName}[Transitions]{$symbol} = $newSuperStateName;
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
  my $superState = $$dfa{$superStateName};
  my (undef, $nfaStates, $transitions, $final) = @$superState;
  $$transitions{$symbol}
 }

sub compress($)                                                                 # Compress DFA by renaming states and deleting no longer needed NFA states
 {my ($dfa) = @_;                                                               # DFA
  my %rename;
  my $cfa = bless {};
  for my $superStateName(sort keys %$dfa)                                       # Each state
   {$rename{$superStateName} = scalar keys %rename;                             # Rename state
   }
  for my $superStateName(sort keys %$dfa)                                       # Each state
   {my $sourceState = $rename{$superStateName};
    my $s = $$cfa{$sourceState} = [];
    my $superState  = $$dfa{$superStateName};
    my (undef, $nfaStates, $transitions, $final) = @$superState;
    for my $symbol(sort keys %$transitions)                                     # Rename the target of every transition
     {$$s[Transitions]{$symbol} = $rename{$$transitions{$symbol}};
     }
    $$s[Final] = $final;
   }
  $cfa
 }

sub print($$;$)                                                                 # Print DFA to a string and optionally to STDERR or STDOUT
 {my ($dfa, $title, $print) = @_;                                               # DFA, title, 1 - STDOUT or 2 - STDERR
  my @out;
  for my $superStateName(sort keys %$dfa)                                       # Each state
   {my $superState = $$dfa{$superStateName};
    my (undef, $nfaStates, $transitions, $Final) = @$superState;
    my @s = sort keys %$transitions;
    if (@s > 0)
     {my $s = $s[0];
      my $S = $dfa->transitionOnSymbol($superStateName, $s);
      my $final = $$dfa{$S}[Final];
      push @out, [$superStateName, $Final, $s, $$transitions{$s}, $final];
      for(1..$#s)
       {my $s = $s[$_];
        my $S = $dfa->transitionOnSymbol($superStateName, $s);
        my $final = $$dfa{$S}[Final];
        push @out, ['', '', $s, $$transitions{$s}, $final];
       }
     }
   }
  if (@out)
   {my $s = "$title\n".formatTable([@out], [qw(State Final Symbol Target Final)])."\n";
    say STDOUT $s if $print and $print == 1;
    say STDERR $s if $print and $print == 2;
    return $s;
   }
  "$title: No states in Dfa";
 }

sub printNws($$;$)                                                              # Print DFA with white space normalized
 {my ($dfa, $title, $print) = @_;                                               # DFA, title, 1 - STDOUT or 2 - STDERR
  nws &print(@_);
 }

sub symbols($)                                                                  # Return an array of all the symbols accepted by the DFA
 {my ($dfa) = @_;                                                               # DFA
  my %symbols;
  for my $superStateName(keys %$dfa)                                            # Each state
   {my $superState = $$dfa{$superStateName};
    my (undef, $nfaStates, $transitions, $final) = @$superState;
    $symbols{$_}++ for keys %$transitions;                                      # Symbol for each transition
   }
  sort keys %symbols;
 }

sub parser($)                                                                   #S Create a parser from a deterministic finite state automaton constructed from a regular expression.
 {my ($dfa) = @_;                                                               # Deterministic finite state automaton generated from an expression
  package Data::DFA::Parser;
  return bless {dfa=>$dfa, state=>0, processed=>[]};
  use Data::Table::Text qw(:all);
  BEGIN
   {genLValueScalarMethods(qw(dfa state));
    genLValueArrayMethods(qw(processed));
   }
 }

#1 Parser methods                                                               # Use the DFA to parse a sequence of symbols

sub Data::DFA::Parser::accept($$)                                               # Accept the next symbol drawn from the symbol set if possible by moving to a new state otherwise confessing with a helpful message
 {my ($parser, $symbol) = @_;                                                   # DFA Parser, next symbol to be processed by the finite state automaton
  my $dfa = $parser->dfa;
  my $transitions = $$dfa{$parser->state}[Transitions];
  if (my $nextState = $$transitions{$symbol})
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
  return 1 if $$dfa{$state}[Final];
  0
 }

sub Data::DFA::Parser::next($)                                                  # Returns an array of symbols that would be accepted in the current state
 {my ($parser) = @_;                                                            # DFA Parser
  my $dfa = $parser->dfa;
  my $state = $parser->state;
  my $transitions = $$dfa{$state}[Transitions];
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

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT_OK    = qw(
choice
fromExpr
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

  say STDERR $@;                                                                # Error message
#   Already processed: a b
#   Expected one of  : b c d e
#   But was given    : a

  is_deeply [$parser->next],     [qw(b c d e)];                                 # Next acceptable symbol
  is_deeply  $parser->processed, [qw(a b)];                                     # Symbols processed
  ok !$parser->final;                                                           # Not in a final state

=head1 Description

Deterministic finite state parser from regular expression


Version "20181027".


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.




=head1 Index


=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Data::DFA

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2018 Philip R Brenan.

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
use Test::More tests=>11;

if (1)
 {my $s = q(zeroOrMore(choice(element("a"))));
  my $d = fromExpr(zeroOrMore(choice(element("a"))), zeroOrMore(choice(element("a"))), );
  if (compressDfa)
   {ok $d->printNws("a*a* 2: ") eq nws(<<END);
a*a* 2:
   State  Final  Symbol  Target  Final
1  0      1      a       1       1
2  1      1      a       1       1
END
   }
  else
   {ok $d->printNws("a*a* 2: ") eq nws(<<END);
a*a* 2:
   State      Final  Symbol  Target     Final
1          0      1  a       0 1 2 3 4      1
2  0 1 2 3 4      1  a       0 1 2 3 4      1
END
   }
 }

if (1)
 {my $s = q(zeroOrMore(choice(element("a"))));
  my $d = eval qq(fromExpr(&sequence($s,$s,$s,$s)));
  if (compressDfa)
   {ok $d->printNws("a*a* 2: ") eq nws(<<END);
a*a* 2:
   State  Final  Symbol  Target  Final
1  0      1      a       1       1
2  1      1      a       1       1
END
   }
  else
   {ok $d->printNws("a*a* 2: ") eq nws(<<END);
a*a* 2:
   State              Final  Symbol  Target             Final
1                  0      1  a       0 1 2 3 4 5 6 7 8      1
2  0 1 2 3 4 5 6 7 8      1  a       0 1 2 3 4 5 6 7 8      1
END
   }
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

# Print the symbols used and the transitions table:

  is_deeply ['a'..'e'], [$dfa->symbols];

  if (compressDfa)
   {ok $dfa->printNws("Dfa for a(b|c)+d?e :") eq nws(<<END);
Dfa for a(b|c)+d?e :
    State  Final  Symbol  Target  Final
1   0             a       2       0
2   1      0      b       1       0
3                 c       3       0
4                 d       4       0
5                 e       5       1
6   2      0      b       1       0
7                 c       3       0
8   3      0      b       1       0
9                 c       3       0
10                d       4       0
11                e       5       1
12  4      0      e       5       1
END
   }
  else
   {ok $dfa->printNws("Dfa for a(b|c)+d?e :") eq nws(<<END);

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
   }
# Create a parser and use it to parse a sequence of symbols

  my $parser = $dfa->parser;                                                    # New parser

  eval { $parser->accept($_) } for qw(a b a);                                   # Try to parse a b a

  say STDERR $@;                                                                # Error message
#   Already processed: a b
#   Expected one of  : b c d e
#   But was given    : a

  is_deeply [$parser->next],     [qw(b c d e)];                                 # Next acceptable symbol
  is_deeply  $parser->processed, [qw(a b)];                                     # Symbols processed
  ok !$parser->final;                                                           # Not in a final state
 }
