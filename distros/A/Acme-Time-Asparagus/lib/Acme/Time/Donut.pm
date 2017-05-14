package Acme::Time::Donut;
use strict;

BEGIN {
    use Exporter();
    use vars qw(@ISA @EXPORT $times);
    use Acme::Time::FooClock;

    @ISA     = qw( Exporter );
    @EXPORT  = qw( donuttime);

    $times = [
        'Glazed Donut', 'Chocolate Bar', 'Cinnamon Roll', 'Cheese & Strawberry Danish',
        'Glazed Twist', 'Powdered Sugar Donut', 'Bear Claw', 'Blueberry Muffin',
        'Maple Donut', 'Chocolate Donut w/Peanuts', 'Plain Old Fashioned', 'Apple Turnover'
    ];
}

=head1 NAME

Acme::Time::Donut - Donut time!!

=head1 SYNOPSIS

    use Acme::Time::Donut;
    print dounttime("5:38");

See Acme::Time::Asparagus and Acme::Time::FooClock for more details.

Buy your donut clock at http://www.sushiclock.com/donut.html

=cut

# sub donuttime {{{

sub donuttime {
    return Acme::Time::FooClock::time(shift);
}    # }}}

'mmmm, donuts';
