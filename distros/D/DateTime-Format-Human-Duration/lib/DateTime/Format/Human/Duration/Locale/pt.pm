package DateTime::Format::Human::Duration::Locale::pt;

use strict;
use warnings;

sub get_human_span_hashref {
    return {
        'no_oxford_comma' => 0,
        'no_time' => 'nenhum momento',
        'and'     => 'e',    
        'year'  => 'ano',
        'years' => 'anos',
        'month'  => 'mês',
        'months' => 'meses',
        'week'  => 'semana',
        'weeks' => 'semanas',
        'day'  => 'dia',
        'days' => 'dias',
        'hour'  => 'hora',
        'hours' => 'horas',
        'minute'  => 'minuto',
        'minutes' => 'minutos',
        'second'  => 'segundo',
        'seconds' => 'segundos',
        'nanosecond'  => 'nanosegundo', # nanosecond ?
        'nanoseconds' => 'nanosegundos', # nanosegundos ?
    };
}

1;
