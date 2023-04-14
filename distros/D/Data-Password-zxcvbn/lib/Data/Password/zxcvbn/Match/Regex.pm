package Data::Password::zxcvbn::Match::Regex;
use Moo;
with 'Data::Password::zxcvbn::Match';
use List::AllUtils qw(max);
our $VERSION = '1.1.2'; # VERSION
# ABSTRACT: match class for recognisable patterns in passwords


our %regexes_limited = ( ## no critic (ProhibitPackageVars)
    recent_year => [qr{(19\d\d|200\d|201\d)},-1],
);
our %regexes = ( ## no critic (ProhibitPackageVars)
    alpha_lower => [qr{(\p{Ll}+)},26],
    alpha_upper => [qr{(\p{Lu}+)},26],
    alpha => [qr{(\p{L}+)},52],
    # Nd means "decimal number", let's ignore the other kind of numbers
    digits => [qr{(\p{Nd}+)},10],
    alphanumeric => [qr{( (?: (?: \p{L}+\p{Nd}+ )+\p{L}* ) | (?: (?: \p{Nd}+\p{L}+ )+\p{Nd}* ))},62],
    # marks, punctuation, symbols
    symbols => [qr{((?:\p{M}|\p{P}|\p{S})+)},33],
    %regexes_limited,
);

# this should be constrained to the keys of %regexes, but we can't do
# that because users can pass their own regexes to ->make
has regex_name => ( is => 'ro', default => 'alphanumeric' );

has regexes => ( is => 'ro', default => sub { \%regexes } );


sub make {
    my ($class, $password, $opts) = @_;

    my $regexes = $opts->{regexes} || \%regexes_limited;
    # the normal zxcvbn implementation only uses recent_year, we may
    # want to have all of them
    if ($regexes eq 'all') {
        $regexes = \%regexes;
    }

    my @matches;
    for my $regex_name (keys %{$regexes}) {
        my $regex = $regexes->{$regex_name}[0];
        # reset the match position
        pos($password)=0;
        while ($password =~ m{$regex}gc) {
            push @matches, $class->new({
                token => $1,
                # @- and @+ hold the begin/end index of matches
                i => $-[1], j => $+[1]-1,
                regex_name => $regex_name,
                regexes => $regexes,
            });
        }
    }

    @matches = sort @matches;
    return \@matches;
}


my $MIN_YEAR_SPACE = 20;
my $REFERENCE_YEAR = 2017;

sub estimate_guesses {
    my ($self,$min_guesses) = @_;

    my $regex = $self->regex_name;
    if ($regex eq 'recent_year') {
        return max(
            abs($self->token - $REFERENCE_YEAR),
            $MIN_YEAR_SPACE,
        );
    }
    else {
        return $self->regexes->{$self->regex_name}[1] ** length($self->token);
    }
}


sub feedback_warning {
    my ($self) = @_;

    return $self->regex_name eq 'recent_year'
        ? 'Recent years are easy to guess'
        : undef
        ;
}

sub feedback_suggestions {
    my ($self) = @_;

    return [
        $self->regex_name eq 'recent_year'
            ? ( 'Avoid recent years',
                'Avoid years that are associated with you' )
            : (),
    ];
}


around fields_for_json => sub {
    my ($orig,$self) = @_;
    ( $self->$orig(), qw(regex_name) )
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::Match::Regex - match class for recognisable patterns in passwords

=head1 VERSION

version 1.1.2

=head1 DESCRIPTION

This class represents the guess that a certain substring of a password
can be guessed by enumerating small languages described by regular
expressions. By default, the only regex used is one that matches
recent years (yes, this is very similar to what L<<
C<Date>|Data::Password::zxcvbn::Match::Date >> does).

=head1 ATTRIBUTES

=head2 C<regexes>

Hashref, the regular expressions that were tried to get this
match. The values are arrayrefs with 2 elements: the regex itself, and
the estimated number of guesses per character; for example:

  digits => [ qr[(\p{Nd}+)], 10 ],

=head2 C<regex_name>

The name of the regex that matched the token.

=head1 METHODS

=head2 C<make>

  my @matches = @{ Data::Password::zxcvbn::Match::Regex->make(
    $password,
    { # this is the default
      regexes => \%Data::Password::zxcvbn::Match::Regex::regexes_limited,
    },
  ) };

Scans the C<$password> for substrings that match regexes in
C<regexes>.

By default, the only regex that's used is one that matches recent
years expressed as 4 digits. More patterns are available as
C<\%Data::Password::zxcvbn::Match::Regex::regexes> (which you can also
get if you say C<< regexes => 'all' >>), or you can pass in your own
hashref.

=head2 C<estimate_guesses>

For the C<recent_year> regex, the number of guesses is the number of
years between the value represented by the token and a reference year
(currently 2017).

For all other regexes, the number of guesses is exponential on the
length of the token, using as base the second element of the matching
pattern (i.e. C<< $self->regexes->{$self->regex_name}[1] >>).

=head2 C<feedback_warning>

=head2 C<feedback_suggestions>

This class suggests not using recent years. At the moment, there's no
feedback for other regexes.

=head2 C<fields_for_json>

The JSON serialisation for matches of this class will contain C<token
i j guesses guesses_log10 regex_name>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
