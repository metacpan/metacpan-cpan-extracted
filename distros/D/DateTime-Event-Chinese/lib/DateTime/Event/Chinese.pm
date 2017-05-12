
package DateTime::Event::Chinese;
use strict;
use warnings;
use vars qw($VERSION);
BEGIN
{
    $VERSION = '1.00';
}
use DateTime::Astro qw(MEAN_SYNODIC_MONTH new_moon_after new_moon_before moment);
use DateTime::Event::SolarTerm qw(WINTER_SOLSTICE prev_term_at no_major_term_on);
use Math::Round qw(round);
use Exporter 'import';

our @EXPORT_OK = qw(
    chinese_new_years
    chinese_new_year_for_sui
    chinese_new_year_after
    chinese_new_year_before
    chinese_new_year_for_gregorian_year
);


# [1] p.253
sub chinese_new_year_for_sui {
    my ($dt) = @_;

    return $dt if $dt->is_infinite;
    my $s1 = prev_term_at( $dt, WINTER_SOLSTICE );
    my $s2 = prev_term_at( $s1 + DateTime::Duration->new(days => 370), WINTER_SOLSTICE );

    my $m12 = new_moon_after( $s1 + DateTime::Duration->new(days => 1) );
    my $m13 = new_moon_after( $m12 + DateTime::Duration->new(days => 1) );
    my $next_m11 = new_moon_before( $s2 + DateTime::Duration->new(days => 1) );

    my $rv;
    if (round((moment($next_m11) - moment($m12)) / MEAN_SYNODIC_MONTH) == 12 &&
        (no_major_term_on($m12) or
         no_major_term_on($m13))) {

        $rv = new_moon_after( $m13 );
    } else {
        $rv = $m13;
    }

    return $rv;
}

sub chinese_new_years {
    return DateTime::Set->from_recurrence(
        next => sub {
            return $_[0] if $_[0]->is_infinite;
            chinese_new_year_after($_[0]);
        },
        previous => sub {
            return $_[0] if $_[0]->is_infinite;
            chinese_new_year_before($_[0]);
         }
    );
}

# [1] p.253
sub chinese_new_year_before {
    my ($dt) = @_;
    return $dt if $dt->is_infinite;

    my $new_year = chinese_new_year_for_sui($dt);
    my $rv;
    if ($dt > $new_year) {
        $rv = $new_year;
    } else {
        $rv = chinese_new_year_for_sui($dt - DateTime::Duration->new(days => 180));
    }
    return $rv;
}

# [1] p.260
sub chinese_new_year_for_gregorian_year {
    my ($dt) = @_;
    return $dt if $dt->is_infinite;

    return chinese_new_year_before(
        DateTime->new(
            year => $dt->year,
            month => 7,
            day => 1,
            time_zone => $dt->time_zone
        )
    );
}

# This one didn't exist in [1]. Basically, it just tries to get the
# chinese new year in the given year, and if that is before the given
# date, we get next year's.
sub chinese_new_year_after {
    my ($dt) = @_;
    return $dt if $dt->is_infinite;
    my $new_year_this_gregorian_year = chinese_new_year_for_gregorian_year($dt);
    my $rv;
    if ($new_year_this_gregorian_year > $dt) {
        $rv = $new_year_this_gregorian_year;
    } else {
        $rv = chinese_new_year_before(
            DateTime->new(
                year => $dt->year + 1,
                month => 7,
                day => 1,
                time_zone => $dt->time_zone
            )
        );
    }
    return $rv;
}

1;

__END__

=head1 NAME

DateTime::Event::Chinese - DateTime Extension for Calculating Important Chinese Dates

=head1 SYNOPSIS

  use DateTime::Event::Chinese qw(:all);
  my $new_moon = chinese_new_years();

  my $dt0  = DateTime->new(...);
  my $next_new_year = $new_year->next($dt0);
  my $prev_new_year = $new_year->previous($dt0);

  my $dt1  = DateTime->new(...);
  my $dt2  = DateTime->new(...);
  my $span = DateTime::Span->new(start => $dt1, end => $dt2);

  my $set  = $new_year->intersection($span);
  my $iter = $set->iterator();

  while (my $dt = $iter->next) {
    print $dt->datetime, "\n";
  }

  my $new_year = chinese_new_year_for_sui($dt);
  my $new_year = chinese_new_year_for_gregorian_year($dt);
  my $new_year = chinese_new_year_after($dt);
  my $new_year = chinese_new_year_before($dt);

=head1 DESCRIPTION

This modules implements the algorithm described in "Calendrical Calculations"
to compute some important Chinese dates, such as date of new year and
other holidays (Currently only new years can be calculated).

=head1 FUNCTIONS

=head2 $set = chinese_new_years();

Returns a DateTime::Set that generates Chinese new years.

=head2 chinese_new_year_for_sui($dt)

Returns the DateTime object representing the Chinese New Year for the
"sui" (the period between two winter solstices) of the given date.

  my $dt = chinese_new_year_for_sui($dt0);

=head2 chinese_new_year_for_greogrian_year($dt)

Returns the DateTime object representing the Chinese New Year for the
given gregorian year.

  my $dt = chinese_new_year_for_sui($dt0);

=head2 chinese_new_year_after($dt)

Returns a DateTime object representing the next Chinese New Year
relative to the given datetime argument.

  my $next_new_year = chinese_new_year_after($dt0);

This is the function that is internally used by new_year()-E<gt>next().

=head2 chinese_new_year_before($dt)

Returns a DateTime object representing the previous Chinese New Year
relative to the given datetime argument.

  my $prev_new_year = chinese_new_year_beore($dt0);

This is the function that is internally used by new_year()-E<gt>previous().

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=head1 REFERENCES

  [1] Edward M. Reingold, Nachum Dershowitz
      "Calendrical Calculations (Millenium Edition)", 2nd ed.
       Cambridge University Press, Cambridge, UK 2002

=head1 SEE ALSO

L<DateTime>
L<DateTime::Set>
L<DateTime::Astro>
L<DateTime::Event::SolarTerm>

=cut