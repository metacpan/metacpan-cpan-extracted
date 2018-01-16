package Data::Password::zxcvbn::Match::Repeat;
use Moo;
with 'Data::Password::zxcvbn::Match';
our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: match class for repetitions of other matches


has repeat_count => (is => 'ro', default => 1);
has base_token => ( is => 'ro', required => 1 );
has base_guesses => ( is => 'ro', default => 1 );
has base_matches => ( is => 'ro', default => sub { [] } );

my $GREEDY_RE = qr{\G.*? ((.+) \2+)}x;
my $LAZY_RE = qr{\G.*? ((.+?) \2+)}x;
my $LAZY_ANCHORED_RE = qr{\A ((.+?) \2+) \z}x;


sub make {
    my ($class, $password, $opts) = @_;

    my $length = length($password);
    return [] if $length <= 1;

    my @matches;
    my $last_index = 0;
    while ($last_index < $length) {
        # make the regex matches start at $last_index
        pos($password) = $last_index;
        my @greedy_match = $password =~ $GREEDY_RE
            or last;
        my @greedy_idx = ($-[1],$+[1]-1);

        pos($password) = $last_index;
        my @lazy_match = $password =~ $LAZY_RE;
        my @lazy_idx = ($-[1],$+[1]-1);

        my (@token,$i,$j);
        if (length($greedy_match[0]) > length($lazy_match[0])) {
            # greedy beats lazy for 'aabaab'
            #   greedy: [aabaab, aab]
            #   lazy:   [aa,     a]
            ($i,$j) = @greedy_idx;
            # greedy's repeated string might itself be repeated, eg.
            # aabaab in aabaabaabaab.
            # run an anchored lazy match on greedy's repeated string
            # to find the shortest repeated string
            @token = $greedy_match[0] =~ $LAZY_ANCHORED_RE;
        }
        else {
            ($i,$j) = @lazy_idx;
            @token = @lazy_match;
        }

        require Data::Password::zxcvbn::MatchList;
        my $base_analysis = Data::Password::zxcvbn::MatchList->omnimatch(
            $token[1],
            $opts,
        )->most_guessable_match_list;

        push @matches, $class->new({
            i => $i, j => $j,
            token => $token[0],
            base_token => $token[1],
            repeat_count => length($token[0]) / length($token[1]),
            base_guesses => $base_analysis->guesses,
            base_matches => $base_analysis->matches,
        });

        $last_index = $j + 1;
    }

    return \@matches;
}


sub estimate_guesses {
    my ($self) = @_;

    return $self->base_guesses * $self->repeat_count;
}


sub feedback_warning {
    my ($self) = @_;

    return length($self->base_token) == 1
        ? 'Repeats like "aaa" are easy to guess'
        : 'Repeats like "abcabcabc" are only slightly harder to guess than "abc"'
        ;
}

sub feedback_suggestions {
    return [ 'Avoid repeated words and characters' ];
}


around fields_for_json => sub {
    my ($orig,$self) = @_;
    ( $self->$orig(), qw(repeat_count base_guesses base_token base_matches) )
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::Match::Repeat - match class for repetitions of other matches

=head1 VERSION

version 1.0.2

=head1 DESCRIPTION

This class represents the guess that a certain substring of a password
is a repetition of some other kind of match.

=head1 ATTRIBUTES

=head2 C<repeat_count>

integer, how many time the L<< /C<base_token> >> is repeated

=head2 C<base_token>

the match that is repeated; this will be an instance of some other
C<Data::Password::zxcvbn::Match::*> class

=head2 C<base_guesses>

the minimal estimate of the attempts needed to guess the L<<
/C<base_token> >>

=head2 C<base_matches>

the list of patterns that L<< /C<base_guesses> >> is based on

=head1 METHODS

=head2 C<make>

  my @matches = @{ Data::Password::zxcvbn::Match::Repeat->make(
    $password, \%opts,
  ) };

Scans the C<$password> for repeated substrings, then recursively
analyses them like the main L<< C<password_strength>
function|Data::Password::zxcvbn/password_strength >> would do:

  password_strength($substring,\%opts);

L<< /C<base_guesses> >> and L<< /C<base_matches> >> come from that
recursive call.

=head2 C<estimate_guesses>

The number of guesses is the L<< /C<base_guesses> >> times the L<<
/C<repeat_count> >>.

=head2 C<feedback_warning>

=head2 C<feedback_suggestions>

This class suggests not to repeat substrings.

=head2 C<fields_for_json>

The JSON serialisation for matches of this class will contain C<token
i j guesses guesses_log10 repeat_count base_guesses base_token
base_matches>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
