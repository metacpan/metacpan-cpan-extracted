package Data::Password::zxcvbn::Match::Spatial;
use Moo;
with 'Data::Password::zxcvbn::Match';
use Data::Password::zxcvbn::AdjacencyGraph;
use Data::Password::zxcvbn::Combinatorics qw(nCk);
use List::AllUtils qw(min);
our $VERSION = '1.0.3'; # VERSION
# ABSTRACT: match class for sequences of nearby keys


# this should be constrained to the keys of %graphs, but we can't do
# that because users can pass their own graphs to ->make
has graph_name => (is=>'ro',default=>'qwerty');
has graph_meta => (is=>'ro',default=>sub {+{}});
has shifted_count => (is=>'ro',default=>0);
has turns => (is=>'ro',default=>1);


sub estimate_guesses {
    my ($self,$min_guesses) = @_;

    my $starts = $self->graph_meta->{starting_positions};
    my $degree = $self->graph_meta->{average_degree};

    my $guesses = 0;
    my $length = length($self->token);
    my $turns = $self->turns;

    # estimate the number of possible patterns w/ length $length or
    # less with $turns turns or less.
    for my $i (2..$length) {
        my $possible_turns = min($turns, $i-1);
        for my $j (1..$possible_turns) {
            $guesses += nCk($i-1,$j-1) * $starts * $degree**$j;
        }
    }

    # add extra guesses for shifted keys. (% instead of 5, A instead
    # of a.)  math is similar to extra guesses of l33t substitutions
    # in dictionary matches.

    if (my $shifts = $self->shifted_count) {
        my $unshifts = $length - $shifts;
        if ($shifts == 0 || $unshifts == 0) {
            $guesses *= 2;
        }
        else {
            my $shifted_variations = 0;
            for my $i (1..min($shifts,$unshifts)) {
                $shifted_variations += nCk($length,$i);
            }
            $guesses *= $shifted_variations;
        }
    }

    return $guesses;
}


sub make {
    my ($class, $password, $opts) = @_;
    my $graphs = $opts->{graphs}
        || \%Data::Password::zxcvbn::AdjacencyGraph::graphs; ## no critic (ProhibitPackageVars)

    my $length = length($password);
    my @matches = ();
    for my $name (keys %{$graphs}) {
        my $graph = $graphs->{$name}{keys};

        my $i=0;
        while ($i < $length-1) {
            my $j = $i+1;
            # this has to be different from the -1 used later, and
            # different from the direction indices (usually 0..3)
            my $last_direction = -2;
            my $turns = 0;
            my $shifted_count = (
                $name !~ m{keypad} &&
                    substr($password,$i,1) =~
                    m{[~!@#\$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?]}
                )
                ? 1 # first character is shifted
                : 0;

          GROW:
            while (1) {
                my $found = 0;
                # consider growing pattern by one character if j
                # hasn't gone over the edge.
                if ($j < $length) {
                    my $found_direction = -1; my $cur_direction = -1;
                    my $prev_character = substr($password,$j-1,1);
                    my $cur_character = substr($password,$j,1);
                  ADJACENCY:
                    for my $adj (@{ $graph->{$prev_character} || [] }) {
                        ## no critic (ProhibitDeepNests)
                        ++$cur_direction;
                        if (defined($adj) &&
                                (my $idx = index($adj,$cur_character)) >= 0) {
                            $found=1; $found_direction = $cur_direction;
                            # index 1 in the adjacency means the key
                            # is shifted, 0 means unshifted: A vs a, %
                            # vs 5, etc.  for example, 'q' is adjacent
                            # to the entry '2@'.  @ is shifted w/
                            # index 1, 2 is unshifted.
                            ++$shifted_count if $idx==1;
                            if ($last_direction != $cur_direction) {
                                # adding a turn is correct even in the
                                # initial case when last_direction is
                                # -2: every spatial pattern starts
                                # with a turn.
                                ++$turns;
                                $last_direction = $cur_direction;
                            }
                            # found a match, stop looking at this key
                            last ADJACENCY;
                        }
                    }
                }

                if ($found) {
                    # if the current pattern continued, extend j and
                    # try to grow again
                    ++$j;
                }
                else {
                    # otherwise push the pattern discovered so far, if
                    # any...
                    my %meta = %{ $graphs->{$name} };
                    delete $meta{keys};
                    push @matches, $class->new({
                        i => $i, j => $j-1,
                        token => substr($password,$i,$j-$i),
                        graph_name => $name,
                        graph_meta => \%meta,
                        turns => $turns,
                        shifted_count => $shifted_count,
                    }) unless $j-$i<=2; # don't consider short chains

                    # ...and then start a new search for the rest of
                    # the password.
                    $i = $j;
                    last GROW;
                }
            }
        }
    }

    @matches = sort @matches;
    return \@matches;
}


sub feedback_warning {
    my ($self) = @_;

    return $self->turns == 1
        ? 'Straight rows of keys are easy to guess'
        : 'Short keyboard patterns are easy to guess'
        ;
}

sub feedback_suggestions {
    return [ 'Use a longer keyboard pattern with more turns' ];
}


around fields_for_json => sub {
    my ($orig,$self) = @_;
    ( $self->$orig(), qw(graph_name shifted_count turns) )
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::Match::Spatial - match class for sequences of nearby keys

=head1 VERSION

version 1.0.3

=head1 DESCRIPTION

This class represents the guess that a certain substring of a password
can be obtained by moving a finger in a continuous line on a keyboard.

=head1 ATTRIBUTES

=head2 C<graph_name>

The name of the keyboard / adjacency graph used for this match

=head2 C<graph_meta>

Hashref, spatial information about the graph:

=over 4

=item *

C<starting_positions>

the number of keys in the keyboard, or starting nodes in the graph

=item *

C<average_degree>

the average number of neighbouring keys, or average out-degree of the graph

=back

=head2 C<shifted_count>

How many of the keys need to be "shifted" to produce the token

=head2 C<turns>

How many times the finger must have changed direction to produce the
token

=head1 METHODS

=head2 C<estimate_guesses>

The number of guesses grows super-linearly with the length of the
pattern, the number of L</turns>, and the amount of L<shifted
keys|/shifted_count>.

=head2 C<make>

  my @matches = @{ Data::Password::zxcvbn::Match::Spatial->make(
    $password,
    { # this is the default
      graphs => \%Data::Password::zxcvbn::AdjacencyGraph::graphs,
    },
  ) };

Scans the C<$password> for substrings that can be produced by typing
on the keyboards described by the C<graphs>.

The data structure needed for C<graphs> is a bit complicated; look at
the L<< C<build-keyboard-adjacency-graphs> script in the
distribution's
repository|https://bitbucket.org/broadbean/p5-data-password-zxcvbn/src/master/maint/build-keyboard-adjacency-graphs
>>.

=head2 C<feedback_warning>

=head2 C<feedback_suggestions>

This class suggests that short keyboard patterns are easy to guess,
and to use longer and less straight ones.

=head2 C<fields_for_json>

The JSON serialisation for matches of this class will contain C<token
i j guesses guesses_log10 graph_name shifted_count turns>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
