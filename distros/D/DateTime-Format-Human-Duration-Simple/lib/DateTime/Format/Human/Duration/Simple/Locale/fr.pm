package DateTime::Format::Human::Duration::Simple::Locale::fr;
use Moose;
use namespace::autoclean;

extends 'DateTime::Format::Human::Duration::Simple::Locale';

has '+serial_comma' => (
    default => 0,
);

override '_build_translations' => sub {
    my $self = shift;

    return {
        and         => [ 'et' ],

        year        => [ 'an',          'ans'            ],
        month       => [ 'mois',         'mois'          ],
        week        => [ 'semaine',      'semaines'      ],
        day         => [ 'jour',         'jours'         ],
        hour        => [ 'heure',        'heures'        ],
        minute      => [ 'minute',       'minutes'       ],
        second      => [ 'seconde',      'secondes'      ],
        millisecond => [ 'milliseconde', 'millisecondes' ],
        nanosecond  => [ 'nanoseconde',  'nanosecondes'  ],
    };
};

__PACKAGE__->meta->make_immutable;

1;
