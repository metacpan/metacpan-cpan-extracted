package Date::Period::Human;

use strict;
use warnings;
use Carp;

use Date::Calc qw/Delta_DHMS Today_and_Now N_Delta_YMDHMS/;

our $VERSION='0.4.5';

use utf8; # umlauts in translations

sub new {
    my ($klass, $args) = @_;
    my $self = { 
        today_and_now => $args->{today_and_now},
        lang          => $args->{lang} || 'nl',
    };
    return bless $self, $klass;
}

sub _parse_mysql_date {
    my ($mysql_date) = @_;

    if ($mysql_date && $mysql_date =~ m/^(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2}):(\d{2})$/) {
        return $1, $2, $3, $4, $5, $6;
    }
    $mysql_date ||= '';
    croak "Not a MySQL date: [$mysql_date]";
}

sub _get_date_parts {
    my ($self, $date) = @_;

    if (ref($date)) {
        return ($date->year, $date->month, $date->day, $date->hour, $date->minute, $date->second);
    }

    if ($date =~ /^\d+$/o){
	my @x = gmtime($date);
	return (
		$x[5]+1900,
		$x[4]+1,
		$x[3],
		$x[2],
		$x[1],
		$x[0]
	);
    }

    return _parse_mysql_date($date);
}

sub human_readable {
    my ($self, $date) = @_;

    my @date = $self->_get_date_parts($date);

    my @now = ref($self->{today_and_now}) eq 'ARRAY' ? @{$self->{today_and_now}} : ();

    if (!@now) {
        @now = Today_and_Now(0);
    }
    my ($Dy, $DM, $Dd,$Dh,$Dm,$Ds) = N_Delta_YMDHMS(@date,@now);

    ## the past
    if ($Dy == 1) {
        return $self->_translate('time_a_year_ago');
    }
    elsif ($Dy > 1) {
        return $self->_translate('time_years_ago', $Dy);
    }
    elsif ($DM == 1) {
        return $self->_translate('time_a_month_ago');
    }
    elsif ($DM > 1) {
        return $self->_translate('time_months_ago', $DM);
    }
    elsif ($Dd >= 7) {
        if (int($Dd / 7) == 1) {
            return $self->_translate('time_a_week_ago', 1);
        }
        if (int($Dd / 7) > 1) {
            return $self->_translate('time_weeks_ago', int($Dd / 7));
        }
    }
    elsif ($Dd > 1) {
        return $self->_translate('time_num_days_ago', $Dd);
    }
    elsif ($Dd == 1) {
        return $self->_translate('time_yesterday_at', $date[3], $date[4]);
    }
    elsif ($Dd == 0 && $Dh >= 1) {
        return $self->_translate('time_hour_min_ago', $Dh, $Dm);
    }
    elsif ($Dd == 0 && $Dh == 0 && $Dm > 0) {
        if ($Dm == 1) {
            return $self->_translate('time_minute_ago', $Dm);
        }
        return $self->_translate('time_minutes_ago', $Dm);
    }
    elsif ($Dd == 0 && $Dh == 0 && $Dm == 0 && $Ds > 5) {
        return $self->_translate('time_less_than_minute_ago');
    }

    ## the future
    elsif ($Dy == 0 && $DM < -12) { # ?? N_Delta_YMDHMS counts 1 year + 3 month as DM = 15 while Dy = 0
        if (abs(int($DM / 12)) == 1) {
            return $self->_translate('time_in_over_year');
        }
    }
    elsif ($Dy < 0) {
        if($Dy == -1){
            if ($DM < 0) {
                return $self->_translate('time_in_over_year', abs(int($DM / 12)) );
            }
            return $self->_translate('time_in_year', $Dy * -1);
        }else{
            if ($DM < 0) {
                return $self->_translate('time_in_over_years', $Dy * -1 );
            }
            return $self->_translate('time_in_years', $Dy * -1);
        }
    }
    elsif ($DM < 0) {
        if ($DM == -1) {
            return $self->_translate('time_in_month', $DM * -1 );
        }
        return $self->_translate('time_in_months',$DM * -1);
    }
    elsif ($Dd <= -2) {
        if (abs($Dd / 7) == 1) {
            return $self->_translate('time_in_week', 1);
        }
        elsif ($Dd % 7 == 0) {
            return $self->_translate('time_in_weeks', abs(int($Dd / 7)));
        }
        return $self->_translate('time_in_num_days', ($Dd * -1) );
    }
    elsif ($Dd == -1) {
        if ($Dh < 0) {
            return $self->_translate('time_after_tomorrow_at', $date[3], $date[4]);
        }
        return $self->_translate('time_tomorrow_at', $date[3], $date[4]);
    }
    elsif ($Dd == 0 && $Dh <= -1) {
        if ($Dh == -1) {
            return $self->_translate('time_in_hour_minutes', $Dh * -1, $Dm * -1);
        }
        return $self->_translate('time_in_hours_minutes', $Dh * -1, $Dm * -1);
    }
    elsif ($Dd == 0 && $Dh == 0 && $Dm < 0) {
        if ($Dm == -1) {
            return $self->_translate('time_in_minute', $Dm * -1);
        }
        return $self->_translate('time_in_minutes', $Dm * -1);
    }
    elsif ($Dd == 0 && $Dh == 0 && $Dm == 0 && $Ds < -5) {
        return $self->_translate('time_in_less_than_minute', $Ds * -1);
    }


    else {
        return $self->_translate('time_just_now');
    }
    return;
}

sub _translate {
    my ($self, $key, @values) = @_;

    my %translation = (
        de => {
            time_months_ago             => 'vor %d Monaten',
            time_a_month_ago            => 'vor einem Monat',
            time_years_ago              => 'vor %d Jahren',
            time_a_year_ago             => 'vor einem Jahr',
            time_weeks_ago              => 'vor %d Wochen',
            time_a_week_ago             => 'vor einer Woche',
            time_num_days_ago           => 'vor %d Tagen',
            time_yesterday_at           => 'Gestern um %02d:%02d',
            time_hour_min_ago           => 'vor %d Stunden %d Minuten',
            time_minute_ago             => 'vor %d Minute',
            time_minutes_ago            => 'vor %d Minuten',
            time_less_than_minute_ago   => 'vor weniger als einer Minute',
            time_just_now               => 'gerade eben',

            time_in_less_than_minute    => 'in %d Sekunden',
            time_in_minute              => 'in %d Minute',
            time_in_minutes             => 'in %d Minuten',
            time_in_hour_minutes        => 'in %d Stunde %d Minuten',
            time_in_hours_minutes       => 'in %d Stunde %d Minuten',
            time_tomorrow_at            => 'Morgen um %02d:%02d',
            time_after_tomorrow_at      => 'Übermorgen um %02d:%02d',
            time_in_num_days            => 'in %d Tagen',
            time_in_week                => 'in %d Woche',
            time_in_weeks               => 'in %d Wochen',
            time_in_month               => 'in %d Monat',
            time_in_months              => 'in %d Monaten',
            time_in_year                => 'in %d Jahr',
            time_in_over_year           => 'in über einem Jahr',
            time_in_years               => 'in %d Jahren',
            time_in_over_years          => 'in über %d Jahren',
        },
        nl => {
            time_months_ago             => '%d maanden geleden',
            time_a_month_ago            => 'een maand geleden',
            time_years_ago              => '%d jaar geleden',
            time_a_year_ago             => 'een jaar geleden',
            time_a_week_ago             => 'een week geleden',
            time_weeks_ago              => '%d weken geleden',
            time_num_days_ago           => '%d dagen geleden',
            time_yesterday_at           => 'gisteren om %02d:%02d',
            time_hour_min_ago           => '%d uur %d minuten geleden',
            time_minute_ago             => '%d minuut geleden',
            time_minutes_ago            => '%d minuten geleden',
            time_less_than_minute_ago   => 'minder dan een minuut geleden',
            time_just_now               => 'net precies',

            time_in_less_than_minute    => 'in %d seconden',
            time_in_minute              => 'in %d minute',
            time_in_minutes             => 'in %d minuten',
            time_in_hour_minutes        => 'in %d uur %d minuten',
            time_in_hours_minutes       => 'in %d uur %d minuten',
            time_tomorrow_at            => 'morgen een %02d:%02d',
            time_after_tomorrow_at      => 'de dag nar morgen een %02d:%02d',
            time_in_num_days            => 'in %d fagen',
            time_in_week                => 'in %d week',
            time_in_weeks               => 'in %d weken',
            time_in_month               => 'in %d maand',
            time_in_months              => 'in %d maanden',
            time_in_year                => 'in %d jaar',
            time_in_over_year           => 'in mer dan een jaar',
            time_in_years               => 'in %d jaar',
            time_in_over_years          => 'in mer dan %d jaar',
        },
        en => {
            time_months_ago             => '%d months ago',
            time_a_month_ago            => 'a month ago',
            time_years_ago              => '%d years ago',
            time_a_year_ago             => 'a year ago',
            time_a_week_ago             => 'a week ago',
            time_weeks_ago              => '%d weeks ago',
            time_num_days_ago           => '%d days ago',
            time_yesterday_at           => 'yesterday at %02d:%02d',
            time_hour_min_ago           => '%d hour %d minutes ago',
            time_minute_ago             => '%d minute ago',
            time_minutes_ago            => '%d minutes ago',
            time_less_than_minute_ago   => 'less than a minute ago',
            time_just_now               => 'just now',

            time_in_less_than_minute    => 'in %d seconds',
            time_in_minute              => 'in %d minute',
            time_in_minutes             => 'in %d minutes',
            time_in_hour_minutes        => 'in %d hour %d minutes',
            time_in_hours_minutes       => 'in %d hours %d minutes',
            time_tomorrow_at            => 'tomorrow at %02d:%02d',
            time_after_tomorrow_at      => 'the day after tomorrow at %02d:%02d',
            time_in_num_days            => 'in %d days',
            time_in_week                => 'in %d week',
            time_in_weeks               => 'in %d weeks',
            time_in_month               => 'in %d month',
            time_in_months              => 'in %d months',
            time_in_year                => 'in %d year',
            time_in_over_year           => 'in over a year',
            time_in_years               => 'in %d years',
            time_in_over_years          => 'in over %d years',
        },
    );

    return sprintf($translation{$self->{lang}}{$key}, @values);
}

1;

=head1 NAME

Date::Period::Human - Human readable date periods

=head1 SYNOPSYS

    # Create the Date::Period::Human object
    my $d = Date::Period::Human->new();

    # Get a relative human readable date string
    my $s = $d->human_readable('2010-01-01 02:30:42');

    # Now $s contains the relative date

=head1 DESCRIPTION

Creates a string of relative time. This is useful when you're showing user
created content, where it's nicer to show how long ago the item was posted
instead of the date and time.

This also solves the problem where you don't know the timezone of the user who
is viewing the item. This is solved because you show relative time instead of
absolute time in most cases. 

There is one case that isn't relative.

=head1 CLASS METHODS

This class contains one public class method.

=head2 new [options]

=over 4

=item lang

The language you want to use. Default 'nl', can be 'en' for English.

=item today_and_now

An arrayref containing [ $year, $month, $day, $hour, $min, $sec ].

Will be used as the fixed point from which the relative time will be calculated.

=back

=head1 METHODS

This class contains one public method.

=head2 $self->human_readable($mysql_date|$datetime|$epoch)

Parses the $mysql_date and returns a human readable time string.

Or, $datetime (a DateTime object) and returns a human readable time string.

Or, $epoch (identified by regex /^\d+$/) and passed through gmtime().

=head1 HOMEPAGE

http://github.com/pstuifzand/date-period-human

=head1 AUTHOR

Peter Stuifzand <peter@stuifzand.eu>

=head1 COPYRIGHT

Copyright 2010 Peter Stuifzand

=cut

