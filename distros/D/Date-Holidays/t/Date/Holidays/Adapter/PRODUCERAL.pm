package Date::Holidays::Adapter::PRODUCERAL;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub holidays {
    my ($self, $year) = @_;

    return { 1224 => 'christmas' };    
}

sub is_holiday {
    my ($self, %params) = @_;

    my $year  = $params{'year'};
    my $month = $params{'month'};
    my $day   = $params{'day'};

    my $key;
    if ($month and $day) {
        $key  = $month.$day;
    }

    my $holidays = $self->holidays($year);

    if ($key and $holidays->{$key}) {
        return $holidays->{$key};
    }

    return '';
}

1;