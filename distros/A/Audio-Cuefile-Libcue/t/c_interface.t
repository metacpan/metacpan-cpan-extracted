#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 35;
BEGIN { use_ok( 'Audio::Cuefile::Libcue', qw( :all ) ) }

#########################

use constant FPS => 75;

sub MSF_TO_F {
  my ( $m, $s, $f ) = @_;
  return ( $f + ( $m * 60 + $s ) * FPS );
}

#########################

# sample cue sheet to use
my $cue = do {
  open my $fh, '<', 't/standard.cue' or die "Failed to open standard.cue: $!";
  local $/ = undef;
  <$fh>;
};

my $cd = cue_parse_string($cue);
ok( $cd, "error parsing CUE" );

my $rem = $cd->cd_get_rem;
ok( $rem, "error getting REM" );

my $cdtext = cd_get_cdtext($cd);
ok( $cdtext, "error getting CDTEXT" );

my $val;
$val = cdtext_get( Audio::Cuefile::Libcue::PTI_PERFORMER, $cdtext );
ok( $val, "error getting CD performer" );
is( $val, "My Bloody Valentine", "error validating CD performer" );

$val = cdtext_get( Audio::Cuefile::Libcue::PTI_TITLE, $cdtext );
ok( $val, "error getting CD title" );
is( $val, "Loveless", "error validating CD title" );

my ( $ival, $track );
$val = cdtext_get( Audio::Cuefile::Libcue::PTI_GENRE, $cdtext );
ok( $val, "error getting CD genre" );
is( $val, "Alternative", "error validating CD genre" );

$val = rem_get( Audio::Cuefile::Libcue::REM_DATE, $rem );
ok( $val, "error getting CD date" );
is( $val, "1991", "error validating CD date" );

$ival = cd_get_ntrack($cd);
is( $ival, 2, "invalid number of tracks" );

# Track 1
$track = cd_get_track( $cd, 1 );
ok( $track, "error getting track" );

$val = track_get_filename($track);
ok( $val, "error getting track filename" );
is( $val, "My Bloody Valentine - Loveless.wav", "error validating track filename" );

$cdtext = track_get_cdtext($track);
ok( $cdtext, "error getting track CDTEXT" );

$val = cdtext_get( Audio::Cuefile::Libcue::PTI_PERFORMER, $cdtext );
ok( $val, "error getting track performer" );
is( $val, "My Bloody Valentine", "error validating track performer" );

$val = cdtext_get( Audio::Cuefile::Libcue::PTI_TITLE, $cdtext );
ok( $val, "error getting track title" );
is( $val, "Only Shallow", "error validating track title" );

$ival = track_get_start($track);
is( $ival, 0, "invalid track start" );
$ival = track_get_length($track);
is( $ival, MSF_TO_F( 4, 17, 52 ), "invalid track length" );

$ival = track_get_index( $track, 1 );
is( $ival, 0, "invalid index" );

# Track 2
$track = cd_get_track( $cd, 2 );
ok( $track, "error getting track" );

$val = track_get_filename($track);
ok( $val, "error getting track filename" );
is( $val, "My Bloody Valentine - Loveless.wav", "error validating track filename" );

$cdtext = track_get_cdtext($track);
ok( $cdtext, "error getting track CDTEXT" );

$val = cdtext_get( Audio::Cuefile::Libcue::PTI_PERFORMER, $cdtext );
ok( $val, "error getting track performer" );
is( $val, "My Bloody Valentine", "error validating track performer" );

$val = cdtext_get( Audio::Cuefile::Libcue::PTI_TITLE, $cdtext );
ok( $val, "error getting track title" );
is( $val, "Loomer", "error validating track title" );

$ival = track_get_start($track);
is( $ival, MSF_TO_F( 4, 17, 52 ), "invalid track start" );
$ival = track_get_length($track);
is( $ival, -1, "invalid track length" );

$ival = track_get_index( $track, 1 );
is( $ival, MSF_TO_F( 4, 17, 52 ), "invalid index" );
