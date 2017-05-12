package DateTime::Format::Human::Duration::Simple::Locale::es;
use Moose;
use namespace::autoclean;
use utf8;

extends 'DateTime::Format::Human::Duration::Simple::Locale';

has '+serial_comma' => (
    default => 0,
);

override '_build_translations' => sub {
    my $self = shift;

    return {
        and         => [ 'y' ],

        year        => [ 'año',          'años'          ],
        month       => [ 'mes',          'meses'         ],
        week        => [ 'semana',       'semanas'       ],
        day         => [ 'día',          'días'          ],
        hour        => [ 'hora',         'horas'         ],
        minute      => [ 'minuto',       'minutos'       ],
        second      => [ 'segundo',      'segundos'      ],
        millisecond => [ 'millisegundo', 'millisegundos' ],
        nanosecond  => [ 'nanosegundo',  'nanosegundos'  ],
    };
};

__PACKAGE__->meta->make_immutable;

1;
