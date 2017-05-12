package main;

use strict;
use warnings;

use Test::More 0.88;

diag 'Things needed for authortest';

require_ok 'Astro::SIMBAD::Client';
require_ok 'Astro::SpaceTrack';
require_ok 'Date::Manip';
ok eval {
    Date::Manip->VERSION( 6 );
    1;
}, 'Installed Date::Manip is v6 or above';
require_ok 'DateTime';
require_ok 'DateTime::TimeZone';
require_ok 'Geo::WebService::Elevation::USGS';
require_ok 'Perl::MinimumVersion';
require_ok 'Test::CPAN::Changes';
require_ok 'Test::Kwalitee';
require_ok 'Test::MockTime';
require_ok 'Test::Perl::Critic';
require_ok 'Test::Without::Module';
require_ok 'Time::HiRes';

ok -f 'date_manip_v5/Date/Manip.pm',
    'Have Date::Manip v5 for regression testing';

done_testing;

1;

# ex: set textwidth=72 :
