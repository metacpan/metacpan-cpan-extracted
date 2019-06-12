package Data::Password::zxcvbn::Match;
use Moo::Role;
use Carp;
use List::AllUtils qw(max);
use overload
    '<=>' => \&compare,
    'cmp' => \&compare,
    bool => sub { 1 },
    ;
our $VERSION = '1.0.4'; # VERSION
# ABSTRACT: role for match objects


has token => (is => 'ro', required => 1);     # string
has [qw(i j)] => (is => 'ro', required => 1); # ints


sub compare {
    my ($self, $other) = @_;

    return $self->i <=> $other->i || $self->j <=> $other->j;
}


requires 'make';


has guesses => (is => 'lazy', builder => 'estimate_guesses');
requires 'estimate_guesses';


sub guesses_log10 {
    return log(shift->guesses)/log(10);
}

my $MIN_SUBMATCH_GUESSES_SINGLE_CHAR = 10;
my $MIN_SUBMATCH_GUESSES_MULTI_CHAR = 50;

# this is here only because ::BruteForce needs it
sub _min_guesses {
    my ($self) = @_;

    return length($self->token) == 1
        ? $MIN_SUBMATCH_GUESSES_SINGLE_CHAR
        : $MIN_SUBMATCH_GUESSES_MULTI_CHAR;
}


sub guesses_for_password {
    my ($self, $password) = @_;

    my $min_guesses = length($self->token) < length($password)
        ? $self->_min_guesses()
        : 1;
    my $guesses = $self->guesses();
    return max($min_guesses,$guesses);
}


sub get_feedback {
    my ($self, $is_sole_match) = @_;

    return {
        warning => $self->feedback_warning($is_sole_match),
        suggestions => $self->feedback_suggestions($is_sole_match),
    };
}

requires 'feedback_warning', 'feedback_suggestions';


sub fields_for_json { qw(token i j guesses guesses_log10) }
sub TO_JSON {
    my ($self) = @_;
    return {
        class => ref($self),
        map { $_ => $self->$_ } $self->fields_for_json,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::Match - role for match objects

=head1 VERSION

version 1.0.4

=head1 SYNOPSIS

  package My::Password::Match::Something;
  use Moo;
  with 'Data::Password::zxcvbn::Match';

  has some_info => (is=>'ro');

  sub make {
    my ($class, $password) = @_;
    return [ $class->new({
      token => some_substring_of($password),
      i => position_of_first_char($token,$password),
      j => position_of_last_char($token,$password),
      some_info => whatever_needed(),
    }) ];
  }

  sub estimate_guesses {
    my ($self) = @_;
    return $self->some_complexity_estimate();
  }

  sub feedback_warning { 'this is a bad idea' }
  sub feedback_suggestions { return [ 'do something else' ] }

  1;

=head1 DESCRIPTION

zxcvbn estimates the strength of a password by guessing which way a
generic password cracker would produce it, and then guessing after how
many tries it would produce it.

This role provides the basic behaviour and interface for the classes
that implement that guessing.

=head1 ATTRIBUTES

=head2 C<token>

Required string: the portion of the password that this object
matches. For example, if your class represents "sequences of digits",
an instance L<made|/make> from the password C<abc1234def> would have
C<< token => '1234' >>.

=head2 C<i>, C<j>

Required integers: the indices of the first and last character of
L</token> in the password. For the example above, we would have C<< i
=> 3, j => 6 >>.

=head2 C<guesses>

The estimated number of attempts that a generic password cracker would
need to guess the particular L</token>. The value for this attribute
is generated on demand by calling L<< /C<estimate_guesses> >>.

=head1 REQUIRED METHODS

=head2 C<make>

  sub make {
    my ($class, $password) = @_;
    return [ $class->new(\%something), ... ];
  }

This factory method should return a I<sorted> arrayref of instances,
one for each substring of the C<$password> that could be generated /
guessed with the logic that your class represents.

=head2 C<estimate_guesses>

  sub estimate_guesses {
    my ($self) = @_;
    return $self->some_complexity_estimate();
  }

This method should return an integer, representing an estimate of the
number of attempts that a generic password cracker would need to guess
the particular L</token> I<within the logic that your class
represents>. For example, if your class represents "sequences of
digits", you could hypothesise that the cracker would go in order from
1, so you'd write:

  sub estimate_guesses { return 0 + shift->token }

=head2 C<feedback_warning>

This method should return a string (possibly empty), or an arrayref
C<[$string,@values]> suitable for localisation. The returned value
should explain what's wrong, e.g. 'this is a top-10 common password'.

=head2 C<feedback_suggestions>

This method should return a possibly-empty array of suggestions to
help choose a less guessable password. e.g. 'Add another word or two';
again, elements can be strings or arrayrefs for localisation.

=head1 METHODS

=head2 C<compare>

  $match1 <=> $match2
  $match1 cmp $match2

The comparison operators are overloaded to sort by L<< /C<i> >> and
L<< /C<j> >>, so a sorted list of matches will cover the password from
left to right.

=head2 C<guesses_log10>

The logarithm in base 10 of L<< /C<guesses> >>.

=head2 C<guesses_for_password>

  my $guesses = $match->guesses_for_password($password);

This method will return the same value as L<< /C<guesses> >>, or some
minimum number of guesses, whichever is higher.

This is to make sure that all match have a measurable impact on the
estimation of the total complexity.

=head2 C<get_feedback>

  my %feedback = %{ $match->get_feedback($is_sole_match) };

Returns a hashref, with verbal feedback to help choose better
passwords. The hash contains:

=over 4

=item *

C<warning>

string (or arrayref for localisation), produced by calling L<<
/C<feedback_warning> >>

=item *

C<suggestions>

arrayref of strings (or arrayrefs for localisation), produced by
calling L<< /C<feedback_suggestions> >>.

=back

=head2 C<TO_JSON>

=head2 C<fields_for_json>

Matches can be serialised to JSON. The serialisation will be a
dictionary with all the fields returned by L<< /C<fields_for_json>
>>. By default, it will contain C<token i j guesses guesses_log10>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
