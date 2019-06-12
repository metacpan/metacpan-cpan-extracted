package Data::Password::zxcvbn::Match::Date;
use Moo;
with 'Data::Password::zxcvbn::Match';
use List::AllUtils 0.14 qw(max min_by);
our $VERSION = '1.0.4'; # VERSION
# ABSTRACT: match class for digit sequences that look like dates


my $MIN_YEAR_SPACE = 20;
my $REFERENCE_YEAR = 2017;

has year => ( is => 'ro', required => 1 );
has separator => ( is => 'ro', default => '' );


sub estimate_guesses {
    my ($self, $min_guesses) = @_;

    # base guesses: (year distance from REFERENCE_YEAR) * num_days * num_years
    my $year_space = max(abs($self->year - $REFERENCE_YEAR),$MIN_YEAR_SPACE);
    my $guesses = $year_space * 365;
    # add factor of 4 for separator selection (one of ~4 choices)
    $guesses *=4 if $self->separator;

    return $guesses;
}


my $MAYBE_DATE_NO_SEP_RE = qr{\A ([0-9]{4,8}) \z}x;
my $MAYBE_DATE_WITH_SEP_RE = qr{\A ([0-9]{1,4}) ([\s/\\_.-]) ([0-9]{1,2}) \2 ([0-9]{1,4}) \z}x;
my $MAX_YEAR = 2050;
my $MIN_YEAR = 1000;
my %SPLITS = (
    4 => [  # for length-4 strings, eg 1191 or 9111, two ways to split:
        [1, 2],  # 1 1 91 (2nd split starts at index 1, 3rd at index 2)
        [2, 3],  # 91 1 1
    ],
    5 => [
        [1, 3],  # 1 11 91
        [2, 3],  # 11 1 91
    ],
    6 => [
        [1, 2],  # 1 1 1991
        [2, 4],  # 11 11 91
        [4, 5],  # 1991 1 1
    ],
    7 => [
        [1, 3],  # 1 11 1991
        [2, 3],  # 11 1 1991
        [4, 5],  # 1991 1 11
        [4, 6],  # 1991 11 1
    ],
    8 => [
        [2, 4],  # 11 11 1991
        [4, 6],  # 1991 11 11
    ],
);

sub make {
    my ($class, $password) = @_;
    # a "date" is recognized as:
    # * any 3-tuple that starts or ends with a 2- or 4-digit year,
    # * with 2 or 0 separator chars (1.1.91 or 1191),
    # * maybe zero-padded (01-01-91 vs 1-1-91),
    # * a month between 1 and 12,
    # * a day between 1 and 31.
    #
    # note: this isn't true date parsing in that "feb 31st" is allowed,
    # this doesn't check for leap years, etc.
    #
    # recipe:
    #
    # start with regex to find maybe-dates, then attempt to map the
    # integers onto month-day-year to filter the maybe-dates into
    # dates.
    #
    # finally, remove matches that are substrings of other matches to
    # reduce noise.
    #
    # note: instead of using a lazy or greedy regex to find many dates
    # over the full string, this uses a ^...$ regex against every
    # substring of the password -- less performant but leads to every
    # possible date match.

    my $length = length($password);
    # dates without separators are between length 4 '1191' and 8 '11111991'
    return [] if $length < 4;

    my @matches;

    for my $i (0..$length-3) {
        for my $j ($i+3 .. $i+8) {
            last if $j >= $length;

            my $token = substr($password,$i,$j-$i+1);
            next unless $token =~ $MAYBE_DATE_NO_SEP_RE;

            my @candidates;
            for my $split (@{ $SPLITS{length($token)} || [] }) {
                my ($k,$l) = @{$split};

                my $year = $class->_map_ints_to_year(
                    substr($token,0,$k),
                    substr($token,$k,$l-$k),
                    substr($token,$l),
                ) or next;

                push @candidates,$year;
            }
            next unless @candidates;

            # at this point: different possible year mappings for the
            # same i,j substring. match the candidate date that likely
            # takes the fewest guesses: a year closest to
            # 2017. ($REFERENCE_YEAR).
            #
            # ie, considering '111504', prefer 11-15-04 to 1-1-1504
            # (interpreting '04' as 2004)
            my $best_candidate = min_by { abs($_ - $REFERENCE_YEAR) } @candidates;
            push @matches, $class->new({
                token => $token,
                i => $i, j => $j,
                separator => '',
                year => $best_candidate,
            });
        }
    }

    # dates with separators are between length 6 '1/1/91' and 10 '11/11/1991'
    for my $i (0..$length-5) {
        for my $j ($i+5 .. $i+10) {
            last if $j >= $length;

            my $token = substr($password,$i,$j-$i+1);
            my @pieces = $token =~ $MAYBE_DATE_WITH_SEP_RE
                or next;

            my $year = $class->_map_ints_to_year(
                $pieces[0],
                $pieces[2],
                $pieces[3]
            ) or next;

            push @matches, $class->new({
                token => $token,
                i => $i, j => $j,
                separator => $pieces[1],
                year => $year,
            });
        }
    }

    # matches now contains all valid date strings in a way that is
    # tricky to capture with regexes only. while thorough, it will
    # contain some unintuitive noise:
    #
    # '2015_06_04', in addition to matching 2015_06_04, will also
    # contain 5(!) other date matches: 15_06_04, 5_06_04, ..., even
    # 2015 (matched as 5/1/2020)
    #
    # to reduce noise, remove date matches that are strict substrings
    # of others

    @matches = grep {
        my $match = $_;
        my $is_submatch = grep {
            $_ == $match
                ? 0
                : $_->i <= $match->i && $_->j >= $match->j
                ? 1
                : 0
            } @matches;
        !$is_submatch;
    } @matches;

    @matches = sort @matches;
    return \@matches;
}

sub _map_ints_to_year {
    my ($class,@ints) = @_;

    ## no critic (ProhibitBooleanGrep)

    # given a 3-tuple, discard if:
    #   middle int is over 31 (for all dmy formats, years are never allowed in
    #   the middle)
    #   middle int is zero
    return undef if $ints[1] > 31 or $ints[1] <= 0;
    #   any int is over the max allowable year
    #   any int is over two digits but under the min allowable year
    return undef if grep { $_ > $MAX_YEAR ||
                               ( $_ > 99 && $_ < $MIN_YEAR ) } @ints;
    #   2 ints are over 31, the max allowable day
    return undef if grep { $_ > 31 } @ints >= 2;
    #   2 ints are zero
    return undef if grep { $_ == 0 } @ints >= 2;
    #   all ints are over 12, the max allowable month
    return undef if grep { $_ > 12 } @ints == 3;

    # first look for a four digit year: yyyy + daymonth or daymonth + yyyy
    my @possible_four_digit_splits = (
        [ $ints[2], $ints[0], $ints[1] ],
        [ $ints[0], $ints[1], $ints[2] ],
    );
    for my $split (@possible_four_digit_splits) {
        my ($year,@rest) = @{$split};
        if ( $year >= $MIN_YEAR && $year <= $MAX_YEAR) {
            # for a candidate that includes a four-digit year,
            # when the remaining ints don't match to a day and month,
            # it is not a date.
            if ($class->_map_ints_to_dm(@rest)) {
                return $year;
            }
            else {
                return undef;
            }
        }
    }

    # given no four-digit year, two digit years are the most flexible
    # int to match, so try to parse a day-month out of @ints[0,1] or
    # @ints[1,0]
    for my $split (@possible_four_digit_splits) {
        my ($year,@rest) = @{$split};
        if ($class->_map_ints_to_dm(@rest)) {
            $year = $class->_two_to_four_digit_year($year);
            return $year;
        }
    }

    return undef;
}

sub _map_ints_to_dm {
    my ($class,@ints) = @_;
    for my $case ([@ints],[reverse @ints]) {
        my ($d,$m) = @{$case};
        if ( $d >= 1 && $d <= 31 && $m >= 1 && $m <= 12) {
            return 1
        }
    }
    return undef;
}

sub _two_to_four_digit_year {
    my ($class, $year) = @_;
    return $year if $year > 99;
    return 1900 + $year if $year > 50;
    return 2000 + $year;
}


sub feedback_warning {
    my ($self) = @_;

    return 'Dates are often easy to guess';
}

sub feedback_suggestions {
    return [ 'Avoid dates and years that are associated with you' ];
}


around fields_for_json => sub {
    my ($orig,$self) = @_;
    ( $self->$orig(), qw(year separator) )
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::Match::Date - match class for digit sequences that look like dates

=head1 VERSION

version 1.0.4

=head1 DESCRIPTION

This class represents the guess that a certain substring of a
password, consisting of digits and maybe separators, can be guessed by
scanning dates in the recent past (like birthdays, or recent events).

=head1 ATTRIBUTES

=head2 C<year>

Integer, the year extracted from the token.

=head2 C<separator>

String, possibly empty: the separator used between digits in the
token.

=head1 METHODS

=head2 C<estimate_guesses>

The number of guesses is the number of days between the extracted
L</year> and a reference year (currently 2017), multiplied by the
possible separators.

=head2 C<make>

  my @matches = @{ Data::Password::zxcvbn::Match::Date->make(
    $password,
  ) };

Scans the C<$password> for sequences of digits and separators that
look like dates. Some examples:

=over 4

=item *

1/1/91

=item *

1191

=item *

1991-01-01

=item *

910101

=back

=head2 C<feedback_warning>

=head2 C<feedback_suggestions>

This class suggests not using dates.

=head2 C<fields_for_json>

The JSON serialisation for matches of this class will contain C<token
i j guesses guesses_log10 year separator>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
