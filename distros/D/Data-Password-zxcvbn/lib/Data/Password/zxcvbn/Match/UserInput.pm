package Data::Password::zxcvbn::Match::UserInput;
use Moo;
extends 'Data::Password::zxcvbn::Match::Dictionary';
our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: match class for words that match other user-supplied information


# a somewhat general word boundary: the spot between a letter and a
# non-letter, or a digit and a non-digit; we don't care about
# beginning or end of string, because we're going to use this only in
# a split
my $WORD_BOUNDARY_RE = qr{
                             (?: (?<=\p{L})(?=\P{L}) ) |
                             (?: (?<=\P{L})(?=\p{L}) ) |
                             (?: (?<=\d)(?=\D) ) |
                             (?: (?<=\D)(?=\d) )
                     }x;


sub make {
    my ($class, $password, $opts) = @_;
    my $user_input = $opts->{user_input};
    return [] unless $user_input && %{$user_input};

    # we build one "dictionary" per input field, so we can distinguish
    # them when providing feedback
    my %user_dicts;
    for my $field (keys %{$user_input}) {
        my $value = $user_input->{$field};
        if (my @words = grep {length>2} split $WORD_BOUNDARY_RE, $value) {
            # all words have rank 1, they're the first thing that a
            # cracker would try
            $user_dicts{$field} = {
                map { lc($_) => 1 } @words, ## no critic(ProhibitUselessTopic)
            };
        }
    }

    return $class->next::method(
        $password,
        {
            ranked_dictionaries => \%user_dicts,
            l33t_table => $opts->{l33t_table},
        },
    );
}


sub feedback_warning {
    my ($self, $is_sole_match) = @_;

    if ($is_sole_match && !$self->l33t && !$self->reversed) {
        return [
            'The value of the [_1] field is easy to guess',
            $self->dictionary_name,
        ];
    }
    elsif ($self->guesses_log10 <= 4) {
        return [
            'This is similar to the value of the [_1] field',
            $self->dictionary_name,
        ];
    }
    return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::Match::UserInput - match class for words that match other user-supplied information

=head1 VERSION

version 1.0.2

=head1 DESCRIPTION

This class represents the guess that a certain substring of a password
can be guessed by using other pieces of information related to the
user: their account name, real name, location, &c.

This is a subclass of L<< C<Data::Password::zxcvbn::Match::Dictionary>
>>.

=head1 METHODS

=head2 C<make>

  my @matches = @{ Data::Password::zxcvbn::Match::UserInput->make(
    $password,
    {
      user_input => \%user_input,
      # this is the default
      l33t_table => \%Data::Password::zxcvbn::Match::Dictionary::l33t_table,
    },
  ) };

The C<%user_input> hash should be a simple hash mapping field names to
strings. It will be converted into a set of dictionaries, one per key,
containing words extracted from the strings. For example

 { name => 'Some One', address => '123 Place Street' }

will become:

 { name => { Some => 1, One => 1 },
   address => { 123 => 1, Place => 1, Street => 1 } }

All words get rank 1 because they're obvious guesses from a cracker's
point of view.

The rest of the logic is the same as for L<<
C<Dictionary>|Data::Password::zxcvbn::Match::Dictionary/make >>.

=head2 C<feedback_warning>

The warnings for this class are very similar to those for
C<Dictionary>, but they explicitly mention the field name. Warnings
look like:

 ['The value of the [_1] field is easy to guess','address']

so your localisation library can translate the warning and the field
name separately.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
