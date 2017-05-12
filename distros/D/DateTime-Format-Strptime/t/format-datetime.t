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

like(
    exception { $strptime->format_datetime('somestring') },
    qr/Validation failed for type named DateTime declared in package DateTime::Format::Strptime::Types/,
    'format_datetime() checks that it received a DateTime object'
);

done_testing();
