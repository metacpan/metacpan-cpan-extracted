use DateTime::Event::Recurrence;
use Test::More;
use strict;
use warnings;
plan tests => 3;

my $hourly   = DateTime::Event::Recurrence->hourly;
my $next_day = DateTime::Span->from_datetimes(
    start => DateTime->now,
    end   => DateTime->now->add( days => 1 )
);
my $future = DateTime::Span->from_datetimes( start => DateTime->now );

ok( $next_day->intersects($future), "next day intersects future" );
ok( $hourly->intersects($next_day), "hourly event intersects next day" );
ok( $hourly->intersects($future), "hourly event intersects future" );

