use strict;
use warnings;

use lib 't/lib';
use T::RequireDateTime;

use Test::More;

use DateTime::TimeZone;

ok(
    !DateTime::TimeZone->new( name => 'UTC' )->has_dst_changes,
    'UTC has no DST changes'
);
ok(
    !DateTime::TimeZone->new( name => 'floating' )->has_dst_changes,
    'floating has no DST changes'
);
ok(
    !DateTime::TimeZone->new( name => 'Asia/Thimphu' )->has_dst_changes,
    'Asia/Thimphu has no DST changes'
);
ok(
    DateTime::TimeZone->new( name => 'America/Chicago' )->has_dst_changes,
    'America/chicago has DST changes'
);

done_testing();
