package Date::Holidays::ABSTRACTED;

use strict;
use warnings;

use base 'Date::Holidays::Abstract';

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub holidays {
    return { 1224 => 'christmas' };
}

sub is_holiday {
    my ($self, $year, $month, $day) = @_;

    my $calendar = $self->holidays($year);
    
    my $key;
    if ($month and $day) {
        $key  = $month.$day;
    }

    if ($key and $calendar->{$key}) {
        return $calendar->{$key};
    } else {
        return '';
    }
}

1;
