package Date::Holidays::PRODUCERAL;

use strict;
use warnings;

sub holidays {
    my ($year) = @_;

    return { 1224 => 'christmas' };    
}

sub is_holiday {
    my ($year, $month, $day) = @_;

    my $key;
    if ($month and $day) {
        $key  = $month.$day;
    }

    my $holidays = holidays();

    if ($key and $holidays->{$key}) {
        return $holidays->{$key};
    }
}

1;
