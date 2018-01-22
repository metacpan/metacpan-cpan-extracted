use strict;
use warnings;

use lib 't/lib';
use T::RequireDateTime;

use Test::More;

foreach (
    qw( America/Chicago
    UTC
    US/Eastern
    Europe/Paris
    Etc/Zulu
    Pacific/Midway
    EST
    )
) {
    ok(
        DateTime::TimeZone->is_valid_name($_),
        "$_ is a valid timezone name"
    );
}

foreach (
    qw( America/Hell
    Foo/Bar
    FooBar
    adhdsjghs;dgohas098huqjy4ily
    1000:0001
    )
) {
    ok(
        !DateTime::TimeZone->is_valid_name($_),
        "$_ is not a valid timezone name"
    );
}

{
    DateTime::TimeZone->is_valid_name(undef);

    is(
        $@, q{},
        'calling is_valid_name with a bad argument does not leave $@ set'
    );
}

done_testing();
