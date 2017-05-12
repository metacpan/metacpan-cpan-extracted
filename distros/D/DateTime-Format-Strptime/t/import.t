use strict;
use warnings;

# We need this to be set to catch warning from inside other packages.
BEGIN {
    ## no critic (Variables::RequireLocalizedPunctuationVars)
    $^W = 1;
}

use Test::More;
use Test::Warnings qw( warnings );

use DateTime::Format::Strptime qw( strftime strptime ),
    -api_version => '1.55';

is_deeply(
    [
        warnings {
            my $parser = DateTime::Format::Strptime->new( pattern => '%Y' );
            $parser->pattern('%y');
            $parser->locale('fr');
            $parser->time_zone('UTC');
        }
    ],
    [],
    'no warnings when calling accessors on constructed object'
);

is(
    strptime( '%Y', '2005' )->year,
    2005,
    'export strptime works as expected'
);

is(
    strftime( '%Y', DateTime->new( year => 2005 ) ),
    2005,
    'export strftime works as expected'
);

done_testing();
