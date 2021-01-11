use strict;
use Test::More;
use FindBin qw/$Bin/;
use Audio::TinySoundFont;

use autodie;
use List::Util qw/sum/;
use Try::Tiny;

{
  my $tsf      = Audio::TinySoundFont->new("$Bin/tiny.sf2");
  my $SR       = $tsf->SAMPLE_RATE;
  my @script_a = (
    {
      preset => '',
      note   => 59,
    },
    {
      preset => '',
      note   => 60,
    },
  );
  my @script_b = (
    {
      preset => '',
      note   => 61,
      at     => 1,
      for    => 3,
    },
    {
      preset => '',
      note   => 62,
      at     => 2,
      for    => 0.5
    },
  );
  my @script_c = (
    {
      preset     => '',
      note       => 63,
      at         => 5 * $SR,
      for        => 1 * $SR,
      in_seconds => 0,
    },
  );

  my $builder = $tsf->new_builder( [@script_a] );
  is( scalar @{ $builder->play_script }, 2, 'new with items did add items' );
  isnt( $builder->play_script->[0], $script_a[0], 'play_script[0] is not a ref to the original' );
  isnt( $builder->play_script->[1], $script_a[1], 'play_script[1] is not a ref to the original' );

  $builder = $tsf->new_builder;
  is( scalar @{ $builder->play_script }, 0, 'new without items did not add items' );

  my $error;
  try { $builder->set( [] ) } catch { $error = $_ };
  is( $error,                            undef, 'set with empty script without error' );
  is( scalar @{ $builder->play_script }, 0,     'set did not add items' );

  try { $builder->set( [@script_a] ) } catch { $error = $_ };
  is( $error,                            undef, 'set with simple script without error' );
  is( scalar @{ $builder->play_script }, 2,     'set did not add items' );

  try { $builder->add( [@script_b] ) } catch { $error = $_ };
  is( $error,                            undef, 'add with simple script without error' );
  is( scalar @{ $builder->play_script }, 4,     'add added items' );

  isnt( $builder->play_script->[0], $script_a[0], 'play_script[0] is not a ref to the original' );
  isnt( $builder->play_script->[1], $script_a[1], 'play_script[1] is not a ref to the original' );
  isnt( $builder->play_script->[2], $script_a[2], 'play_script[2] is not a ref to the original' );
  isnt( $builder->play_script->[3], $script_a[3], 'play_script[3] is not a ref to the original' );

  try { $builder->clear } catch { $error = $_ };
  is( $error,                            undef, 'clear with simple script without error' );
  is( scalar @{ $builder->play_script }, 0,     'clear cleared items' );

  $builder->add( [@script_a] );
  $builder->add( [@script_b] );
  $builder->add( [@script_c] );
  is( scalar @{ $builder->play_script }, 5, 'add added items' );

  my $all_snd = $builder->render;
  is( scalar @{ $builder->play_script }, 5, 'render did not remove items' );
  is( $tsf->active_voices,               0, 'render ends with no active voices' );

  $builder->clear;
  $builder->add( [@script_c] );
  my $c_snd = $builder->render;

  is( length $all_snd, length $c_snd, 'Using the last script item only produces an identical length' );
}

# Volume
{
  my $tsf = Audio::TinySoundFont->new("$Bin/tiny.sf2");
  my $builder = $tsf->new_builder( [ { preset => '' } ] );

    my $snd = $builder->render;
    my $ld1_snd = $builder->render( volume => .5 );
    my $ld2_snd = $builder->render( db => -20 );

    is( length $ld1_snd, length $snd, 'A rerender causes an identical length with volume given' );
    is( length $ld2_snd, length $snd, 'A rerender causes an identical length with db given' );
    unlike( $snd, qr/^\0*$/, 'Sample was not empty' );
    unlike( $ld1_snd, qr/^\0*$/, 'Loud Sample1 was not empty' );
    unlike( $ld2_snd, qr/^\0*$/, 'Loud Sample2 was not empty' );

    my @snds = reverse sort unpack 's<*', $snd;
    splice( @snds, int( @snds * .1 ) );
    my $sndp10 = sum(@snds) / scalar(@snds);

    my @ld1_snds = reverse sort unpack 's<*', $ld1_snd;
    splice( @ld1_snds, int( @ld1_snds * .1 ) );
    my $ld1_sndp10 = sum(@ld1_snds) / scalar(@ld1_snds);

    my @ld2_snds = reverse sort unpack 's<*', $ld2_snd;
    splice( @ld2_snds, int( @ld2_snds * .1 ) );
    my $ld2_sndp10 = sum(@ld2_snds) / scalar(@ld2_snds);

    cmp_ok( $ld1_sndp10, '>', $sndp10, 'A higher volume creates a louder render' );
    cmp_ok( $ld2_sndp10, '>', $sndp10, 'A higher volume creates a louder render' );

    $tsf->volume(0.5);
    my $df_snd = $builder->render;
    ok( $df_snd eq $ld1_snd, 'Using the main volume control works identically' );

}

# Check builder errors
{
  my $tsf = Audio::TinySoundFont->new("$Bin/tiny.sf2");
  my $builder = $tsf->new_builder( [ { preset => '' } ] );
  $tsf->note_on('');
  my $error;
  my $snd = try { $builder->render } catch { $error = $_; undef };
  is( $snd, undef, 'A render when there are active voices fails' );
  like( $error, qr/is active/, 'Error is about TSF being active' );

  $builder->clear;
  undef $error;
  try { $builder->add( {} ) } catch { $error = $_ };
  note $error;
  isnt( $error, undef, 'Error adding anything but an ArrayRef script items' );
  like( $error, qr/requires an ArrayRef/, 'Error refers to an ArrayRef' );

  undef $error;
  my $playscript_tsf = try { $tsf->new_builder( [] ) } catch { $error = $_; undef };
  isnt( $playscript_tsf, undef, 'Trying to add a play_script at construction works' );

  undef $error;
  my $error_tsf = try { $tsf->new_builder( {} ) } catch { $error = $_; undef };
  isnt( $error_tsf, undef, 'Trying to add single HashRef at construction does works' );

  undef $error;
  my $error_tsf = try { $tsf->new_builder( preset => '' ) } catch { $error = $_; undef };
  is( $error_tsf, undef, 'Trying to add a non-ArrayRef/HashRef play_script at construction fails' );
  note $error;
  isnt( $error, undef, 'Got an error trying to set non-ArrayRef/HashRef play_script' );
  like( $error, qr/must be a HashRef/, 'Error refers to an HashRef' );
}

done_testing;
