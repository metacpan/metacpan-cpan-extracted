package DateTime::Format::Human::Duration::Locale::it;

use strict;
use warnings;

sub get_human_span_hashref {
    return {
        'no_oxford_comma' => 1,
        'no_time' => 'zero secondi',
        'and'     => 'e',
        'year'  => 'anno',
        'years' => 'anni',
        'month'  => 'mese',
        'months' => 'mesi',
        'week'  => 'settimana',
        'weeks' => 'settimane',
        'day'  => 'giorno',
        'days' => 'giorni',
        'hour'  => 'ora',
        'hours' => 'ore',
        'minute'  => 'minuto',
        'minutes' => 'minuti',
        'second'  => 'secondo',
        'seconds' => 'secondi',
        'nanosecond'  => 'nanosecondo',
        'nanoseconds' => 'nanosecondi',
    };
}

1;
