use strict;
use Test::More;
use FindBin qw/$Bin/;
use Audio::TinySoundFont;

use autodie;
use Try::Tiny;
use List::Util qw/sum/;

my $sf2_file = "$Bin/tiny.sf2";
my $tsf      = Audio::TinySoundFont->new($sf2_file);

sub p10
{
  my @samples = reverse sort unpack 's<*', shift;
  splice( @samples, int( @samples * .1 ) );
  return sum(@samples) / scalar(@samples);
}

# Volume
{
  $tsf->volume(-1.0);
  $tsf->note_on('');
  $tsf->note_off('');
  my $volneg1 = $tsf->render;

  $tsf->volume(-0.0001);
  $tsf->note_on('');
  $tsf->note_off('');
  my $volnsm = $tsf->render;

  $tsf->volume(0.0);
  $tsf->note_on('');
  $tsf->note_off('');
  my $vol0 = $tsf->render;

  # Because of how TSF handles the lower limit for gain, this is equal to 0.
  $tsf->volume(0.00001);
  $tsf->note_on('');
  $tsf->note_off('');
  my $volll = $tsf->render;

  $tsf->volume(0.0001);
  $tsf->note_on('');
  $tsf->note_off('');
  my $volsm = $tsf->render;

  $tsf->volume(0.5);
  $tsf->note_on('');
  $tsf->note_off('');
  my $vol05 = $tsf->render;

  $tsf->volume(0.9999);
  $tsf->note_on('');
  $tsf->note_off('');
  my $vol49s = $tsf->render;

  $tsf->volume(1.0);
  $tsf->note_on('');
  $tsf->note_off('');
  my $vol1 = $tsf->render;

  $tsf->volume(1.0001);
  $tsf->note_on('');
  $tsf->note_off('');
  my $volld = $tsf->render;

  $tsf->volume(2.0);
  $tsf->note_on('');
  $tsf->note_off('');
  my $vol2 = $tsf->render;

  # The ones that should be identical
  ok( $vol0 eq $volneg1, '0.0 and -1.0 are identical' );
  ok( $vol0 eq $volnsm,  '0.0 and -0.0001 are identical' );
  ok( $vol0 eq $volll,   '0.0 and 0.00001 are identical' );
  ok( $vol1 eq $volld,   '1.0 and 1.0001 are identical' );
  ok( $vol1 eq $vol2,    '1.0 and 2.0 are identical' );

  # The ones that should not be identical
  ok( $vol0 ne $volsm,  '0 and 0.0001 are not identical' );
  ok( $vol1 ne $vol49s, '1 and 0.9999 are not identical' );

  # Make sure the p10 is increasing in each case
  cmp_ok( p10($vol0),   '<', p10($volsm),  '0.0 is quieter than 0.0001' );
  cmp_ok( p10($volsm),  '<', p10($vol05),  '0.0001 is quieter than 0.5' );
  cmp_ok( p10($vol05),  '<', p10($vol49s), '0.5 is quieter than 0.9999' );
  cmp_ok( p10($vol49s), '<', p10($vol1),   '0.9999 is quieter than 1.0' );
}

done_testing;
