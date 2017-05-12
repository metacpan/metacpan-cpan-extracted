
#  Copyright (c) 1996, 1997 by Steffen Beyer. All rights reserved.
#  This package is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.

package DFA::Kleene;  #  DFA = Deterministic Finite Automaton

# Other modules in this series (variants of Kleene's algorithm):
#
# Math::MatrixBool (see "Kleene()")
# Math::MatrixReal (see "kleene()")

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
            $number_of_states %alphabet
            %accepting_states @delta
            @words %language);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw(initialize define_accepting_states define_delta kleene example);

%EXPORT_TAGS = (all => [@EXPORT_OK]);

$VERSION = '1.0';

use Carp;

sub initialize
{
    croak "Usage: DFA::Kleene::initialize(\$number_of_states,\$alphabet)"
      if (@_ != 2);

    my($number,$alpha) = @_;
    my($i,$j,$k);

    croak "DFA::Kleene::initialize(): number of states must be > 0"
      if ($number <= 0);
    croak "DFA::Kleene::initialize(): alphabet must comprise at least one character"
      if (length($alpha) == 0);

    $number_of_states = $number;

    undef %alphabet;
    undef %accepting_states;
    undef @delta;
    undef @words;
    undef %language;

    for ( $i = 0; $i < length($alpha); $i++ )
    {
        $alphabet{substr($alpha,$i,1)} = 1;
    }

    for ( $i = 1; $i <= $number_of_states; $i++ )
    {
        $delta[$i] = { };
        $words[$i] = [ ];
        for ( $j = 1; $j <= $number_of_states; $j++ )
        {
            $words[$i][$j] = [ ];
            for ( $k = 0; $k <= $number_of_states; $k++ )
            {
                $words[$i][$j][$k] = { };
            }
        }
    }
}

sub define_accepting_states
{
    croak "Usage: DFA::Kleene::define_accepting_states(\@accepting_states)"
      if (@_ < 1);

    my(@final) = @_;
    my($state);

    undef %accepting_states;
    foreach $state (@final)
    {
        croak "DFA::Kleene::define_accepting_states(): state $state not in [1..$number_of_states]"
          if (($state < 1) || ($state > $number_of_states));
        $accepting_states{$state} = 1;
    }
}

sub define_delta
{
    croak "Usage: DFA::Kleene::define_delta(\$state1,\$character,\$state2)"
      if (@_ != 3);

    my($state1,$character,$state2) = @_;

    croak "DFA::Kleene::define_delta(): state $state1 not in [1..$number_of_states]"
      if (($state1 < 1) || ($state1 > $number_of_states));
    croak "DFA::Kleene::define_delta(): state $state2 not in [1..$number_of_states]"
      if (($state2 < 1) || ($state2 > $number_of_states));
    croak "DFA::Kleene::define_delta(): only single character or empty string permitted"
      if (length($character) > 1);
    croak "DFA::Kleene::define_delta(): character is not contained in alphabet"
      if ($character && !($alphabet{$character}));
    croak "DFA::Kleene::define_delta(): \$delta[$state1]{'$character'} already defined"
      if (defined $delta[$state1]{$character});

    $delta[$state1]{$character} = $state2;
}

sub kleene
{
    croak "Usage: DFA::Kleene::kleene()"
      if (@_ != 0);

    my($i,$j,$k);
    my($state,$word,$word1,$word2,$word3);

    for ( $i = 1; $i <= $number_of_states; $i++ )
    {
        for ( $j = 1; $j <= $number_of_states; $j++ )
        {
            foreach $_ (keys %{$delta[$i]})
            {
                if ($delta[$i]{$_} == $j)
                {
                    $words[$i][$j][0]{$_} = 1;
                }
            }
            if ($i == $j) { $words[$i][$j][0]{''} = 1; }
        }
    }

    for ( $k = 1; $k <= $number_of_states; $k++ )
    {
        for ( $i = 1; $i <= $number_of_states; $i++ )
        {
            for ( $j = 1; $j <= $number_of_states; $j++ )
            {
                foreach $word (keys %{$words[$i][$j][$k-1]})
                {
                    $words[$i][$j][$k]{$word} = 1;
                }
                foreach $word1 (keys %{$words[$i][$k][$k-1]})
                {
                    foreach $word2 (keys %{$words[$k][$k][$k-1]})
                    {
                        foreach $word3 (keys %{$words[$k][$j][$k-1]})
                        {
                            if ($word2)
                                { $word = "${word1}(${word2})*${word3}"; }
                            else
                                { $word = "${word1}${word3}"; }
                            $words[$i][$j][$k]{$word} = 1;
                        }
                    }
                }
            }
        }
    }
    undef %language;
    foreach $state (keys %accepting_states)
    {
        # Note that the following assumes state #1 to be the "start" state:

        foreach $word (keys %{$words[1][$state][$number_of_states]})
        {
            $language{$word} = 1;
        }
    }
    return( sort(keys %language) );
}

sub example
{
    &initialize(6,"ab");
    &define_accepting_states(2,3,4,5);
    &define_delta(1,'a',4);
    &define_delta(1,'b',6);
    &define_delta(2,'a',2);
    &define_delta(2,'b',5);
    &define_delta(3,'a',6);
    &define_delta(3,'b',3);
    &define_delta(4,'a',2);
    &define_delta(4,'b',5);
    &define_delta(5,'a',4);
    &define_delta(5,'b',3);
    &define_delta(6,'a',6);
    &define_delta(6,'b',6);

    # should return something equivalent to:
    #         (a(a)*b)*a(a)*(b)*
    # which is the same as ((a+)b)*(a+)b*

    foreach $_ ( &kleene() )
    {
        print "'$_'\n";
    }
}

1;

__END__

=head1 NAME

DFA::Kleene - Kleene's Algorithm for Deterministic Finite Automata

Calculates the "language" (set of words) accepted
(= recognized) by a Deterministic Finite Automaton

See L<Math::Kleene(3)> for the theory behind this algorithm!

=head1 SYNOPSIS

=over 4

=item *

C<use DFA::Kleene qw(initialize define_accepting_states>
C<define_delta kleene example);>

=item *

C<use DFA::Kleene qw(:all);>

=item *

C<&initialize(6,"ab");>

Define the number of states (state #1 is the "start" state!) of your
Deterministic Finite Automaton and the alphabet used (as a string
containing all characters which are part of the alphabet).

=item *

C<&define_accepting_states(2,3,4,5);>

Define which states are "accepting states" in your Deterministic Finite
Automaton (list of state numbers).

=item *

C<&define_delta(1,'a',4);>

Define the state transition function "delta" (arguments are: "from" state,
character (or empty string!) read during the transition, "to" state).

You need several calls to this function in order to build a complete
transition table describing your Deterministic Finite Automaton.

=item *

C<@language = &kleene();>

Returns a (sorted) list of regular expressions describing the language
(= set of patterns) recognized ("accepted") by your Deterministic Finite
Automaton.

=item *

C<&example();>

Calculates the language of a sample Deterministic Finite Automaton.

Prints a (sorted) list of regular expressions which should be equivalent
to the following regular expression:

            (a(a)*b)*a(a)*(b)*

This is the same as

            ((a+)b)*(a+)b*

=back

=head1 DESCRIPTION

The routines in this module allow you to define a Deterministic Finite
Automaton and to compute the "language" (set of "words" or "patterns")
accepted (= recognized) by it.

Actually, a list of regular expressions is generated which describe the
same language (set of patterns) as the one accepted by your Deterministic
Finite Automaton.

The output generated by this module can easily be modified to produce
Perl-style regular expressions which can actually be used to recognize
words (= patterns) contained in the language defined by your Deterministic
Finite Automaton.

Other modules in this series (variants of Kleene's algorithm):

=over 4

=item *

Math::MatrixBool (see "Kleene()")

=item *

Math::MatrixReal (see "kleene()")

=back

=head1 SEE ALSO

Math::MatrixBool(3), Math::MatrixReal(3), Math::Kleene(3),
Set::IntegerRange(3), Set::IntegerFast(3), Bit::Vector(3).

=head1 VERSION

This man page documents "DFA::Kleene" version 1.0.

=head1 AUTHOR

Steffen Beyer <sb@sdm.de>.

=head1 COPYRIGHT

Copyright (c) 1996, 1997 by Steffen Beyer. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

