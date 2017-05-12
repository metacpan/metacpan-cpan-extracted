use strict;
use warnings;

use lib 't/lib';
use T::RequireDateTime;

use Test::More;
use Test::Requires qw( Test::Output );

use DateTime::TimeZone;

{
    stderr_like(
        sub { DateTime::TimeZone->new( name => 'Fake/TZ' ) },
        qr/\Qfrom a different version (unknown)/,
        'loading timezone where olson version is not defined'
    );
}

{
    stderr_like(
        sub { DateTime::TimeZone->new( name => 'Fake/TZ2' ) },
        qr/\Qfrom a different version (2000a)/,
        'loading timezone where olson version is older than current'
    );
}

done_testing();

## no critic (Modules::ProhibitMultiplePackages)
{
    package DateTime::TimeZone::Fake::TZ;

    use strict;

    use Class::Singleton;
    use DateTime::TimeZone;
    use DateTime::TimeZone::OlsonDB;

    use base 'Class::Singleton', 'DateTime::TimeZone';

    sub is_olson {1}
}

{
    package DateTime::TimeZone::Fake::TZ2;

    use strict;

    use Class::Singleton;
    use DateTime::TimeZone;
    use DateTime::TimeZone::OlsonDB;

    use base 'Class::Singleton', 'DateTime::TimeZone';

    sub is_olson {1}

    sub olson_version {'2000a'}
}
