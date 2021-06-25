#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;
use Date::QuarterOfYear qw/ quarter_of_year /;

like(
    exception { quarter_of_year([ 2019, 02, 28 ]) },
    qr/you can't pass a reference of type ARRAY/,
    "passing an arrayref should croak",
);

like(
    exception { quarter_of_year({ years => 2019, month => 2, day => 28 }) },
    qr/you must specify year, month and day/,
    "missing out year from hashref should croak",
);

like(
    exception { quarter_of_year({ year => 2019, months => 2, day => 28 }) },
    qr/you must specify year, month and day/,
    "missing out month from hashref should croak",
);

like(
    exception { quarter_of_year({ year => 2019, month => 2, days => 28 }) },
    qr/you must specify year, month and day/,
    "missing out day from hashref should croak",
);

like(
    exception { quarter_of_year( years => 2019, month => 2, day => 28 ) },
    qr/you must specify year, month and day/,
    "missing out year from hash should croak",
);

like(
    exception { quarter_of_year( year => 2019, months => 2, day => 28 ) },
    qr/you must specify year, month and day/,
    "missing out month from hash should croak",
);

like(
    exception { quarter_of_year( year => 2019, month => 2, days => 28 ) },
    qr/you must specify year, month and day/,
    "missing out day from hash should croak",
);

like(
    exception { quarter_of_year( year => 2019, month => 2 ) },
    qr/invalid arguments/,
    "wrong number of arguments",
);

like(
    exception { quarter_of_year( "2019-05" ) },
    qr/unexpected date format/,
    "ISO format but without the days",
);

done_testing();

