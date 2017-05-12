use strict;
use warnings;

use Test::More tests => 5;

use DateTimeX::Lite::Locale;

DateTimeX::Lite::Locale->add_aliases( foo => 'root' );
DateTimeX::Lite::Locale->add_aliases( bar => 'foo' );
DateTimeX::Lite::Locale->add_aliases( baz => 'bar' );
eval { DateTimeX::Lite::Locale->add_aliases( bar => 'baz' ) };

like( $@, qr/loop/, 'cannot add an alias that would cause a loop' );

my $l = DateTimeX::Lite::Locale->load('baz');
isa_ok( $l, 'DateTimeX::Lite::Locale' );
is( $l->id, 'baz', 'id is baz' );

ok( DateTimeX::Lite::Locale->remove_alias('baz'), 'remove_alias should return true' );

eval { DateTimeX::Lite::Locale->load('baz') };
like( $@, qr/invalid/i, 'removed alias should be gone' );
