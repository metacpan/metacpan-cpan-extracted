use strict;
use Test::More;
use Try::Tiny;
use FindBin qw/$Bin/;
use List::Util qw/sum/;
use Audio::TinySoundFont;

my $tsf = Audio::TinySoundFont->new("$Bin/tiny.sf2");
isnt( $tsf, undef, 'Can create a new object' );

my $preset = $tsf->preset('');
isnt( $preset, undef, 'Can get a preset' );

my $snd = $preset->render( seconds => 5, note => 59, vel => 0.7, volume => .3 );
isnt( $snd, undef, 'Render works' );
note( 'Length of $snd: ' . length $snd );
cmp_ok( length($snd), '>=', 2 * 44_100 * 5, 'Rendering is over 5 seconds' );
cmp_ok(
  length($snd), '<=', 2 * 44_100 * 6,
  'Rendering is also under 6 seconds'
);
unlike( $snd, qr/^\0*$/, 'Sample was not empty' );

# Volume
{
  my $ld_snd = $preset->render( seconds => 5, note => 59, vel => 0.7, volume => .5 );
  is( length $ld_snd, length $snd, 'A rerender causes an identical length' );
  unlike( $snd, qr/^\0*$/, 'Sample was not empty' );

  my @snds = reverse sort unpack 's<*', $snd;
  splice( @snds, int( @snds * .1 ) );
  my $sndp10 = sum(@snds) / scalar(@snds);

  my @ld_snds = reverse sort unpack 's<*', $ld_snd;
  splice( @ld_snds, int( @ld_snds * .1 ) );
  my $ld_sndp10 = sum(@ld_snds) / scalar(@ld_snds);
  cmp_ok( $ld_sndp10, '>', $sndp10, 'A higher volume creates a louder render' );

  $tsf->volume(0.5);
  my $df_snd = $preset->render( seconds => 5, note => 59, vel => 0.7 );
  ok( $df_snd eq $ld_snd, 'Using the main volume control works identically' );
}

# Amp and Volume
foreach ( [ 0.0, -110 ], [ 0.0, -100 ], [ 0.3, -10.457575 ], [ 0.97, -0.264565 ], [ 1.0, 0 ], [ 1.0, 10 ] )
{
  my ( $vol, $db ) = @$_;
  my $vol_snd = $preset->render( volume => $vol );
  my $db_snd  = $preset->render( db     => $db );
  ok( $vol_snd eq $db_snd, "volume $vol and db $db work correct" );
}

# Velocity and notes
{
  local $SIG{__WARN__} = sub { ok( 0, 'Warning is not expected' ) || note $_[0]; };

  my $vel_low_ib   = $preset->render( vel  => 0 );
  my $vel_high_ib  = $preset->render( vel  => 1 );
  my $note_low_ib  = $preset->render( note => 0 );
  my $note_high_ib = $preset->render( note => 127 );

  1e-10;
  local $SIG{__WARN__} = sub { like( $_[0], qr/^(Note|Velocity)/, 'Warning is one that is expected' ) || note $_[0]; };
  my $vel_low_oob   = $preset->render( vel  => 0 - 1e10 );
  my $vel_high_oob  = $preset->render( vel  => 1 + 1e10 );
  my $note_low_oob  = $preset->render( note => -1 );
  my $note_high_oob = $preset->render( note => 128 );

  ok( $vel_low_ib eq $vel_low_oob,     'Low velocity OOB value is the same as IB' );
  ok( $vel_high_ib eq $vel_high_oob,   'High velocity OOB value is the same as IB' );
  ok( $note_low_ib eq $note_low_oob,   'Low note OOB value is the same as IB' );
  ok( $note_high_ib eq $note_high_oob, 'High note OOB value is the same as IB' );
}

# Defaults
{
  my $base = $preset->render( seconds => 1, note => 60, vel => 0.5 );
  my $deft = $preset->render();
  ok( $base eq $deft, 'Defaults generate a 1 second clip as expected' );
}

# Samples
{
  my $smpl_snd = $preset->render( samples => Audio::TinySoundFont::SAMPLE_RATE() * 5 );
  is( length $snd, length $smpl_snd, 'Using the sample count also works' );
}

{
  $tsf->note_on('');
  my $error;
  my $snd = try { $preset->render( seconds => 5 ) } catch { $error = $_; undef };
  is( $snd, undef, 'A render while playing elsewhere fails' );
  like( $error, qr/is active/, 'Error is about TSF being active' );
}

done_testing;
