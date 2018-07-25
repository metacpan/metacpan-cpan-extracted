package main;

use 5.006002;

use strict;
use warnings;

use Test::More 0.88;

diag 'Things needed for authortest';

require_ok 'File::Spec';

{
    my $dir = $ENV{ASTRO_COORD_ECI_TLE_DIR};
    $dir
	and -d $dir
	or eval {
	require File::HomeDir;
	$dir = File::HomeDir->my_dist_config(
	    'Astro-Coord-ECI-TLE-Dir' );
    };

    ok $dir, 'TLE directory found'
	or diag 'See t/tle_pass_extra.t for where the TLE data should go';

    my $file = File::Spec->catfile( $dir, 'pass_extra.tle' );
    ok $dir && -f $file, "TLE file $file found"
	or diag 'See t/tle_pass_extra.t for what goes in this file';

}

require_ok 'Astro::SpaceTrack';
cmp_ok mung_version( Astro::SpaceTrack->VERSION ), '>=', 0.085,
    'Need at least Astro::SpaceTrack 0.085';
require_ok 'Astro::Coord::ECI::TLE::Iridium';
require_ok 'Date::Manip';
require_ok 'Test::CPAN::Changes';
require_ok 'Test::MockTime';
require_ok 'Test::Perl::Critic';
require_ok 'Test::Without::Module';
require_ok 'Time::Local';

done_testing;

sub mung_version {
    my ( $vers ) = @_;
    $vers =~ s/ _ //smxg;
    return $vers;
}

1;

# ex: set textwidth=72 :
