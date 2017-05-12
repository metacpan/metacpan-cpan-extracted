use strict;
use warnings;

use Test::More tests => 2;

use DateTime::TimeZone::Alias;

{
    my $tzs = DateTime::TimeZone::Alias->timezones();
    my $als = DateTime::TimeZone::Alias->aliases();

    is_deeply(
        \@DateTime::TimeZone::Catalog::ALL,
        $tzs,
        "compare returned timezones with internals"
    );

    is_deeply(
        \%DateTime::TimeZone::Catalog::LINKS,
        $als,
        "compare returned aliases with internals"
    );
}
