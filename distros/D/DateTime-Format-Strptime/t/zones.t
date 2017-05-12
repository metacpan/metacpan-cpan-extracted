use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;

use DateTime::Format::Strptime;

{
    my $parser = DateTime::Format::Strptime->new(
        pattern  => '%Y %Z',
        on_error => 'croak',
    );

    like(
        exception { $parser->parse_datetime('2015 EST') },
        qr/ambiguous/,
        'parser dies on ambiguous zone abbreviation'
    );
}

{
    my $parser = DateTime::Format::Strptime->new(
        pattern  => '%Y %Z',
        zone_map => { EST => '-0200' },
        on_error => 'croak',
    );

    my $dt = $parser->parse_datetime('2015 EST');
    is(
        $dt->offset, -7200,
        'parser uses zone map provided with constructor'
    );
}

done_testing();
