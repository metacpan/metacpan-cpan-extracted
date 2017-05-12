#!perl -T
use strict;
use warnings;

use lib 't/lib';
use T::RequireDateTime;

use Test::Requires {
    'Test::Taint' => 0,
};

use Test::Fatal qw( lives_ok );
use Test::More;

use DateTime::TimeZone;
use DateTime::TimeZone::Local;

if ( taint_checking_ok('taint mode is on') ) {
    my $name = 'America/Chicago';
    taint($name);

    lives_ok(
        sub { DateTime::TimeZone->new( name => $name ) },
        'DateTime::TimeZone untaints tz name before loading tz module'
    );
}

done_testing();

