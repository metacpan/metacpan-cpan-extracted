package DateTime::Format::Human::Duration::Locale::fr;

use strict;
use warnings;

sub get_human_span_hashref {
    return {
        'no_oxford_comma' => 1,
        'no_time' => 'pas le temps',
        'and'     => 'et',    
        'year'  => 'an',
        'years' => 'ans',
        'month'  => 'mois',
        'months' => 'mois',
        'week'  => 'semaine',
        'weeks' => 'semaines',
        'day'  => 'jour',
        'days' => 'jours',
        'hour'  => 'heure',
        'hours' => 'heures',
        'minute'  => 'minute',
        'minutes' => 'minutes',
        'second'  => 'seconde',
        'seconds' => 'seconds',
        'nanosecond'  => 'nanoseconde',
        'nanoseconds' => 'nanosecondes',      
    };
}

1;
