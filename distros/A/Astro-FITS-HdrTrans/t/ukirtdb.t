#!perl

use 5.006;
use strict;
use warnings;

use Test::More;

plan tests => 5;

# Test compilation.
require_ok( 'Astro::FITS::HdrTrans' );

# Set up a header.
my $header = { 'AIRTEMP' => '3.972',
               'AMEND' => '1',
               'AMSTART' => '1',
               'BBTEMP' => '1073',
               'CALAPER' => 'BB_Blank',
               'CAMLENS' => '0.12',
               'CDELT1' => '-3.33e-05',
               'CDELT2' => '3.33e-05',
               'CRPIX1' => '480.5',
               'CRPIX2' => '480.5',
               'CRVAL1' => '20.0985013',
               'CRVAL2' => '237.4130524',
               'CTYPE1' => 'DEC--TAN',
               'CTYPE2' => 'RA---TAN',
               'DATE_END' => '2008-08-09T05:00:38.295',
               'DATE_OBS' => '2008-08-09T04:58:56.526',
               'DCOLUMNS' => '1024',
               'DECBASE' => '20.0985013',
               'DECJ2000' => '0',
               'DECJ2000_INT' => '0',
               'DECOFF' => '-0.002',
               'DEPERDN' => '6.3',
               'DETECTOR' => 'ALADDIN',
               'DEXPTIME' => '100',
               'DOMETEMP' => '5.712',
               'DROWS' => '1024',
               'EQUINOX' => '2000',
               'EXPOSED' => '100',
               'FILENAME' => 'u20080809_00038.sdf',
               'FILTER' => 'black_blank',
               'FILTER1' => 'black_blank',
               'FILTER2' => 'open',
               'GRISM' => 'open',
               'GRISM1' => 'open',
               'GRISM2' => 'open',
               'GRPMEM' => '0',
               'GRPNUM' => '37',
               'HUMIDITY' => '5.768',
               'IDKEY' => '2425285',
               'INSTMODE' => 'imaging',
               'INSTRUME' => 'UIST',
               'LAMP' => 'off',
               'MODE' => 'ND1',
               'MSBID' => 'CAL',
               'NEXP' => '1',
               'OBJECT' => 'None',
               'OBSERVER' => 'BLANK',
               'OBSNUM' => '38',
               'OBSTYPE' => 'DARK',
               'PIXLSIZE' => '0.12',
               'POLARISE' => '0',
               'PROJECT' => 'CAL',
               'RABASE' => '15.8275368',
               'RAJ2000' => '0',
               'RAJ2000_INT' => '0',
               'RAOFF' => '0',
               'RDOUT_X1' => '1',
               'RDOUT_X2' => '1024',
               'RDOUT_Y1' => '1',
               'RDOUT_Y2' => '1024',
               'RECIPE' => 'DARK_AND_BPM',
               'RUN' => '38',
               'SLITNAME' => 'large_field',
               'STANDARD' => '1',
               'OPER_SFT' => 'NIGHT',
               'TELESCOP' => 'UKIRT',
               'TRUSSENE' => '10.281',
               'TRUSSWSW' => '8.763',
               'UTDATE' => '20080809',
               'UT_DATE' => 'Aug  9 2008 12:00AM',
               'UT_DMF' => '902725136',
               'WAVEFORM' => 'uist_ndr1024_app',
               'WPLANGLE' => '0',
             };

# Translate it.
my %gen = Astro::FITS::HdrTrans::translate_from_FITS( $header );

# Check UT dates.
isa_ok( $gen{'UTSTART'}, "Time::Piece", "UTSTART is a Time::Piece object" );
is( $gen{'UTSTART'}, "Sat Aug  9 04:58:56 2008", "UTSTART translates" );
isa_ok( $gen{'UTEND'}, "Time::Piece", "UTEND is a Time::Piece object" );
is( $gen{'UTEND'}, "Sat Aug  9 05:00:38 2008", "UTEND translates" );
