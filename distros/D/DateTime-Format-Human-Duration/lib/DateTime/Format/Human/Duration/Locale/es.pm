package DateTime::Format::Human::Duration::Locale::es;

use strict;
use warnings;

sub get_human_span_hashref {
    return {
        'no_oxford_comma' => 0,
        'no_time' => 'no hay tiempo',
        'and'     => 'y',    
        'year'  => 'año',
        'years' => 'años',
        'month'  => 'mes',
        'months' => 'meses',
        'week'  => 'semana',
        'weeks' => 'semanas',
        'day'  => 'día',
        'days' => 'días',
        'hour'  => 'hora',
        'hours' => 'horas',
        'minute'  => 'minuto',
        'minutes' => 'minutos',
        'second'  => 'segundo',
        'seconds' => 'segundos',
        'nanosecond'  => 'nanosegundo',
        'nanoseconds' => 'nanosegundos',
    };
}

1;
