use strict;
use Test::More;
use FindBin qw/$Bin/;
use Audio::TinySoundFont;

use autodie;
use Try::Tiny;

{
  my $tsf = Audio::TinySoundFont->new("$Bin/tiny.sf2");
  is( $tsf->is_active, '', 'Fresh instance is inactive' );

  $tsf->note_on('');
  is( $tsf->is_active, 1, 'note_on makes it active' );
  is( $tsf->active_voices, 1, 'note_on sets the active_voices correctly');

  $tsf->note_off('');
  is( $tsf->is_active, 1, 'note_off immedietely does not makes it inactive' );

  $tsf->render( seconds => 5 );
  is( $tsf->is_active, '', 'note_off after 5 seconds does make it inactive' );
  is( $tsf->active_voices, 0, 'The active_voices is still correct');

  $tsf->note_on('', 60);
  $tsf->note_on('', 59);
  is( $tsf->active_voices, 2, 'Having 2 note_on calls sets active_voices correctly');
  $tsf->note_off('', 60);
  $tsf->note_off('', 59);
  $tsf->render( seconds => 5 );
  is( $tsf->is_active, '', 'note_off on each note works well' );
  is( $tsf->active_voices, 0, 'The active_voices is still correct');
}

# Error testing
{
  my $tsf = Audio::TinySoundFont->new("$Bin/tiny.sf2");
  my $error;
  try { $tsf->note_on } catch { $error = $_ };
  like($error, qr/Preset is required/, 'note_on croaks without a preset');

  try { $tsf->note_on(bless({}, 'NOPACKAGE') ) } catch { $error = $_ };
  like($error, qr/Audio::TinySoundFont::Preset/, 'Giving note_on a nonsense package produces an error');

  try { $tsf->note_off } catch { $error = $_ };
  like($error, qr/Preset is required/, 'note_off croaks without a preset');

  try { $tsf->note_off(bless({}, 'NOPACKAGE') ) } catch { $error = $_ };
  like($error, qr/Audio::TinySoundFont::Preset/, 'Giving note_off a nonsense package produces an error');

  is( $tsf->active_voices, 0, 'The active_voices is still correct');
}

done_testing;
