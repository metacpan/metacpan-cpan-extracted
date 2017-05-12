use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;

use DateTime::Format::Strptime;
use DateTime;

my $code_meth = DateTime::Locale->load('en')->can('code') ? 'code' : 'id';

my $strptime = DateTime::Format::Strptime->new(
    pattern  => '%B %Y',
    locale   => 'pt',
    on_error => 'croak',
);

my $dt = DateTime->new(
    year   => 2015,
    month  => 8,
    locale => 'en',
);

is(
    $strptime->format_datetime($dt),
    'agosto 2015',
    'formatted output is in locale of formatter (Portugese)'
);

is(
    $dt->locale->$code_meth,
    'en',
    q{formatter leaves DateTime object's locale unchanged}
);

done_testing();
