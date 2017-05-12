package DateTime::Format::Human::Duration::Simple::Locale;
use Moose;
use namespace::autoclean;

has 'serial_comma' => (
    isa     => 'Bool',
    is      => 'ro',
    default => 1,
);

has 'translations' => (
    isa     => 'HashRef[ArrayRef[Str]]',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_translations',
);

sub _build_translations {
    my $self = shift;

    return {
        and         => [ 'and' ],

        year        => [ 'year',        'years'        ],
        month       => [ 'month',       'months'       ],
        week        => [ 'week',        'weeks'        ],
        hour        => [ 'hour',        'hours'        ],
        day         => [ 'day',         'days'         ],
        hour        => [ 'hour',        'hours'        ],
        minute      => [ 'minute',      'minutes'      ],
        second      => [ 'second',      'seconds'      ],
        millisecond => [ 'millisecond', 'milliseconds' ],
        nanosecond  => [ 'nanosecond',  'nanoseconds'  ],
    };
}

sub get_translation_for_value {
    my $self  = shift;
    my $unit  = shift;
    my $value = shift;

    unless ( defined $value ) {
        return $self->translations->{$unit}->[0];
    }

    return ( $value == 1 ) ? $self->translations->{$unit}->[0] : $self->translations->{$unit}->[1];
}

__PACKAGE__->meta->make_immutable;

1;
