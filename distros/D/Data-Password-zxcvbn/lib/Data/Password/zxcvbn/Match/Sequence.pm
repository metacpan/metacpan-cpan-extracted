package Data::Password::zxcvbn::Match::Sequence;
use Moo;
with 'Data::Password::zxcvbn::Match';
our $VERSION = '1.0.3'; # VERSION
# ABSTRACT: match class for sequences of uniformly-spaced codepoints


has ascending => (is => 'ro', default => 1);


sub estimate_guesses {
    my ($self,$min_guesses) = @_;

    my $first_char = substr($self->token,0,1);

    my $guesses;
    # lower guesses for obvious starting points
    if ($first_char =~ m{[aAzZ019]}) {
        $guesses = 4;
    }
    elsif ($first_char =~ m{[0-9]}) {
        $guesses = 10; # digits
    }
    else {
        # could give a higher base for uppercase, assigning 26 to both
        # upper and lower sequences is more conservative.
        $guesses = 26;
    }

    $guesses *= 2 unless $self->ascending;

    return $guesses * length($self->token);
}


sub feedback_warning {
    my ($self) = @_;

    return 'Sequences like abc or 6543 are easy to guess';
}

sub feedback_suggestions {
    return [ 'Avoid sequences' ];
}


my $MAX_DELTA = 5;

sub make {
    my ($class, $password) = @_;
    # Identifies sequences by looking for repeated differences in
    # unicode codepoint.  this allows skipping, such as 9753, and also
    # matches some extended unicode sequences such as Greek and
    # Cyrillic alphabets.
    #
    # for example, consider the input 'abcdb975zy'
    #
    # password: a   b   c   d   b    9   7   5   z   y
    # index:    0   1   2   3   4    5   6   7   8   9
    # delta:      1   1   1  -2  -41  -2  -2  69   1
    #
    # expected result:
    # [(i, j, delta), ...] = [(0, 3, 1), (5, 7, -2), (8, 9, 1)]

    my $length = length($password);
    return [] if $length <= 1;

    my @matches;

    my $update = sub {
        my ($i,$j,$delta) = @_;
        my $abs_delta = abs($delta||0);
        return unless $j-$i>1 or $abs_delta == 1;
        return if $abs_delta == 0;
        return if $abs_delta > $MAX_DELTA;

        my $token = substr($password,$i,$j-$i+1);
        push @matches, $class->new({
            token => $token,
            i => $i, j => $j,
            ascending => !!($delta>0),
        });
    };

    my $i=0;
    my $last_delta;
    for my $k (1..$length-1) {
        my $delta = ord(substr($password,$k,1)) - ord(substr($password,$k-1,1));
        $last_delta = $delta unless defined($last_delta);
        next if $delta == $last_delta;
        my $j = $k-1;
        $update->($i,$j,$last_delta);
        $i = $j; $last_delta = $delta;
    }
    $update->($i,$length-1,$last_delta);

    return \@matches;
}


around fields_for_json => sub {
    my ($orig,$self) = @_;
    ( $self->$orig(), qw(ascending) )
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::Match::Sequence - match class for sequences of uniformly-spaced codepoints

=head1 VERSION

version 1.0.3

=head1 DESCRIPTION

This class represents the guess that a certain substring of a
password, consisting of uniformly-spaced codepoints, is easy to guess.

=head1 ATTRIBUTES

=head2 C<ascending>

Boolean, true if the sequence starts at a lower codepoint and ends at
a higher one (e.g. C<acegi> is ascending, C<86420> is not).

=head1 METHODS

=head2 C<estimate_guesses>

The number of guesses is I<linear> with the length of the
sequence. Descending sequences get a higher estimate, sequences that
start at obvious points (e.g. C<A> or C<1>) get lower estimates.

=head2 C<feedback_warning>

=head2 C<feedback_suggestions>

This class suggests not using sequences.

=head2 C<make>

  my @matches = @{ Data::Password::zxcvbn::Match::Sequence->make(
    $password,
  ) };

Scans the C<$password> for sequences of characters whose codepoints
increase or decrease by a constant.

=head2 C<fields_for_json>

The JSON serialisation for matches of this class will contain C<token
i j guesses guesses_log10 ascending>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
