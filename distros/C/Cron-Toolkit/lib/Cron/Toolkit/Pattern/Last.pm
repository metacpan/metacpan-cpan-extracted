package Cron::Toolkit::Pattern::Last;
use strict;
use warnings;
use parent 'Cron::Toolkit::Pattern';
use Cron::Toolkit::Utils qw(:all);

sub type { return 'last'; }

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);

    if ($args{field_type} eq 'dow') {
        # DOW: dayL or L (L = 7L)
        if ($args{value} =~ /^(\d+)L$/i) {
            $self->{dow} = $1;
        } else {
            $self->{dow} = 7;  # L alone = last Saturday
        }
    } elsif ($args{field_type} eq 'dom') {
        # DOM: L or L-offset
        if ($args{value} =~ /^L-?(\d*)$/i) {
            $self->{offset} = $1 eq '' ? 0 : $1;
        }
    }

    return $self;
}

sub match {
    my ($self, $value, $tm) = @_;

    if ($self->field_type eq 'dom') {
        my $target = $tm->length_of_month - ($self->{offset} // 0);
        return $tm->day_of_month == $target;
    }

    if ($self->field_type eq 'dow') {
        my $target_dow = $self->{dow};

        # Find the last occurrence of target_dow in this month
        my $last_day = $tm->length_of_month;
        my $last_tm  = $tm->with_day_of_month($last_day);
        my $days_back = ($last_tm->day_of_week - $target_dow + 7) % 7;
        my $last_occurrence = $last_day - $days_back;

        return $tm->day_of_month == $last_occurrence;
    }

    return 0;
}

sub to_english {
    my ($self) = @_;

    if ($self->field_type eq 'dom') {
        if ($self->{offset} == 0) {
            return "on the last day";
        } else {
            return "on the " . num_to_ordinal($self->{offset}) . " to last day";
        }
    }

    if ($self->field_type eq 'dow') {
        my $day_name = $DAY_NAMES{$self->{dow}} // 'day';
        return "on the last $day_name";
    }

    return "last";
}

1;
