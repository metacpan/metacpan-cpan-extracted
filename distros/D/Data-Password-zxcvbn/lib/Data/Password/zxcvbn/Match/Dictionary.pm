package Data::Password::zxcvbn::Match::Dictionary;
use Moo;
with 'Data::Password::zxcvbn::Match';
use Data::Password::zxcvbn::Combinatorics qw(nCk enumerate_substitution_maps);
use List::AllUtils qw(min);
our $VERSION = '1.1.2'; # VERSION
# ABSTRACT: match class for words in passwords


has reversed => (is => 'ro', default => 0);   # bool
has substitutions => ( is => 'ro', default => sub { +{} } );
has rank => ( is => 'ro', default => 1 ); # int
# this should be constrained to the keys of %ranked_dictionaries, but
# we can't do that because users can pass their own dictionaries to
# ->make
has dictionary_name => ( is => 'ro', default => 'passwords' );


sub l33t {
    return scalar(keys %{shift->substitutions})!=0;
}


our %l33t_table = ( ## no critic (ProhibitPackageVars)
  a => ['4', '@'],
  b => ['8'],
  c => ['(', '{', '[', '<'],
  e => ['3'],
  g => ['6', '9'],
  i => ['1', '!', '|'],
  l => ['1', '|', '7'],
  o => ['0'],
  s => ['$', '5'],
  t => ['+', '7'],
  x => ['%'],
  z => ['2'],
);

sub make {
    my ($class, $password, $opts) = @_;
    ## no critic (ProhibitPackageVars)
    my $dictionaries = $opts->{ranked_dictionaries}
        || do {
            require Data::Password::zxcvbn::RankedDictionaries;
            \%Data::Password::zxcvbn::RankedDictionaries::ranked_dictionaries;
        };
    my $l33t_table = $opts->{l33t_table} || \%l33t_table;

    my @matches;
    $class->_make_simple(\@matches,$password,$dictionaries);
    $class->_make_reversed(\@matches,$password,$dictionaries);
    $class->_make_l33t(\@matches,$password,$dictionaries, $l33t_table);

    @matches = sort @matches;
    return \@matches;
}

sub _make_simple {
    my ($class, $matches, $password, $dictionaries) = @_;
    my $password_lc = lc($password);
    # lc may change the length of the password...
    my $length = length($password_lc);

    for my $dictionary_name (keys %{$dictionaries}) {
        my $ranked_dict = $dictionaries->{$dictionary_name};
        for my $i (0..$length-1) {
            for my $j ($i..$length-1) {
                my $word = substr($password_lc,$i,$j-$i+1);
                if (my $rank = $ranked_dict->{$word}) {
                    push @{$matches}, $class->new({
                        token => substr($password,$i,$j-$i+1),
                        i => $i, j=> $j,
                        rank => $rank,
                        dictionary_name => $dictionary_name,
                    });
                }
            }
        }
    }
}

sub _make_reversed {
    my ($class, $matches, $password, $dictionaries) = @_;

    my $rev_password = reverse($password);
    my @rev_matches;
    $class->_make_simple(\@rev_matches,$rev_password,$dictionaries);

    my $rev_length = length($password)-1;
    for my $rev_match (@rev_matches) {
        my $word = $rev_match->token;
        # no need to add this, the normal matching will have produced
        # it already
        next if $word eq reverse($word);
        push @{$matches}, $class->new({
            token => reverse($word),
            i => $rev_length - $rev_match->j,
            j=> $rev_length - $rev_match->i,
            rank => $rev_match->rank,
            dictionary_name => $rev_match->dictionary_name,
            reversed => 1,
        });
    }
}

# makes a pruned copy of l33t_table that only includes password's
# possible substitutions
sub _relevant_l33t_subtable {
    my ($class, $password, $l33t_table) = @_;
    # set of characters
    my %password_chars; @password_chars{split //,$password} = ();

    my %subtable;
    for my $letter (keys %{$l33t_table}) {
        my @relevant_subs = grep { exists $password_chars{$_} }
            @{$l33t_table->{$letter}};
        $subtable{$letter} = \@relevant_subs
            if @relevant_subs;
    }

    return \%subtable;
}

sub _translate {
    my ($class, $string, $table) = @_;
    my $keys = join '', keys %{$table};
    $string =~ s{([\Q$keys\E])}
                {$table->{$1}}g;
    return $string;
}

sub _make_l33t {
    my ($class, $matches, $password, $dictionaries, $l33t_table) = @_;

    my $subs = enumerate_substitution_maps(
        $class->_relevant_l33t_subtable($password,$l33t_table)
    );
    for my $sub (@{$subs}) {
        next unless %{$sub};
        my $subbed_password = $class->_translate($password,$sub);
        my @subbed_matches;
        $class->_make_simple(\@subbed_matches,$subbed_password,$dictionaries);

        for my $subbed_match (@subbed_matches) {
            my $token = substr($password,
                               $subbed_match->i,
                               $subbed_match->j - $subbed_match->i + 1);
            # too short, ignore
            next if length($token) <= 1;
            # only return the matches that contain an actual substitution
            next if lc($token) eq lc($subbed_match->token);
            # subset of mappings in $sub that are in use for this match
            my %min_subs = map {
                $token =~ m{\Q$_}
                    ? ( $_ => $sub->{$_} )
                    : ()
            } keys %{$sub};
            push @{$matches}, $class->new({
                token => $token,
                substitutions => \%min_subs,
                i => $subbed_match->i,
                j=> $subbed_match->j,
                rank => $subbed_match->rank,
                dictionary_name => $subbed_match->dictionary_name,
            });
        }
    }
}


sub estimate_guesses {
    my ($self,$min_guesses) = @_;

    return $self->rank *
        $self->_uppercase_variations *
        $self->_l33t_variations *
        $self->_reversed_variations;
}


# an uppercase letter, followed by stuff that is *not* uppercase
# letters
my $START_UPPER_RE = qr{\A \p{Lu} \P{Lu}+ \z}x;
# stuff that is *not* uppercase letters, followed by an uppercase
# letter
my $END_UPPER_RE = qr{\A \P{Lu}+ \p{Lu} \z}x;
# no characters that are *not* uppercase letters
my $ALL_NOT_UPPER_RE = qr{\A \P{Lu}+ \z}x;
# no characters that are *not* lowercase letters
my $ALL_NOT_LOWER_RE = qr{\A \P{Ll}+ \z}x;


sub does_word_start_upper { return $_[1] =~ $START_UPPER_RE }
sub does_word_end_upper   { return $_[1] =~ $END_UPPER_RE }
sub is_word_all_not_upper { return $_[1] =~ $ALL_NOT_UPPER_RE }
sub is_word_all_not_lower { return $_[1] =~ $ALL_NOT_LOWER_RE }
sub is_word_all_upper { return $_[1] =~ $ALL_NOT_LOWER_RE && $_[1] ne lc($_[1]) }

sub _uppercase_variations {
    my ($self) = @_;

    my $word = $self->token;

    # if the word has no uppercase letters, count it as 1 variation
    return 1 if $word =~ $ALL_NOT_UPPER_RE;
    return 1 if lc($word) eq $word;

    # a capitalized word is the most common capitalization scheme, so
    # it only doubles the search space (uncapitalized + capitalized).
    # allcaps and end-capitalized are common enough too, underestimate
    # as 2x factor to be safe.
    return 2 if $word =~ $START_UPPER_RE;
    return 2 if $word =~ $END_UPPER_RE;
    return 2 if $word =~ $ALL_NOT_LOWER_RE;

    # otherwise calculate the number of ways to capitalize U+L
    # uppercase+lowercase letters with U uppercase letters or
    # less. or, if there's more uppercase than lower (for
    # eg. PASSwORD), the number of ways to lowercase U+L letters with
    # L lowercase letters or less.
    my $U = () = $word =~ m/\p{Lu}/g;
    my $L = () = $word =~ m/\p{Ll}/g;

    my $variations = 0;
    $variations += nCk($U+$L,$_) for 1..min($U,$L);
    return $variations;
}

sub _l33t_variations {
    my ($self) = @_;

    my $word = $self->token;

    my $variations = 1;
    for my $subbed (keys %{$self->substitutions}) {
        my $unsubbed = $self->substitutions->{$subbed};

        # number of Substituted characters
        my $S = () = $word =~ m{\Q$subbed}gi;
        # number of Unsubstituted characters
        my $U = () = $word =~ m{\Q$unsubbed}gi;

        if ($S==0 || $U==0) {
            # for this substitution, password is either fully subbed
            # (444) or fully unsubbed (aaa); treat that as doubling
            # the space (attacker needs to try fully subbed chars in
            # addition to unsubbed.)
            $variations *= 2;
        }
        else {
            # this case is similar to capitalization: with aa44a, U =
            # 3, S = 2, attacker needs to try unsubbed + one sub + two
            # subs
            my $possibilities = 0;
            $possibilities += nCk($U+$S,$_) for 1..min($U,$S);
            $variations *= $possibilities;
        }
    }

    return $variations;
}

sub _reversed_variations {
    return shift->reversed ? 2 : 1;
}


sub feedback_warning {
    my ($self, $is_sole_match) = @_;

    if ($self->dictionary_name eq 'passwords') {
        if ($is_sole_match && !$self->l33t && !$self->reversed) {
            if ($self->rank <= 10) {
                return 'This is a top-10 common password';
            }
            elsif ($self->rank <= 100) {
                return 'This is a top-100 common password';
            }
            else {
                return 'This is a very common password';
            }
        }
        elsif ($self->guesses_log10 <= 4) {
            return 'This is similar to a commonly used password';
        }
    }
    elsif ($self->dictionary_name =~ /names$/) {
        if ($is_sole_match) {
            return 'Names and surnames by themselves are easy to guess'
        }
        else {
            return 'Common names and surnames are easy to guess';
        }
    }
    elsif ($is_sole_match) {
        return 'A word by itself is easy to guess';
    }

    return undef;
}

sub feedback_suggestions {
    my ($self) = @_;

    my $word = $self->token;
    my @suggestions;

    if ($self->does_word_start_upper($word)) {
        push @suggestions, q{Capitalization doesn't help very much};
    }
    elsif ($self->is_word_all_upper($word)) {
        push @suggestions, 'All-uppercase is almost as easy to guess as all-lowercase';
    }

    if ($self->reversed && length($word) >= 4) {
        push @suggestions, q{Reversed words aren't much harder to guess};
    }

    if ($self->l33t) {
        push @suggestions, q{Predictable substitutions like '@' instead of 'a' don't help very much};
    }

    return \@suggestions;
}


around fields_for_json => sub {
    my ($orig,$self) = @_;
    ( $self->$orig(), qw(dictionary_name reversed rank substitutions) )
};

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Wiktionary xato

=head1 NAME

Data::Password::zxcvbn::Match::Dictionary - match class for words in passwords

=head1 VERSION

version 1.1.2

=head1 DESCRIPTION

This class represents the guess that a certain substring of a password
can be guessed by going through a dictionary.

=head1 ATTRIBUTES

=head2 C<reversed>

Boolean, true if the token appears to be a dictionary word that's been
reversed (i.e. last letter first)

=head2 C<substitutions>

Hashref representing the characters that need to be substituted to
make the token match a dictionary work (e.g. if the token is
C<s!mpl3>, this hash would be C<< { '!' => 'i', '3' => 'e' } >>).

=head2 C<rank>

Number, indicating how common the dictionary word is. 1 means "most
common".

=head2 C<dictionary_name>

String, the name of the dictionary that the word was found in. Usually one of:

=over 4

=item *

C<english_wikipedia>

words extracted from a dump of the English edition of Wikipedia

=item *

C<male_names>, C<female_names>, C<surnames>

common names from the 1990 US census

=item *

C<passwords>

most common passwords, extracted from the "xato" password dump

=item *

C<us_tv_and_film>

words from a 2006 Wiktionary word frequency study over American
television and movies

=back

=head1 METHODS

=head2 C<l33t>

Returns true if the token had any L</substitutions> (i.e. it was
written in "l33t-speak")

=head2 C<make>

  my @matches = @{ Data::Password::zxcvbn::Match::Dictionary->make(
    $password,
    { # these are the defaults
      ranked_dictionaries => \%Data::Password::zxcvbn::RankedDictionaries::ranked_dictionaries,
      l33t_table => \%Data::Password::zxcvbn::Match::Dictionary::l33t_table,
    },
  ) };

Scans the C<$password> for substrings that match words in the
C<ranked_dictionaries>, possibly reversed, possibly with substitutions
from the C<l33t_table>.

The C<ranked_dictionaries> should look like:

  { some_dictionary_name => { 'word' => 156, 'another' => 13, ... },
    ... }

(i.e. a hash of dictionaries, each mapping words to their frequency
rank) and the C<l33t_table> should look like:

  { a => [ '4', '@' ], ... }

(i.e. a hash mapping characters to arrays of other characters)

=head2 C<estimate_guesses>

The number of guesses is the product of the rank of the word, how many
case combinations match it, how many substitutions were used, doubled
if the token is reversed.

=head2 C<does_word_start_upper>

=head2 C<does_word_end_upper>

=head2 C<is_word_all_not_upper>

=head2 C<is_word_all_not_lower>

=head2 C<is_word_all_upper>

  if ($self->does_word_start_upper($word)) { ... }

These are mainly for sub-classes, to use in L<< /C<feedback_warning>
>> and L<< /C<feedback_suggestions> >>.

=head2 C<feedback_warning>

=head2 C<feedback_suggestions>

This class suggests not using common words or passwords, especially on
their own. It also suggests that capitalisation, "special characters"
substitutions, and writing things backwards are not very useful.

=head2 C<fields_for_json>

The JSON serialisation for matches of this class will contain C<token
i j guesses guesses_log10 dictionary_name reversed rank
substitutions>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
