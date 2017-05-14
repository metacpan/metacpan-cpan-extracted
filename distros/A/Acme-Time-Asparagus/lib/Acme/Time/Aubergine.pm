package Acme::Time::Aubergine;
use strict;

BEGIN {
    use Exporter();
    use vars qw (@ISA @EXPORT $times );
    use Acme::Time::FooClock;
    @ISA       = qw (Exporter);
    @EXPORT = qw ( veggietime );

    $times = [
        'Tomato',       'Aubergine',      'Carrot',     'Garlic',
        'Spring Onion', 'Pumpkin',        'Asparagus',  'Onion',
        'Sweetcorn',    'Brussel Sprout', 'Red Pepper', 'Cabbage',
    ];
}

=head1 NAME

Acme::Time::Aubergine - Vegetable clock, in the King's English. Or is it
the Queen?

=head1 SYNOPSIS

    use Acme::Time::Aubergine;
    print veggietime("5:38");

See Acme::Time::Asparagus and Acme::Time::FooClock for more details.

=cut

# sub veggietime {{{

sub veggietime {
    return Acme::Time::FooClock::time(shift);
}    # }}}

1;

