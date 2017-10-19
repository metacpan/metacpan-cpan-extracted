package main;

use strict;
use warnings;

use Astro::Coord::ECI::TLE;
use Astro::Coord::ECI::TLE::Iridium;
use Test::More 0.88;	# Because of done_testing().

eval {
    require Safe;
    1;
} or plan skip_all => 'Can not load module Safe';

note <<'EOD';

The following tests check manipulation of the canned statuses
EOD

cmp_ok elements( Astro::Coord::ECI::TLE->status( 'show' ) ), '==', 97,
    'Astro::Coord::ECI::TLE->status() items initially';

Astro::Coord::ECI::TLE->status( 'clear' );
cmp_ok elements( Astro::Coord::ECI::TLE->status( 'show' ) ), '==', 0,
    'Astro::Coord::ECI::TLE->status() items after clear';

Astro::Coord::ECI::TLE->status( add => 22222, iridium => '' );
cmp_ok elements( Astro::Coord::ECI::TLE->status( 'show' ) ), '==', 1,
    'Astro::Coord::ECI::TLE->status() items after adding 22222';

note <<'EOD';

The following tests UNDOCUMENTED AND UNSUPPORTED functionality. This
means that the functionality exists solely for the convenience of the
author, who reserves the right to change or revoke the functionality
without notice.
EOD

is_deeply( Safe->new()->reval(
	scalar Astro::Coord::ECI::TLE->status( 'dump' )
    ),
    {
	'22222' => {
	    'class' => 'Astro::Coord::ECI::TLE::Iridium',
	    'comment' => '',
	    'id' => '22222',
	    'name' => '',
	    'status' => 0,
	    'type' => 'iridium'
	}
    }, 'Data::Dumper dump',
);

note <<'EOD';

OK, now we are back to testing supported stuff again.
EOD

Astro::Coord::ECI::TLE->status( add => 33333, iridium => '?' );

note <<'EOD';

The following tests check the reblessing machinery
EOD

my $tle = Astro::Coord::ECI::TLE->new( id => 11111 );
is ref $tle, 'Astro::Coord::ECI::TLE', 'OID 11111 is a TLE';

ok ! $tle->can_flare(), 'OID 11111 can not flare.';

$tle->rebless( 'iridium' );
is ref $tle, 'Astro::Coord::ECI::TLE::Iridium',
    'OID 11111 can be reblessed to Iridium';

ok $tle->can_flare(), 'Now OID 11111 can flare.';

$tle->rebless();
is ref $tle, 'Astro::Coord::ECI::TLE',
    'By default, OID 11111 reblesses to a TLE';

ok ! $tle->can_flare(), 'Again, OID 11111 can not flare.';

$tle->set( id => 22222 );
is ref $tle, 'Astro::Coord::ECI::TLE::Iridium',
    q{Changing object's OID to 22222 makes it an Iridium};

ok $tle->can_flare(), 'OID 22222 can flare.';

$tle->set( id => 33333 );
is ref $tle, 'Astro::Coord::ECI::TLE::Iridium',
    q{Changing object's OID to 33333 leaves it still an Iridium};

ok ! $tle->can_flare(), 'But OID 33333 can not flare.';

ok $tle->can_flare( 1 ), 'OID 33333 can flare if we accept spares';

note 'Specify that OID 33333 has decayed';
Astro::Coord::ECI::TLE->status( add => 33333, iridium => 'D' );
$tle->rebless();

ok ! $tle->can_flare(), 'Now OID 33333 can not flare.';

ok ! $tle->can_flare( 1 ), 'and OID 33333 can not flare if we accept spares';

ok $tle->can_flare( 'all' ), 'but OID 33333 can flare if we accept all';

$tle = Astro::Coord::ECI::TLE->new( id => 22222 );
is ref $tle, 'Astro::Coord::ECI::TLE::Iridium',
    'If we instantiate OID 22222 directly, we get an Iridium';

$tle = Astro::Coord::ECI::TLE->new( reblessable => 0, id => 22222 );
is ref $tle, 'Astro::Coord::ECI::TLE',
    'But if we turn off reblessing, OID 22222 is a plain TLE';

$tle->set( reblessable => 1 );
is ref $tle, 'Astro::Coord::ECI::TLE::Iridium',
    'If we turn reblessing back on, OID 22222 becomes an Iridium';

$tle->rebless( 'tle' );
is ref $tle, 'Astro::Coord::ECI::TLE',
    'But we can still rebless OID 22222 to a plain TLE';

$tle->rebless();
is ref $tle, 'Astro::Coord::ECI::TLE::Iridium',
    'A default rebless makes OID 22222 an Iridium again';

$tle->set( id => 11111 );
is ref $tle, 'Astro::Coord::ECI::TLE',
    'Changing the OID to 11111 makes it a plain TLE';

note <<'EOD';

The following tests check whether various attributes affect the model
EOD

ok ! $tle->is_model_attribute( 'reblessable' ),
    q{'reblessable' is not a model attribute};

ok ! $tle->is_model_attribute( 'horizon' ),
    q{'horizon' is not a model attribute};

ok ! $tle->is_model_attribute( 'status' ),
    q{'status' is not a model attribute};

ok $tle->is_model_attribute( 'bstardrag' ),
    q{'bstardrag' is a model attribute};

ok $tle->is_model_attribute( 'meananomaly' ),
    q{'meananomaly' is a model attribute};

ok ! $tle->is_model_attribute( 'id' ),
    q{'id' is not a model attribute};

ok ! $tle->is_model_attribute( 'name' ),
    q{'name' is not a model attribute};

note <<'EOD';

The following tests check whether various model names are valid
EOD

ok $tle->is_valid_model( 'model' ), q{'model' is a valid model};

ok $tle->is_valid_model( 'null' ), q{'null' is a valid model};

ok $tle->is_valid_model( 'sgp4' ), q{'sgp4' is a valid model};

ok $tle->is_valid_model( 'sdp4' ), q{'sdp4' is a valid model};

ok ! $tle->is_valid_model( 'pdq4' ), q{'pdq4' is not a valid model};

done_testing;

sub elements {
    return scalar @_;
}

1;

# ex: set textwidth=72 :
