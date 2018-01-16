package Data::Password::zxcvbn::MatchList;
use Moo;
use Data::Password::zxcvbn::Match::BruteForce;
use Data::Password::zxcvbn::Combinatorics qw(factorial);
use Data::Password::zxcvbn::TimeEstimate qw(guesses_to_score);
use Module::Runtime qw(use_module);
use List::AllUtils 0.14 qw(max_by);

our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: a collection of matches for a password


has password => (is => 'ro', required => 1);  # string
has matches => (is => 'ro', default => sub { [] });
has guesses => (is => 'ro');


sub omnimatch {
    my ($class, $password, $opts) = @_;

    # let's protect people who try to pass BruteForce in
    my @modules = $opts->{modules}
        ? grep { $_ ne 'Data::Password::zxcvbn::Match::BruteForce' } @{$opts->{modules}}
        : map { "Data::Password::zxcvbn::Match::$_" }
        qw(
              Dictionary
              UserInput
              Spatial
              Repeat
              Sequence
              Regex
              Date
      );

    # here, we need to pass the whole $opts down, because some
    # matchers (e.g. Repeat) will use it to call us recursively, and
    # we don't want to lose any option
    my @matches = map {
        @{ use_module($_)->make($password,$opts) },
    } @modules;
    @matches = sort @matches;

    return $class->new({
        password => $password,
        matches => \@matches,
    });
}


# the following is a O($l_max * ($n + $m)) dynamic programming
# algorithm for a length-$n password with $m candidate matches. $l_max
# is the maximum optimal sequence length spanning each prefix of the
# password. In practice it rarely exceeds 5 and the search terminates
# rapidly.
#
# the optimal "minimum guesses" sequence is here defined to be the
# sequence that minimizes the following function:
#
#    $g = $l! * Product($_->guesses for $sequence) + $D^($l - 1)
#
# where $l is the length of the $sequence.
#
# the factorial term is the number of ways to order $l patterns.
#
# the $D^($l-1) term is another length penalty, roughly capturing the
# idea that an attacker will try lower-length sequences first before
# trying length-$l sequences.
#
# for example, consider a sequence that is date-repeat-dictionary.
#
#  - an attacker would need to try other date-repeat-dictionary
#    combinations, hence the product term.
#
#  - an attacker would need to try repeat-date-dictionary,
#    dictionary-repeat-date, ..., hence the factorial term.
#
#  - an attacker would also likely try length-1 (dictionary) and
#    length-2 (dictionary-date) sequences before length-3. assuming at
#    minimum $D guesses per pattern type, $D^($l-1) approximates
#    Sum($D**$_ for 1..$l-1)

my $MIN_GUESSES_BEFORE_GROWING_SEQUENCE = 10000;

sub most_guessable_match_list { ## no critic(ProhibitExcessComplexity)
    my ($self, $exclude_additive) = @_;

    my $password = $self->password;
    my $n = length($password);

    # partition matches into sublists according to ending index j
    my %matches_by_j;
    for my $match (@{$self->matches}) {
        push @{$matches_by_j{$match->j}},$match;
    }
    # small detail: for deterministic output, sort each sublist by i.
    for my $list (values %matches_by_j) {
        $list = [ sort {$a->i <=> $b->i} @{$list} ];
    }

    # $optimal{m}{$k}{$l} holds final match in the best length-$l
    # match sequence covering the password prefix up to $k, inclusive.
    # if there is no length-$l sequence that scores better (fewer
    # guesses) than a shorter match sequence spanning the same prefix,
    # this is undefined.
    #
    # $optimal{pi} has the same structure as $optimal{m} -- holds the
    # product term Prod(m.guesses for m in sequence). $optimal{pi}
    # allows for fast (non-looping) updates to the minimization
    # function.
    #
    # $optimal{g} again same structure, holds the overall metric
    my %optimal;

    # helper: considers whether a length-$length sequence ending at
    # $match is better (fewer guesses) than previously encountered
    # sequences, updating state if so.
    my $update = sub {
        my ($match,$length) = @_;

        my $k = $match->j;
        my $pi = $match->guesses_for_password($password);

        if ($length > 1) {
            # we're considering a length-$length sequence ending with
            # $match: obtain the product term in the minimization
            # function by multiplying $match->guesses by the product
            # of the length-($length-1) sequence ending just before
            # $match, at $match->i - 1
            $pi *= $optimal{pi}->{$match->i-1}{$length-1};
        }
        my $guesses = factorial($length) * $pi;
        $guesses += $MIN_GUESSES_BEFORE_GROWING_SEQUENCE ** ($length-1)
            unless $exclude_additive;

        # update state if new best. first see if any competing
        # sequences covering this prefix, with $length or fewer
        # matches, fare better than this sequence. if so, skip it and
        # return.
        for my $competing_length (keys %{$optimal{g}->{$k}}) {
            next if $competing_length > $length;
            my $competing_g = $optimal{g}->{$k}{$competing_length};
            next unless defined $competing_g;
            return if $competing_g <= $guesses;
        }

        $optimal{g}->{$k}{$length} = $guesses;
        $optimal{m}->{$k}{$length} = $match;
        $optimal{pi}->{$k}{$length} = $pi;
    };

    # helper: evaluate bruteforce matches ending at k.
    my $bruteforce_update = sub {
        my ($k) = @_;
        # see if a single bruteforce match spanning the k-prefix is optimal.
        my $match = Data::Password::zxcvbn::Match::BruteForce->new({
            password => $password,
            i => 0, j => $k,
        });
        $update->($match, 1);

        for my $i (1..$k) {
            # generate $k bruteforce matches, spanning from (i=1, j=$k) up to
            # (i=$k, j=$k). see if adding these new matches to any of the
            # sequences in $optimal{m}->[i-1] leads to new bests.
            my $other_match = Data::Password::zxcvbn::Match::BruteForce->new({
                password => $password,
                i => $i, j => $k,
            });

            for my $length (keys %{$optimal{m}->{$i-1}}) {
                my $last_match = $optimal{m}->{$i-1}{$length};

                # corner: an optimal sequence will never have two adjacent
                # bruteforce matches. it is strictly better to have a single
                # bruteforce match spanning the same region: same contribution
                # to the guess product with a lower length.
                # --> safe to skip those cases.
                next if $last_match->isa('Data::Password::zxcvbn::Match::BruteForce');
                # try adding m to this length-l sequence.
                $update->($other_match, $length + 1);
            }
        }
    };

    # helper: step backwards through optimal.m starting at the end,
    # constructing the final optimal match sequence.
    my $unwind = sub {
        my ($k) = @_;

        my @optimal_match_sequence;
        --$k;
        # find the final best sequence length and score
        my $length; my $guesses;
        for my $candidate_length (keys %{$optimal{g}->{$k}}) {
            my $candidate_guesses = $optimal{g}->{$k}{$candidate_length};
            if (!defined($guesses) || $candidate_guesses < $guesses) {
                $length = $candidate_length;
                $guesses = $candidate_guesses;
            }
        }

        while ($k >= 0) {
            my $match = $optimal{m}->{$k}{$length};
            unshift @optimal_match_sequence,$match;
            $k = $match->i - 1;
            --$length;
        }

        return \@optimal_match_sequence;
    };

    for my $k (0..$n-1) {
        for my $match (@{$matches_by_j{$k}}) {
            if ($match->i > 0) {
                for my $l (keys %{$optimal{m}->{$match->i - 1}}) {
                    $update->($match, $l+1);
                }
            }
            else {
                $update->($match,1);
            }
        }
        $bruteforce_update->($k);
    }

    my $optimal_match_sequence = $unwind->($n);
    my $optimal_length = @{$optimal_match_sequence};

    my $guesses;
    # corner: empty password
    if ($n==0) {
        $guesses = 1;
    }
    else {
        $guesses = $optimal{g}->{$n - 1}{$optimal_length};
    }

    return ref($self)->new({
        password => $password,
        guesses => $guesses,
        matches => $optimal_match_sequence,
    });
}


sub guesses_log10 {
    return log(shift->guesses)/log(10);
}


sub score { guesses_to_score(shift->guesses) }


sub get_feedback {
    my ($self, $max_score_for_feedback) = @_;
    # yes, if someone passes a 0, they'll get the default; I consider
    # this a feature
    $max_score_for_feedback ||= 2;

    my $matches = $self->matches;
    my $matches_count = @{$matches};

    if ($matches_count == 0) {
        return {
            warning => '',
            suggestions => [
                'Use a few words, avoid common phrases.',
                'No need for symbols, digits, or uppercase letters.',
            ],
        };
    }

    if ($self->score > $max_score_for_feedback) {
        return { warning => '', suggestions => [] };
    }

    my $longest_match = max_by { length($_->token) } @{$matches};
    my $is_sole_match = $matches_count == 1;
    my $feedback = $longest_match->get_feedback($is_sole_match);

    push @{$feedback->{suggestions}},
        'Add another word or two. Uncommon words are better.';
    $feedback->{warning} ||= '';

    return $feedback;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords JS

=head1 NAME

Data::Password::zxcvbn::MatchList - a collection of matches for a password

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

  use Data::Password::zxcvbn::MatchList;

  my $list = Data::Password::zxcvbn::MatchList->omnimatch($password)
              ->most_guessable_match_list;

=head1 DESCRIPTION

zxcvbn estimates the strength of a password by guessing which way a
generic password cracker would produce it, and then guessing after how
many tries it would produce it.

This class represents a list of guesses ("matches"), covering
different substrings of a password.

=head1 ATTRIBUTES

=head2 C<password>

Required string, the password this list is about.

=head2 C<matches>

Arrayref, the actual list of matches.

=head2 C<guesses>

The estimated number of attempts that a generic password cracker would
need to guess the whole L</password>. This will be set for objects
returned by L<< /C<most_guessable_match_list> >>, not for those
returned by L<< /C<omnimatch> >>.

=head1 METHODS

=head2 C<omnimatch>

  my $match_list = Data::Password::zxcvbn::MatchList->omnimatch($password,\%opts);

Main constructor (the name comes from the original JS
implementation). Calls C<< ->make($password,\%opts) >> on all the
C<Data::Password::zxcvbn::Match::*> classes (or the ones in C<<
@{$opts{modules}} >>), combines all the matches, and returns a
C<MatchList> holding them.

=head2 C<most_guessable_match_list>

  my $minimal_list = $match_list->most_guessable_match_list;

This method extracts, from the L</matches> of the invocant, a list of
non-overlapping matches with minimum guesses. That list should
represent the way that a generic password cracker would guess the
L</password>, and as such is the one that the L<main
function|Data::Password::zxcvbn/password_strength> will use.

=head2 C<guesses_log10>

The logarithm in base 10 of L<< /C<guesses> >>.

=head2 C<score>

  my $score = $match_list->score;

Returns an integer from 0-4 (useful for implementing a strength
bar). See L<<
C<Data::Password::zxcvbn::TimeEstimate::guesses_to_score>|Data::Password::zxcvbn::TimeEstimate/guesses_to_score
>>.

=head2 C<get_feedback>

  my %feedback = %{ $match_list->get_feedback };

Collects all the feedback from the L</matches>, and returns it.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
