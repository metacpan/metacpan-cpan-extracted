package BadLocalizer;
use Moo;
extends 'Data::Localize::Localizer';

package BadFormatter;
use Moo;
extends 'Data::Localize::Format';

package main;
use strict;
use Test::More tests => 2;
use Data::Localize;

{
    my $loc = Data::Localize->new();
    eval {
        $loc->add_localizer( '+BadLocalizer' );
    };
    like( $@, qr/Bad localizer/ );
}

{
    my $format = BadFormatter->new();
    eval {
        $format->format;
    };
    like( $@, qr/format\(\) must be overridden/ );
}


## should be more
