package DateTime::Format::Human::Duration::Simple::Locale::de;
use Moose;
use namespace::autoclean;

extends 'DateTime::Format::Human::Duration::Simple::Locale';

has '+serial_comma' => (
    default => 0,
);

override '_build_translations' => sub {
    my $self = shift;

    return {
        and         => [ 'und' ],

        year        => [ 'Jahr',         'Jahre'         ],
        month       => [ 'Monat',        'Monate'        ],
        week        => [ 'Woche',        'Wochen'        ],
        day         => [ 'Tag',          'Tage'          ],
        hour        => [ 'Stunde',       'Stunden'       ],
        minute      => [ 'Minute',       'Minuten'       ],
        second      => [ 'Sekunde',      'Sekunden'      ],
        millisecond => [ 'Millisekunde', 'Millisekunden' ],
        nanosecond  => [ 'Nanosekunde',  'Nanosekunden'  ],
    };
};

__PACKAGE__->meta->make_immutable;

1;
