use strict;
use warnings;

use lib 't/lib';
use T::RequireDateTime;

use Test::More;

use DateTime::TimeZone;

{
    my $tz = DateTime::TimeZone->new( name => '-0300' );
    is( $tz->name, '-0300', 'name should match value given in constructor' );
}

{
    my $tz = DateTime::TimeZone->new( name => 'floating' );
    is(
        $tz->name, 'floating',
        'name should match value given in constructor'
    );
}

{
    my $tz = DateTime::TimeZone->new( name => 'America/Chicago' );
    is(
        $tz->name, 'America/Chicago',
        'name should match value given in constructor'
    );
}

{
    my $tz = DateTime::TimeZone->new( name => 'UTC' );
    is( $tz->name, 'UTC', 'name should match value given in constructor' );
}

done_testing();
