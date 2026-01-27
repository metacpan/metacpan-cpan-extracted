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
         "Default" : null,
         "Extra" : "",
         "Field" : "NORAD_CAT_ID",
         "Key" : "",
         "Null" : "YES",
         "Type" : "int(10) unsigned"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "OBJECT_TYPE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(12)"
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
         "Type" : "bigint(10) unsigned"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "PERIGEE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "bigint(10) unsigned"
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
         "Default" : null,
         "Extra" : "",
         "Field" : "OBJECT_NUMBER",
         "Key" : "",
         "Null" : "YES",
         "Type" : "int(10) unsigned"
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
    basicspacedata modeldef class gp_history
    } );

ok $rslt->is_success(), 'Fetch modeldef for class gp_history';

if ( $rslt->is_success() ) {

    my $expect = $json->decode( <<'EOD' );
{
   "controller" : "basicspacedata",
   "data" : [
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "CCSDS_OMM_VERS",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(3)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "COMMENT",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(33)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "CREATION_DATE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "datetime"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "ORIGINATOR",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(7)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "OBJECT_NAME",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(25)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "OBJECT_ID",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(12)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "CENTER_NAME",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(5)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "REF_FRAME",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(4)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "TIME_SYSTEM",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(3)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "MEAN_ELEMENT_THEORY",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(4)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "EPOCH",
         "Key" : "",
         "Null" : "YES",
         "Type" : "datetime(6)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "MEAN_MOTION",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(13,8)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "ECCENTRICITY",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(13,8)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "INCLINATION",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(7,4)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "RA_OF_ASC_NODE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(7,4)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "ARG_OF_PERICENTER",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(7,4)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "MEAN_ANOMALY",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(7,4)"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "EPHEMERIS_TYPE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "tinyint(3) unsigned"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "CLASSIFICATION_TYPE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "char(1)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "NORAD_CAT_ID",
         "Key" : "",
         "Null" : "NO",
         "Type" : "int(10) unsigned"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "ELEMENT_SET_NO",
         "Key" : "",
         "Null" : "YES",
         "Type" : "smallint(5) unsigned"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "REV_AT_EPOCH",
         "Key" : "",
         "Null" : "YES",
         "Type" : "mediumint(8) unsigned"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "BSTAR",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(19,14)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "MEAN_MOTION_DOT",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(9,8)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "MEAN_MOTION_DDOT",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(22,13)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "SEMIMAJOR_AXIS",
         "Key" : "",
         "Null" : "YES",
         "Type" : "double(12,3)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "PERIOD",
         "Key" : "",
         "Null" : "YES",
         "Type" : "double(12,3)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "APOAPSIS",
         "Key" : "",
         "Null" : "YES",
         "Type" : "double(12,3)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "PERIAPSIS",
         "Key" : "",
         "Null" : "YES",
         "Type" : "double(12,3)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "OBJECT_TYPE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(12)"
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
         "Default" : null,
         "Extra" : "",
         "Field" : "COUNTRY_CODE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "char(6)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "LAUNCH_DATE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(10)"
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
         "Field" : "DECAY_DATE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(10)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "FILE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "bigint(20) unsigned"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "GP_ID",
         "Key" : "",
         "Null" : "NO",
         "Type" : "int(10) unsigned"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "TLE_LINE0",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(27)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "TLE_LINE1",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(71)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "TLE_LINE2",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(71)"
      }
   ]
}
EOD
    my $got = $json->decode( $rslt->content() );
    is_deeply $got, $expect, 'Got expected modeldef for class gp_history'
	or do {
	diag <<'EOD';
Writing modeldef we got and we expect to gp_history.got and gp_history.expect
EOD
	dump_data( 'gp_history.got', $got );
	dump_data( 'gp_history.expect', $expect );
    };
}

$rslt = $st->spacetrack_query_v2( qw{
    basicspacedata modeldef class gp
    } );

ok $rslt->is_success(), 'Fetch modeldef for class gp';

if ( $rslt->is_success() ) {

    my $expect = $json->decode( <<'EOD' );
{
   "controller" : "basicspacedata",
   "data" : [
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "CCSDS_OMM_VERS",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(3)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "COMMENT",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(33)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "CREATION_DATE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "datetime"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "ORIGINATOR",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(7)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "OBJECT_NAME",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(25)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "OBJECT_ID",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(12)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "CENTER_NAME",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(5)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "REF_FRAME",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(4)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "TIME_SYSTEM",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(3)"
      },
      {
         "Default" : "",
         "Extra" : "",
         "Field" : "MEAN_ELEMENT_THEORY",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(4)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "EPOCH",
         "Key" : "",
         "Null" : "YES",
         "Type" : "datetime(6)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "MEAN_MOTION",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(13,8)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "ECCENTRICITY",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(13,8)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "INCLINATION",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(7,4)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "RA_OF_ASC_NODE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(7,4)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "ARG_OF_PERICENTER",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(7,4)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "MEAN_ANOMALY",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(7,4)"
      },
      {
         "Default" : "0",
         "Extra" : "",
         "Field" : "EPHEMERIS_TYPE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "tinyint(4)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "CLASSIFICATION_TYPE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "char(1)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "NORAD_CAT_ID",
         "Key" : "",
         "Null" : "NO",
         "Type" : "int(10) unsigned"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "ELEMENT_SET_NO",
         "Key" : "",
         "Null" : "YES",
         "Type" : "smallint(5) unsigned"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "REV_AT_EPOCH",
         "Key" : "",
         "Null" : "YES",
         "Type" : "mediumint(8) unsigned"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "BSTAR",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(19,14)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "MEAN_MOTION_DOT",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(9,8)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "MEAN_MOTION_DDOT",
         "Key" : "",
         "Null" : "YES",
         "Type" : "decimal(22,13)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "SEMIMAJOR_AXIS",
         "Key" : "",
         "Null" : "YES",
         "Type" : "double(12,3)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "PERIOD",
         "Key" : "",
         "Null" : "YES",
         "Type" : "double(12,3)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "APOAPSIS",
         "Key" : "",
         "Null" : "YES",
         "Type" : "double(12,3)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "PERIAPSIS",
         "Key" : "",
         "Null" : "YES",
         "Type" : "double(12,3)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "OBJECT_TYPE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(12)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "RCS_SIZE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "char(6)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "COUNTRY_CODE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "char(6)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "LAUNCH_DATE",
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
         "Field" : "DECAY_DATE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "date"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "FILE",
         "Key" : "",
         "Null" : "YES",
         "Type" : "bigint(20) unsigned"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "GP_ID",
         "Key" : "",
         "Null" : "NO",
         "Type" : "int(10) unsigned"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "TLE_LINE0",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(27)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "TLE_LINE1",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(71)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "TLE_LINE2",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(71)"
      }
   ]
}
EOD
    my $got = $json->decode( $rslt->content() );
    is_deeply $got, $expect, 'Got expected modeldef for class gp'
	or do {
	diag <<'EOD';
Writing modeldef we got and we expect to gp.got and gp.expect
EOD
	dump_data( 'gp.got', $got );
	dump_data( 'gp.expect', $expect );
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
         "Default" : "",
         "Extra" : "",
         "Field" : "COUNTRY",
         "Key" : "",
         "Null" : "NO",
         "Type" : "varchar(100)"
      },
      {
         "Default" : null,
         "Extra" : "",
         "Field" : "SPADOC_CD",
         "Key" : "",
         "Null" : "YES",
         "Type" : "varchar(6)"
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
