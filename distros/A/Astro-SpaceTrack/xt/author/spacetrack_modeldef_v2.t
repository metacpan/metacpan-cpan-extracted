package main;

use 5.006002;

use strict;
use warnings;

use Astro::SpaceTrack;
use JSON;
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::Test qw{ spacetrack_skip_no_prompt };

spacetrack_skip_no_prompt();

my $st = Astro::SpaceTrack->new();
my $rslt = $st->spacetrack_query_v2();
$rslt->is_success()
    or plan skip_all => 'Space Track inaccessable: ' . $rslt->status_line();

my $json = JSON->new()->pretty()->canonical()->utf8();

$rslt = $st->spacetrack_query_v2( qw{
    basicspacedata modeldef class satcat
    } );

ok $rslt->is_success(), 'Fetch modeldef for class satcat';

if ( $rslt->is_success() ) {

    my $expect = $json->decode( <<'EOD' );
{
   "controller" : "basicspacedata",
   "data" : [
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "INTLDES",
         "Key" : "",
         "Null" : "NO",
         "Type" : "char(12)"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "NORAD_CAT_ID",
         "Key" : "",
         "Null" : "NO",
         "Type" : "mediumint(8) unsigned"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "OBJECT_TYPE",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(11)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "SATNAME",
         "Key" : "",
         "Null" : "NO",
         "Type" : "char(25)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "COUNTRY",
         "Key" : "",
         "Null" : "NO",
         "Type" : "char(6)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "LAUNCH",
         "Key" : "",
         "Null" : "YES",
         "Type" : "date"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "SITE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "char(5)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "DECAY",
         "Key" : "",
         "Null" : "YES",
         "Type" : "date"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "PERIOD",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(12,2)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "INCLINATION",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(12,2)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "APOGEE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "bigint(12)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "PERIGEE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "bigint(12)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "COMMENT",
         "Key" : "",
         "Null" : "YES",
         "Type" : "char(32)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "COMMENTCODE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "tinyint(3) unsigned"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "RCSVALUE",
         "Key" : "",
         "Null" : "NO",
         "Type" : "int(1)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "RCS_SIZE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(6)"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "FILE",
         "Key" : "",
         "Null" : "NO",
         "Type" : "smallint(5) unsigned"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "LAUNCH_YEAR",
         "Key" : "",
         "Null" : "NO",
         "Type" : "smallint(5) unsigned"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "LAUNCH_NUM",
         "Key" : "",
         "Null" : "NO",
         "Type" : "smallint(5) unsigned"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "LAUNCH_PIECE",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(3)"
      },
      {
         "Default" : "N",
         "Extra" : "",
         "Field" : "CURRENT",
         "Key" : "",
         "Null" : "NO",
         "Type" : "enum('Y','N')"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "OBJECT_NAME",
         "Key" : "",
         "Null" : "NO",
         "Type" : "char(25)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "OBJECT_ID",
         "Key" : "",
         "Null" : "NO",
         "Type" : "char(12)"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "OBJECT_NUMBER",
         "Key" : "",
         "Null" : "NO",
         "Type" : "mediumint(8) unsigned"
      }
   ]
}
EOD
    my $got = $json->decode( $rslt->content() );
    is_deeply $got, $expect, 'Got expected modeldef for class satcat'
	or do {
	diag <<'EOD';
Writing modeldef we got and we expect to satcat.got and satcat.expect
EOD
	dump_data( 'satcat.got', $got );
	dump_data( 'satcat.expect', $expect );
    };
}

$rslt = $st->spacetrack_query_v2( qw{
    basicspacedata modeldef class tle
    } );

ok $rslt->is_success(), 'Fetch modeldef for class tle';

if ( $rslt->is_success() ) {

    my $expect = $json->decode( <<'EOD' );
{
   "controller" : "basicspacedata",
   "data" : [
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "COMMENT",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(32)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "ORIGINATOR",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(5)"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "NORAD_CAT_ID",
         "Key" : "",
         "Null" : "NO",
         "Type" : "mediumint(8) unsigned"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "OBJECT_NAME",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(60)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "OBJECT_TYPE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(11)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "CLASSIFICATION_TYPE",
         "Key" : "",
         "Null" : "NO",
         "Type" : "char(1)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "INTLDES",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(8)"
      },
      {
         "Default" : "0000-00-00 00:00:00",
         "Extra" : "",
         "Field" : "EPOCH",
         "Key" : "",
         "Null" : "NO",
         "Type" : "datetime"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "EPOCH_MICROSECONDS",
         "Key" : "",
         "Null" : "NO",
         "Type" : "mediumint(8) unsigned"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "MEAN_MOTION",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "ECCENTRICITY",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "INCLINATION",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "RA_OF_ASC_NODE",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "ARG_OF_PERICENTER",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "MEAN_ANOMALY",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "EPHEMERIS_TYPE",
         "Key" : "",
         "Null" : "NO",
         "Type" : "tinyint(3) unsigned"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "ELEMENT_SET_NO",
         "Key" : "",
         "Null" : "NO",
         "Type" : "smallint(5) unsigned"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "REV_AT_EPOCH",
         "Key" : "",
         "Null" : "NO",
         "Type" : "float"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "BSTAR",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "MEAN_MOTION_DOT",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "MEAN_MOTION_DDOT",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "FILE",
         "Key" : "",
         "Null" : "NO",
         "Type" : "int(10) unsigned"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "TLE_LINE0",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(62)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "TLE_LINE1",
         "Key" : "",
         "Null" : "NO",
         "Type" : "char(71)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "TLE_LINE2",
         "Key" : "",
         "Null" : "NO",
         "Type" : "char(71)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "OBJECT_ID",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(11)"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "OBJECT_NUMBER",
         "Key" : "",
         "Null" : "NO",
         "Type" : "mediumint(8) unsigned"
      },
      {
	  "Default" : "0.000",
	  "Extra" : "",
	  "Field" : "SEMIMAJOR_AXIS",
	  "Key" : "",
	  "Null" : "NO",
	  "Type" : "double(20,3)"
      },
      {
	  "Default" : null,
	  "Extra" : "",
	  "Field" : "PERIOD",
	  "Key" : "",
	  "Null" : "YES",
	  "Type" : "double(20,3)"
      },
      {
	  "Default" : "0.000",
	  "Extra" : "",
	  "Field" : "APOGEE",
	  "Key" : "",
	  "Null" : "NO",
	  "Type" : "double(20,3)"
      },
      {
	  "Default" : "0.000",
	  "Extra" : "",
	  "Field" : "PERIGEE",
	  "Key" : "",
	  "Null" : "NO",
	  "Type" : "double(20,3)"
      }
   ]
}
EOD
    my $got = $json->decode( $rslt->content() );
    is_deeply $got, $expect, 'Got expected modeldef for class tle'
	or do {
	diag <<'EOD';
Writing modeldef we got and we expect to tle.got and tle.expect
EOD
	dump_data( 'tle.got', $got );
	dump_data( 'tle.expect', $expect );
    };
}

$rslt = $st->spacetrack_query_v2( qw{
    basicspacedata modeldef class tle_latest
    } );

ok $rslt->is_success(), 'Fetch modeldef for class tle_latest';

if ( $rslt->is_success() ) {

    my $expect = $json->decode( <<'EOD' );
{
   "controller" : "basicspacedata",
   "data" : [
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "ORDINAL",
         "Key" : "",
         "Null" : "NO",
         "Type" : "tinyint(3) unsigned"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "COMMENT",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(32)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "ORIGINATOR",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(5)"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "NORAD_CAT_ID",
         "Key" : "",
         "Null" : "NO",
         "Type" : "mediumint(8) unsigned"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "OBJECT_NAME",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(60)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "OBJECT_TYPE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(11)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "CLASSIFICATION_TYPE",
         "Key" : "",
         "Null" : "NO",
         "Type" : "char(1)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "INTLDES",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(8)"
      },
      {
         "Default" : "0000-00-00 00:00:00",
         "Extra" : "",
         "Field" : "EPOCH",
         "Key" : "",
         "Null" : "NO",
         "Type" : "datetime"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "EPOCH_MICROSECONDS",
         "Key" : "",
         "Null" : "NO",
         "Type" : "mediumint(8) unsigned"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "MEAN_MOTION",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "ECCENTRICITY",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "INCLINATION",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "RA_OF_ASC_NODE",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "ARG_OF_PERICENTER",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "MEAN_ANOMALY",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "EPHEMERIS_TYPE",
         "Key" : "",
         "Null" : "NO",
         "Type" : "tinyint(3) unsigned"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "ELEMENT_SET_NO",
         "Key" : "",
         "Null" : "NO",
         "Type" : "smallint(5) unsigned"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "REV_AT_EPOCH",
         "Key" : "",
         "Null" : "NO",
         "Type" : "float"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "BSTAR",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "MEAN_MOTION_DOT",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "MEAN_MOTION_DDOT",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "FILE",
         "Key" : "",
         "Null" : "NO",
         "Type" : "int(10) unsigned"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "TLE_LINE0",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(62)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "TLE_LINE1",
         "Key" : "",
         "Null" : "NO",
         "Type" : "char(71)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "TLE_LINE2",
         "Key" : "",
         "Null" : "NO",
         "Type" : "char(71)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "OBJECT_ID",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(11)"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "OBJECT_NUMBER",
         "Key" : "",
         "Null" : "YES",
         "Type" : "mediumint(8) unsigned"
      },
      {
         "Default" : "0.000",
         "Extra" : "",
         "Field" : "SEMIMAJOR_AXIS",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double(20,3)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "PERIOD",
         "Key" : "",
         "Null" : "YES",
         "Type" : "double(20,3)"
      },
      {
         "Default" : "0.000",
         "Extra" : "",
         "Field" : "APOGEE",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double(20,3)"
      },
      {
         "Default" : "0.000",
         "Extra" : "",
         "Field" : "PERIGEE",
         "Key" : "",
         "Null" : "NO",
         "Type" : "double(20,3)"
      }
   ]
}
EOD
    my $got = $json->decode( $rslt->content() );
    is_deeply $got, $expect, 'Got expected modeldef for class tle_latest'
	or do {
	diag <<'EOD';
Writing modeldef we got and we expect to tle_latest.got and tle_latest.expect
EOD
	dump_data( 'tle_latest.got', $got );
	dump_data( 'tle_latest.expect', $expect );
    };
}

$rslt = $st->spacetrack_query_v2( qw{
    basicspacedata modeldef class boxscore
    } );

ok $rslt->is_success(), 'Fetch modeldef for class boxscore';

if ( $rslt->is_success() ) {

    my $expect = $json->decode( <<'EOD' );
{
   "controller" : "basicspacedata",
   "data" : [
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "COUNTRY",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(100)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "SPADOC_CD",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(9)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "ORBITAL_TBA",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(23,0)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "ORBITAL_PAYLOAD_COUNT",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(23,0)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "ORBITAL_ROCKET_BODY_COUNT",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(23,0)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "ORBITAL_DEBRIS_COUNT",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(23,0)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "ORBITAL_TOTAL_COUNT",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(23,0)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "DECAYED_PAYLOAD_COUNT",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(23,0)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "DECAYED_ROCKET_BODY_COUNT",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(23,0)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "DECAYED_DEBRIS_COUNT",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(23,0)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "DECAYED_TOTAL_COUNT",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(23,0)"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "COUNTRY_TOTAL",
         "Key" : "",
         "Null" : "NO",
         "Type" : "bigint(21)"
      }
   ]
}
EOD
    my $got = $json->decode( $rslt->content() );
    is_deeply $got, $expect, 'Got expected modeldef for class boxscore'
	or do {
	diag <<'EOD';
Writing modeldef we got and we expect to boxscore.got and boxscore.expect
EOD
	dump_data( 'boxscore.got', $got );
	dump_data( 'boxscore.expect', $expect );
    };
}

$rslt = $st->spacetrack_query_v2( qw{
    basicspacedata modeldef class launch_site
    } );

ok $rslt->is_success(), 'Fetch modeldef for class launch_site';

if ( $rslt->is_success() ) {

    my $expect = $json->decode( <<'EOD' );
{
   "controller" : "basicspacedata",
   "data" : [
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "SITE_CODE",
         "Key" : "",
         "Null" : "NO",
         "Type" : "char(5)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "LAUNCH_SITE",
         "Key" : "",
         "Null" : "NO",
         "Type" : "char(64)"
      }
   ]
}
EOD
    my $got = $json->decode( $rslt->content() );
    is_deeply $got, $expect, 'Got expected modeldef for class launch_site'
	or do {
	diag <<'EOD';
Writing modeldef we got and we expect to launch_site.got and launch_site.expect
EOD
	dump_data( 'launch_site.got', $got );
	dump_data( 'launch_site.expect', $expect );
    };
}

done_testing;

1;

sub dump_data {
    my ( $fn, $data ) = @_;
    open my $fh, '>', $fn
	or die "Unable to open $fn for output: $!\n";
    print { $fh } ref $data ? $json->encode( $data ) : $data;
    close $fh;
    return;
}

# ex: set textwidth=72 :
