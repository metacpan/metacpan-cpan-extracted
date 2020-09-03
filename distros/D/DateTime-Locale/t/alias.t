use strict;
use warnings;

use Test2::V0;
use Test::File::ShareDir::Dist { 'DateTime-Locale' => 'share' };

use DateTime::Locale;

DateTime::Locale->add_aliases( foo => 'root' );
DateTime::Locale->add_aliases( bar => 'foo' );
DateTime::Locale->add_aliases( baz => 'bar' );
like(
    dies { DateTime::Locale->add_aliases( bar => 'baz' ) },
    qr/loop/,
    'cannot add an alias that would cause a loop'
);

like(
    dies { DateTime::Locale->add_aliases( bar => 'bar' ) },
    qr/Can't alias an id to itself/,
    'alias to itself should fail'
);

my $l = DateTime::Locale->load('baz');
isa_ok( $l, 'DateTime::Locale::FromData' );
is( $l->id, 'root', 'id is root' );

ok(
    DateTime::Locale->remove_alias('baz'),
    'remove_alias should return true'
);

like(
    dies { DateTime::Locale->load('baz') },
    qr/invalid/i,
    'removed alias should be gone'
);

done_testing();
