package main;

use 5.006002;

use strict;
use warnings;

use Astro::Coord::ECI::TLE;
use Test::More 0.88;	# Because of done_testing();

my @rslt;

note <<'EOD';
This test is of the proper population of the magnitude table only.
Actual computation tests are done elsewhere.
EOD

succeeds( clear => 'Clearing the magnitude table' );

succeeds( show => 'Retrieving the empty magnitude table' );

is_deeply \@rslt, [], 'There are no magnitudes in the table';

succeeds( magnitude => { 25544 => -1.0 },
    'Setting the magnitude table directly' );

succeeds( show => 'Retrieving the magnitude table' );

is_deeply \@rslt, [ 25544 => -1.0 ],
    'Contents of magnitude table are as expected';

succeeds( show => 5,
    'Retrieving a magnitude which is not in the table' );

is_deeply \@rslt, [], 'The retrieval of 00005 returned nothing';

succeeds( add => 00005 => 11, 'Adding OID 5' );

succeeds( show => 5, 'Retrieving an added magnitude' );

is_deeply \@rslt, [ '00005' => 11 ],
    'Got back correct magnitude for OID 5';

succeeds( show => 25544, 'Retrieving originally-loaded magnitude' );

is_deeply \@rslt, [ 25544, -1.0 ],
    'Got back correct originally-loaded magnitude';

succeeds( show => 'Retrieving all loaded magnitudes' );

is_deeply { @rslt }, {
    '00005'	=> 11,
    '25544'	=> -1,
}, 'The contents of the magnitude table are as expected';

succeeds( drop => 5, 'Dropping OID 5' );

succeeds( show => 'Retrieving modified magnitudes' );

is_deeply \@rslt, [ 25544 => -1 ],
    'Dropped body is gone from table';

succeeds( molczan => 't/mcnames.mag',
    'Loading a Molczan-format magnitude file' );

succeeds( show => 'Retrieving Molczan-format magnitudes' );

my $want = {
    '20580'	=> 3.0,
    '25544'	=> -0.5,
    '37820'	=> 4.0,
};

is_deeply { @rslt }, $want, 'Got the expected data from the load';

if ( open my $fh, '<', 't/mcnames.mag' ) {
    clear(  );
    succeeds( molczan => $fh, 'Loading a Molczan-format file handle' );
    close $fh;
    succeeds( show => 'Retrieve data loaded from file handle' );
    is_deeply { @rslt }, $want,
	'Got the expected data from the handle';
} else {
    note <<"EOD";
Skipping load of Molczan-format data from file handle. Failed to open
t/mcnames.mag: $!
EOD
}

clear(  );

succeeds( quicksat => 't/quicksat.mag',
    'Loading a Quicksat-format magnitude file' );

succeeds( show => 'Retrieving Quicksat-format magnitudes' );

$want = {
    '20580'	=> 2.2,
    '25544'	=> -1.3,
    '37820'	=> 3.2,
};

is_deeply { @rslt }, $want, 'Got the expected data from the load';

if ( open my $fh, '<', 't/quicksat.mag' ) {
    clear(  );
    succeeds( quicksat => $fh, 'Loading a Quicksat-format file handle' );
    close $fh;
    succeeds( show => 'Retrieve data loaded from file handle' );
    is_deeply { @rslt }, $want,
	'Expected data is 0.7 mag dimmer than file contents';
} else {
    note <<"EOD";
Skipping load of Quicksat-format data from file handle. Failed to open
t/quicksat.mag: $!
EOD
}

succeeds( adjust => 'Getting the magnitude adjustment' );

cmp_ok $rslt[0], '==', 0, 'The default magnitude adjustment is zero';

# Except for the OID (which was changed from 88888) the following OID is
# test data distributed with Space Track Report Number 3, obtained from
# the Celestrak web site.

my $tle;
ok eval {
    ( $tle ) = Astro::Coord::ECI::TLE->parse( <<'EOD' );
1 25544U          80275.98708465  .00073094  13844-3  66816-4 0    8
2 25544  72.8435 115.9689 0086731  52.6988 110.5714 16.05824518  105
EOD
    1;
}, 'Parse test TLE';

cmp_ok $tle->get( 'intrinsic_magnitude' ), '==', -1.3,
    'The intrinsic magnitude got set to -1.3';

succeeds( adjust => 0.7, 'Setting the magnitude adjustment to 0.7' );

succeeds( adjust => 'Retrieving the new magnitude adjustment' );

cmp_ok $rslt[0], '==', 0.7, 'The magnitude adjustment is now 0.7';

succeeds( show => 25544, 'Retrieving the magnitude table entry for our OID' );

cmp_ok { @rslt }->{'25544'}, '==', -1.3,
    'Magnitude table still has -1.3';

ok eval {
    ( $tle ) = Astro::Coord::ECI::TLE->parse( <<'EOD' );
1 25544U          80275.98708465  .00073094  13844-3  66816-4 0    8
2 25544  72.8435 115.9689 0086731  52.6988 110.5714 16.05824518  105
EOD
    1;
}, 'Re-parse the test TLE';

cmp_ok 0 + sprintf( '%.1f', $tle->get( 'intrinsic_magnitude' ) ), '==', -0.6,
    'The intrinsic magnitude got set to -0.6';


done_testing;

sub clear {
    my ( $name ) = @_;
    defined $name
	or $name = 'Clear magnitude table';
    eval {
	Astro::Coord::ECI::TLE->magnitude_table( 'clear' );
	@rslt = Astro::Coord::ECI::TLE->magnitude_table( 'show' );
	@rslt
	    and die "Magnitude table still occupied\n";
	1;
    } or do {
	@_ = "$name failed: $@";
	goto &fail;
    };
    @_ = ( "$name succeeded" );
    goto \&pass;
}

sub succeeds {
    my ( @args ) = @_;
    my $title = pop @args;
    eval {
	@rslt = Astro::Coord::ECI::TLE->magnitude_table( @args );
	1;
    } or do {
	@_ = ( "$title failed: $@" );
	goto &fail;
    };
    @_ = ( "$title succeeded" );
    goto &pass;
}

1;

# ex: set filetype=perl textwidth=72 :
