package Date::Holidays::SUPERED;

use strict;
use warnings;

use base 'Date::Holidays::Super';

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
    
    my $key;
    my $calendar = $self->holidays($year);

    if ($month and $day) {
        $key  = $month.$day;
    }

    if ($key && $calendar->{$key}) {
        return $calendar->{$key};
    }
}

1;