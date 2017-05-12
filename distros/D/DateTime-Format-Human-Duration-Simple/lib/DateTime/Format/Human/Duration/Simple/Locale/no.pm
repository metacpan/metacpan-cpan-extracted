package DateTime::Format::Human::Duration::Simple::Locale::no;
use Moose;
use namespace::autoclean;
use utf8;

extends 'DateTime::Format::Human::Duration::Simple::Locale';

override '_build_translations' => sub {
    my $self = shift;

    return {
        and         => [ 'og' ],

        year        => [ 'år',          'år'            ],
        month       => [ 'måned',       'måneder'       ],
        week        => [ 'uke',         'uker'          ],
        day         => [ 'dag',         'dager'         ],
        hour        => [ 'time',        'timer'         ],
        minute      => [ 'minutt',      'minutter'      ],
        second      => [ 'sekund',      'sekunder'      ],
        millisecond => [ 'millisekund', 'millisekunder' ],
        nanosecond  => [ 'nanosekund',  'nanosekunder'  ],
    };
};

__PACKAGE__->meta->make_immutable;

1;
