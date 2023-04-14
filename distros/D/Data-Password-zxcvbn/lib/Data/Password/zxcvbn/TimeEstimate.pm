package Data::Password::zxcvbn::TimeEstimate;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK=qw(estimate_attack_times guesses_to_score display_time);
our $VERSION = '1.1.2'; # VERSION
# ABSTRACT: functions to estimate cracking times


sub estimate_attack_times {
    my ($guesses) = @_;
    my %crack_times_seconds = (
        online_throttling_100_per_hour => $guesses / (100.0 / 3600.0),
        online_no_throttling_10_per_second => $guesses / 10.0,
        offline_slow_hashing_1e4_per_second => $guesses / 1e4,
        offline_fast_hashing_1e10_per_second => $guesses / 1e10,
    );

    my %crack_times_display = map {
        $_ => display_time($crack_times_seconds{$_})
    } keys %crack_times_seconds;

    return {
        crack_times_seconds => \%crack_times_seconds,
        crack_times_display => \%crack_times_display,
    };
}


# the +5 are apparently there to avoid fencepost errors
my @score_scales = (
    1e3+5, # risky password: "too guessable"

    1e6+5, # modest protection from throttled online attacks: "very guessable"

    1e8+5, # modest protection from unthrottled online attacks:
           # "somewhat guessable"

    1e10+5, # modest protection from offline attacks: "safely
            # unguessable" assuming a salted, slow hash function like
            # bcrypt, scrypt, PBKDF2, argon, etc

    # else: strong protection from offline attacks under same
    # scenario: "very unguessable"
);
sub guesses_to_score {
    my ($guesses) = @_;

    for my $score (0..$#score_scales) {
        if ($guesses < $score_scales[$score]) {
            return $score
        }
    }

    return scalar @score_scales;
}


my @display_scales = (
    # if it's less than this, use this name
    # (otherwise divide by the number, and carry on)
    [ 60 => 'second' ],
    [ 60 => 'minute' ],
    [ 24 => 'hour' ],
    [ 30 => 'day' ],
    [ 12 => 'month' ],
    [ 100 => 'year' ],
);

sub display_time {
    my ($time) = @_;
    return ['less than a second']
        if $time < 1;

    for my $scale (@display_scales) {
        if ($time < $scale->[0]) {
            return [ "[quant,_1,$scale->[1]]", int($time) ];
        }
        $time /= $scale->[0];
    }

    return ['centuries'];
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords PBKDF2 scrypt bcrypt un

=head1 NAME

Data::Password::zxcvbn::TimeEstimate - functions to estimate cracking times

=head1 VERSION

version 1.1.2

=head1 SYNOPSIS

  use Data::Password::zxcvbn::TimeEstimate qw(estimate_attack_times);
  my $estimates = estimate_attack_times($number_of_guesses);

=head1 DESCRIPTION

This module provides functions for back-of-the-envelope crack time
estimations, in seconds, based on a few scenarios.

=head1 FUNCTIONS

=head2 C<estimate_attack_times>

  my $estimates = estimate_attack_times($number_of_guesses);

Returns a hashref with two keys:

=over 4

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

=back

=head2 C<guesses_to_score>

 my $score = guesses_to_score($number_of_guesses);

Returns an integer from 0-4 (useful for implementing a strength bar):

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

=head2 C<display_time>

  my ($string,@values) = @{ display_time($time) };
  print My::Localise->get_handle->maketext($string,@values);

Given a C<$time> in seconds, returns an arrayref suitable for
L<< C<Locale::Maketext> >>, like:

 [ 'quant,_1,day', 23 ]

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
