use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;

use DateTime::Format::Strptime;
use DateTime;

my $strptime = DateTime::Format::Strptime->new(
    pattern  => '%B %Y',
    locale   => 'pt',
    on_error => 'croak',
);

my $e = exception { $strptime->format_datetime('somestring') };
is(
    $e->type->name,
    'DateTime',
    'got expected type failure when passing a string to format_datetime'
);

done_testing();
