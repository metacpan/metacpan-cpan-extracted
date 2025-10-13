package Data::Password::zxcvbn;
use strict;
use warnings;
use Module::Runtime qw(use_module);
use Data::Password::zxcvbn::MatchList;
use Data::Password::zxcvbn::TimeEstimate qw(estimate_attack_times);
use Exporter 'import';
our @EXPORT_OK=qw(password_strength);
our $VERSION = '1.1.3'; # VERSION
# ABSTRACT: Dropbox's password estimation logic


sub password_strength {
    my ($password, $opts) = @_;

    my $match_list_module = $opts->{match_list_module}
        || 'Data::Password::zxcvbn::MatchList';
    my $matches = use_module($match_list_module)->omnimatch(
        $password, {
            user_input => $opts->{user_input},
            regexes => $opts->{regexes},
            ranked_dictionaries => $opts->{ranked_dictionaries},
            l33t_table => $opts->{l33t_table},
            graphs => $opts->{graphs},
            modules => $opts->{modules},
        },
    );
    my $most_guessable = $matches->most_guessable_match_list();
    my $attack_times = estimate_attack_times($most_guessable->guesses);
    my $feedback = $most_guessable->get_feedback(
        $opts->{max_score_for_feedback},
    );

    return {
        score => $most_guessable->score,
        matches => $most_guessable->matches,
        guesses => $most_guessable->guesses,
        guesses_log10 => $most_guessable->guesses_log10,
        feedback => {
            warning => $feedback->{warning} || '',
            suggestions => $feedback->{suggestions} || [],
        },
        crack_times_seconds => $attack_times->{crack_times_seconds} || {},
        crack_times_display => $attack_times->{crack_times_display} || {},
    };
}


1;

__END__

=pod

=encoding UTF-8

=for :stopwords PBKDF2 scrypt bcrypt un

=head1 NAME

Data::Password::zxcvbn - Dropbox's password estimation logic

=head1 VERSION

version 1.1.3

=head1 SYNOPSIS

  use Data::Password::zxcvbn qw(password_strength);

  my $strength = password_strength($my_password);
  warn $strength->{warning} if $strength->{score} < 3;

=head1 DESCRIPTION

This is a Perl port of Dropbox's password strength estimation library,
L<< C<zxcvbn>|https://github.com/dropbox/zxcvbn >>.

The code layout has been reworked to be generally nicer (e.g. we use
classes instead of dispatch tables, all data structures are immutable)
and to pre-compute more (e.g. the dictionaries are completely
pre-built, instead of being partially computed at run time).

The code has been tested against the L<Python
port's|https://github.com/dwolfhub/zxcvbn-python>
F<password_expected_value.json> test. When the dictionaries contain
exactly the same data (including some words that are loaded wrongly by
the Javascript and Python code, due to escaping issues), our results
are identical. With the dictionaries as provided in this distribution,
the results (estimated number of guesses) are still within 1%.

=head1 FUNCTIONS

=head2 C<password_strength>

  my $strength = password_strength($password);

This is the main entry point for the library, and the only function
you usually care about.

It analyses the given string, finding the easiest way that a password
cracking algorithm would guess it, and reports on its findings.

=head3 Return value

The return value is a hashref, with these keys:

=over 4

=item *

C<guesses>

estimated guesses needed to crack password

=item *

C<guesses_log10>

order of magnitude of C<guesses>

=item *

C<crack_times_seconds>

hashref of back-of-the-envelope crack time estimations, in seconds,
based on a few scenarios:

=over 4

=item *

C<online_throttling_100_per_hour>

online attack on a service that rate-limits authentication attempts

=item *

C<online_no_throttling_10_per_second>

online attack on a service that doesn't rate-limit, or where an
attacker has outsmarted rate-limiting.

=item *

C<offline_slow_hashing_1e4_per_second>

offline attack. assumes multiple attackers, proper user-unique
salting, and a slow hash function with moderate work factor, such as
bcrypt, scrypt, PBKDF2.

=item *

C<offline_fast_hashing_1e10_per_second>

offline attack with user-unique salting but a fast hash function like
SHA-1, SHA-256 or MD5. A wide range of reasonable numbers anywhere
from one billion - one trillion guesses per second, depending on
number of cores and machines; ball-parking at 10B/sec.

=back

=item *

C<crack_times_display>

same keys as C<crack_times_seconds>, but more useful for display: the
values are arrayrefs C<["english string",$value]> that can be passed
to I18N libraries like L<< C<Locale::Maketext> >> to get localised
versions with proper plurals

=item *

C<score>

Integer from 0-4 (useful for implementing a strength bar):

=over 4

=item *

C<0>

too guessable: risky password. (C<< guesses < 10e3 >>)

=item *

C<1>

very guessable: protection from throttled online attacks. (C<< guesses
< 10e6 >>)

=item *

C<2>

somewhat guessable: protection from un-throttled online attacks. (C<<
guesses < 10e8 >>)

=item *

C<3>

safely un-guessable: moderate protection from offline slow-hash
scenario. (C<< guesses < 10e10 >>)

=item *

C<4>

very un-guessable: strong protection from offline slow-hash
scenario. (C<< guesses >= 10e10 >>)

=back

=item *

C<feedback>

hashref, verbal feedback to help choose better passwords, contains
useful information when C<< score <= 2 >>:

=over 4

=item *

C<warning>

a string (sometimes empty), or an arrayref C<[$string,@values]>
suitable for localisation. Explains what's wrong, e.g. 'this is a
top-10 common password'.

=item *

C<suggestions>

a possibly-empty array of suggestions to help choose a less guessable
password. e.g. 'Add another word or two'; again, elements can be
strings or arrayrefs for localisation.

=back

=item *

C<matches>

the list of patterns that zxcvbn based the guess calculation on; this
is rarely useful to show to users

=back

All the objects in the returned value can be serialised to JSON, if
you set C<convert_blessed> or equivalent in your JSON library.

=head3 Options

  my $strength = password_strength($password,\%options);

You can pass in several options to customise the behaviour of this
function. From most-frequently useful:

=over 4

=item *

C<user_input>

the most useful option: a hashref of field names and values that
should be considered "obvious guesses", e.g. account name, user's real
name, company name, &c. (see L<<
C<Data::Password::zxcvbn::Match::UserInput> >>)

=item *

C<max_score_for_feedback>

the maximum L<< /C<score> >> above which no feedback will be provided,
defaults to 2; provide a higher value if you want feedback even on
strong passwords

=item *

C<modules>

arrayref of module names to use instead of the built-in
C<Data::Password::zxcvbn::Match::*> classes; if you want to I<add> a
module, you still have to list all the built-ins in this array; L<<
C<Data::Password::zxcvbn::Match::BruteForce> >> is special, and if
included here, it will be ignored

=item *

C<match_list_module>

module name to use instead of L<< C<Data::Password::zxcvbn::MatchList>
>> to run all the computations; the module should really be a subclass
of that default one, with maybe some customised messages

=item *

C<ranked_dictionaries>

=item *

C<l33t_table>

dictionaries and transliteration table, see L<<
C<Data::Password::zxcvbn::Match::Dictionary> >>

=item *

C<graphs>

adjacency graphs for keyboard-related spatial guesses, see L<<
C<Data::Password::zxcvbn::Match::Spatial> >>

=item *

C<regexes>

which regexes to use, see L<< C<Data::Password::zxcvbn::Match::Regex>
>>

=back

=head1 SEE ALSO

=over

=item *

L<the original implementation by Dropbox|https://github.com/dropbox/zxcvbn>

=item *

L<the Python port|https://github.com/dwolfhub/zxcvbn-python>

=back

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
