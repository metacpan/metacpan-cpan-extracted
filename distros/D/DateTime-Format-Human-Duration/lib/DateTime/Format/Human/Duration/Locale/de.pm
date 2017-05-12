package DateTime::Format::Human::Duration::Locale::de;

use strict;
use warnings;

sub get_human_span_hashref {
    return {
        'no_oxford_comma' => 0,
        'no_time' => 'Keine Zeit',
        'and'     => 'und',    
        'year'  => 'Jahr',
        'years' => 'Jahre',
        'month'  => 'Monat',
        'months' => 'Monate',
        'week'  => 'Woche',
        'weeks' => 'Wochen',
        'day'  => 'Tag',
        'days' => 'Tage',
        'hour'  => 'Stunde',
        'hours' => 'Stunden',
        'minute'  => 'Minute',
        'minutes' => 'Minuten',
        'second'  => 'Sekunde',
        'seconds' => 'Sekunden',
        'nanosecond'  => 'Nanosekunde',
        'nanoseconds' => 'Nanosekunden',
    };
}

1;
