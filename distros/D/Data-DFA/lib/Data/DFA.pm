#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Deterministic finite state parser from a regular expression
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2018
#-------------------------------------------------------------------------------

package Data::DFA;
our $VERSION = "20180328";
require v5.16;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::NFA qw(:all);
use Data::Table::Text qw(:all);
use utf8;

sub StateName{0}                                                                # Constants describing a state of the finite state automaton: [{transition label=>new state}, {jump target=>1}, final state if true]
sub States{1}
sub Transitions{2}
sub Final{3}

#1 Deterministic finite state parser                                            # Create a deterministic finite state automaton to parse sequences of symbols in the language defined by a regular expression.

sub fromExpr(@)                                                                 #S Create a DFA from a regular expression.
 {my (@expr) = @_;                                                              # Expression
  my $nfa = Data::NFA::fromExpr(@expr);

  my $dfa  = bless {};                                                          # States in DFA
  $$dfa{0} = bless [0,                                                          # Start state
    bless({0=>1}, "Data::DFA::NfaStates"),
    bless({},     "Data::DFA::Transitions"),
    $nfa->isFinal(0)], "Data::DFA::State";
  $dfa->superStates(0, $nfa);
  $dfa
 }

sub finalState($$)                                                              # Check whether any of the specified states in the NFA are final
 {my ($nfa, $reach) = @_;                                                       # NFA, hash of states in the NFA
  for my $state(sort keys %$reach)
   {return 1 if $nfa->isFinal($state);
   }
  0
 }

sub superState($$$)                                                             # Create super states from existing superstate
 {my ($dfa, $superStateName, $nfa) = @_;                                        # DFA, start state in DFA, NFA we are tracking
  my $superState = $$dfa{$superStateName};
  my (undef, $nfaStates, $transitions) = @$superState;

  my @created;                                                                  # New super states created
  for my $symbol($nfa->symbols)                                                 # Each symbol
   {my $reach = {};                                                             # States in NFS reachable from start state in dfa
    for my $nfaState(sort keys %$nfaStates)                                     # Each NFA state in the dfa start state
     {my $r = $nfa->statesReachableViaSymbol($nfaState, $symbol);               # States in the NFA reachable on the symbol
      $$reach{$_}++ for sort keys %$r;                                          # Accumulate NFA reachable NFA states
     }
    my $newSuperStateName = join ' ', sort keys %$reach;                        # Name of the super state reached from the start state via the current symbol
    if (!$$dfa{$newSuperStateName})                                             # Super state does not exists so create it
     {my $newState = $$dfa{$newSuperStateName} = bless
       [$newSuperStateName,
        bless($reach, "Data::DFA::NfaStates"),
        bless({},     "Data::DFA::Transitions"),
        finalState($nfa, $reach)], "Data::DFA::State";
      push @created, $newSuperStateName;                                        # Find all its transitions
     }
    $$dfa{$superStateName}[Transitions]{$symbol} = $newSuperStateName;
   }
  @created
 }

sub superStates($$$)                                                            # Create super states from existing superstate
 {my ($dfa, $SuperStateName, $nfa) = @_;                                        # DFA, start state in DFA, NFA we are tracking
  my @fix = ($SuperStateName);
  while(@fix)                                                                   # Create each superstate as the set of all nfa states we could be in after each transition on a symbol
   {push @fix, superState($dfa, pop @fix, $nfa);
   }
 }

sub transitionOnSymbol($$$)                                                     # The super state reached by transition on a symbol from a specified state
 {my ($dfa, $superStateName, $symbol) = @_;                                     # DFA, start state in DFA, symbol
  my $superState = $$dfa{$superStateName};
  my (undef, $nfaStates, $transitions, $final) = @$superState;
  $$transitions{$symbol}
 }

sub print($$$)                                                                  # Print DFA
 {my ($dfa, $title, $print) = @_;                                               # DFA, title, 1 - STDOUT or 2 - STDERR
  my @out;
  for my $superStateName(sort keys %$dfa)
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
    return nws $s;
   }
  "$title: No states in Dfa";
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
   {my @next      = sort keys %$transitions;
    my @processed = @{$parser->processed};
    $parser->next = [@next];
    my $next = join ' ', @next;
    confess join "\n",
      "Already processed: ". join(' ', @processed),
       @next > 0 ? "Expected one of  : ". join(' ', @next) :
                   "Expected nothing more.",
      "But was given    : $symbol",
      '';
   }
 }

sub Data::DFA::Parser::final($)                                                 # Returns whether we are currently in a final state or not
 {my ($parser) = @_;                                                            # DFA Parser
  my $dfa = $parser->dfa;
  my $state = $parser->state;
  $$dfa{$state}[Final] ? 1 : 0
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
  my $dfa = $parser->dfa;
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

For example: to recognize sequences of symbols drawn from B<'a'..'e'> that match
the regular expression: B<a (b|c)+ d? e> proceed as follows:

# Construct a deterministic finite state automaton from the regular expression:

  use Data::DFA qw(:all);
  use Data::Table::Text qw(:all);
  use Test::More qw(no_plan);

  my $dfa = dfaFromExpr
   (element("a"),
    oneOrMore(choice(element("b"), element("c"))),
    optional(element("d")),
    element("e")
   );

# Print the symbols used and the transitions table:

  is_deeply ['a'..'e'], [$dfa->symbols];

  ok $dfa->print("Dfa for a(b|c)+d?e :") eq nws <<END;
Dfa for a(b|c)+d?e :
Location  F  Transitions
       0  0  { a => 1 }
       1  0  { b => 2, c => 2 }
       2  0  { b => 2, c => 2, d => 6, e => 7 }
       6  0  { e => 7 }
       7  1  undef
END

# Create a parser and parse a sequence of symbols with the returned sub:

  my ($parser, $end, $next, $processed) = $dfa->parser;                         # New parser

  eval { &$parser($_) } for(qw(a b a));                                         # Try to parse a b a

  say STDERR $@;                                                                # Error message
#   Already processed: a b
#   Expected one of  : b c d e
#   But was given    : a

  is_deeply [&$next],      [qw(b c d e)];                                       # Next acceptable symbol
  is_deeply [&$processed], [qw(a b)];                                           # Symbols processed
  ok !&$end;                                                                    # Not at the end

=head1 Description

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Deterministic finite state parser

Create a deterministic finite state automaton to parse sequences of symbols in the language defined by a regular expression.

=head2 fromExpr(@)

Create a DFA from a regular expression.

     Parameter  Description
  1  @expr      Expression

This is a static method and so should be invoked as:

  Data::DFA::fromExpr


=head2 finalState($$)

Check whether any of the specified states in the NFA are final

     Parameter  Description
  1  $nfa       NFA
  2  $reach     Hash of states in the NFA

=head2 superState($$$)

Create super states from existing superstate

     Parameter        Description
  1  $dfa             DFA
  2  $superStateName  Start state in DFA
  3  $nfa             NFA we are tracking

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

=head2 print($$$)

Print DFA

     Parameter  Description
  1  $dfa       DFA
  2  $title     Title
  3  $print     1 - STDOUT or 2 - STDERR

=head2 parser($)

Create a parser from a deterministic finite state automaton constructed from a regular expression.

     Parameter  Description
  1  $dfa       Deterministic finite state automaton generated from an expression

This is a static method and so should be invoked as:

  Data::DFA::parser


=head1 Parser methods

Use the DFA to parse a sequence of symbols

=head2 Data::DFA::Parser::accept($$)

Accept the next symbol drawn from the symbol set if possible by moving to a new state otherwise confessing with a helpful message

     Parameter  Description
  1  $parser    DFA Parser
  2  $symbol    Next symbol to be processed by the finite state automaton

=head2 Data::DFA::Parser::final($)

Returns whether we are currently in a final state or not

     Parameter  Description
  1  $parser    DFA Parser

=head2 Data::DFA::Parser::next($)

Returns an array of symbols that would be accepted in the current state

     Parameter  Description
  1  $parser    DFA Parser

=head2 Data::DFA::Parser::accepts($@)

Confirm that a DFA accepts an array representing a sequence of symbols

     Parameter  Description
  1  $parser    DFA Parser
  2  @symbols   Array of symbols


=head1 Index


1 L<Data::DFA::Parser::accept|/Data::DFA::Parser::accept>

2 L<Data::DFA::Parser::accepts|/Data::DFA::Parser::accepts>

3 L<Data::DFA::Parser::final|/Data::DFA::Parser::final>

4 L<Data::DFA::Parser::next|/Data::DFA::Parser::next>

5 L<finalState|/finalState>

6 L<fromExpr|/fromExpr>

7 L<parser|/parser>

8 L<print|/print>

9 L<superState|/superState>

10 L<superStates|/superStates>

11 L<transitionOnSymbol|/transitionOnSymbol>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard L<Module::Build> process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

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
 }

test unless caller;

1;
# podDocumentation
#__DATA__
use warnings FATAL=>qw(all);
use strict;
use Test::More tests=>4;

if (1)
 {my $s = q(zeroOrMore(choice(element("a"))));
  my $dfa = fromExpr(zeroOrMore(choice(element("a"))), zeroOrMore(choice(element("a"))), );
  ok $dfa->print("a*a* 2: ") eq nws <<END;
a*a* 2:
   State      Final  Symbol  Target     Final
1          0      1  a       0 1 2 3 4      1
2  0 1 2 3 4      1  a       0 1 2 3 4      1
END
 }

if (1)
 {my $s = q(zeroOrMore(choice(element("a"))));
  my $dfa = eval qq(fromExpr(&sequence($s,$s,$s,$s)));
  ok $dfa->print("a*a* 2: ") eq nws <<END;
a*a* 2:
   State              Final  Symbol  Target             Final
1                  0      1  a       0 1 2 3 4 5 6 7 8      1
2  0 1 2 3 4 5 6 7 8      1  a       0 1 2 3 4 5 6 7 8      1
END

  ok  $dfa->parser->accepts(qw(a a a));
  ok !$dfa->parser->accepts(qw(a b a));

 }
