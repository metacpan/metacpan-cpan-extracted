use strict;
use warnings;
use utf8;

use Test::More 0.96;
use Test::File::ShareDir::Dist { 'DateTime-Locale' => 'share' };

use DateTime::Locale;

## no critic (InputOutput::RequireCheckedSyscalls)
binmode $_, ':encoding(UTF-8)'
    for map { Test::Builder->new->$_ }
    qw( output failure_output todo_output );
## use critic

for my $code (qw( English French Italian Latvian latviešu )) {
    ok(
        DateTime::Locale->load($code),
        "code $code loaded a locale"
    );
}

done_testing();
