package Acme::Time::DimSum;
use strict;

BEGIN {
    use Exporter();
    use vars qw (@ISA @EXPORT $times );
    use Acme::Time::FooClock;
    @ISA       = qw (Exporter);
    @EXPORT = qw ( sushitime );

    $times = [
        'Potsticker',          'Perl Ball',
        'Custard Tart',        'Crab Craw',
        'Stuffed Bell Pepper', 'Spring Roll',
        'Shrimp Dumpling',     'Fried Won Ton',
        'Sui Mai',             'Fortune Cookie',
        'Fried Taro',          'Pork Bun'
    ];
}

=head1 NAME

Acme::Time::DimSum - DimSum Time!

=head1 SYNOPSIS

    use Acme::Time::DimSum;
    print sushitime("5:38");

See Acme::Time::Asparagus and Acme::Time::FooClock for more details.

Buy your dimsum clock at http://www.sushiclock.com/dimsum.html

=cut

# sub sushitime {{{

sub sushitime {
    return Acme::Time::FooClock::time(shift);
}    # }}}

'domo arigato';

