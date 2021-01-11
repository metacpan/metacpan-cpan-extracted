use strict;
use Test::More;
use FindBin qw/$Bin/;
use Audio::TinySoundFont;

use autodie;
use Try::Tiny;

my $tsf = Audio::TinySoundFont->new("$Bin/tiny.sf2");
{
  $tsf->note_on('');
  $tsf->note_off('');

  my $samples = $tsf->render;
  is( $tsf->is_active, '', 'note_off after 1 second does make it inactive' );

  $tsf->note_on('');
  $tsf->note_off('');
  my @samples = $tsf->render_unpack;
  is( $tsf->is_active, '', 'note_off after 1 second does make it inactive' );
  ok( pack( 's*', @samples ) eq $samples, 'TinySoundFont: render_unpack returns the same data as render' );
}

{
  my $preset  = $tsf->preset('');
  my $samples = $preset->render;
  my @samples = $preset->render_unpack;
  ok( pack( 's<*', @samples ) eq $samples, 'Preset: render_unpack returns the same data as render' );
}

{
  my $builder = $tsf->new_builder( [ { preset => '' } ] );
  my $samples = $builder->render;
  my @samples = $builder->render_unpack;
  ok( pack( 's<*', @samples ) eq $samples, 'Builder: render_unpack returns the same data as render' );

}

done_testing;
