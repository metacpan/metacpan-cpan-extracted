package Data::OpeningHours::Calendar;
use strict;
use warnings;

use Data::OpeningHours::Hours;
use DateTime::Format::Strptime;

sub new {
    my ($class) = @_;
    my $self = {};
    $self->{parser} = DateTime::Format::Strptime->new(
        pattern => '%a',
        locale => 'en_US',
        on_error => 'croak',
    );
    return bless $self, $class;
}

sub set_week_day {
    my ($self, $day, $hours) = @_;
    $self->{week}[$day] = Data::OpeningHours::Hours->new($hours);
    return;
}

sub set_special_day {
    my ($self, $date, $hours) = @_;
    $self->{days}{$date} = Data::OpeningHours::Hours->new($hours);
    return;
}
sub is_special_day {
    my ($self, $date) = @_;
    return exists $self->{days}{$date};
}

sub is_open_on_week_day {
    my ($self, $day_of_week, $hour) = @_;
    return unless exists $self->{week}[$day_of_week];
    return $self->{week}[$day_of_week]->is_open_between($hour);
}

sub is_open_on_special_day {
    my ($self, $date, $hour) = @_;
    return $self->{days}{$date}->is_open_between($hour);
}

sub is_open {
    my ($self, $date) = @_;
    if ($self->is_special_day($date->ymd('-'))){
        return $self->is_open_on_special_day(
            $date->ymd('-'),
            sprintf('%02d:%02d', $date->hour, $date->minute));
    }

    return $self->is_open_on_week_day(
        $date->wday,
        sprintf('%02d:%02d', $date->hour, $date->minute));
}

sub first_open_hour {
    my ($self, $date) = @_;
    if ($self->is_special_day($date->ymd('-'))) {
        my $hours = $self->{days}{$date->ymd('-')};
        return $hours->first_hour() if $hours;
        return;
    }
    my $hours = $self->{week}[$date->wday];
    return $hours->first_hour() if $hours;
    return;
}

sub next_open {
    my ($self, $date) = @_;
    my $open = $date->clone;
    while (1) {
        $open->add(days => 1);
        my $hour = $self->first_open_hour($open);
        if ($hour) {
            my ($h,$m) = split /:/, $hour;
            $open->set_hour($h);
            $open->set_minute($m);
            return $open;
        }
    }
    return;
}

1;

