use strict;
use Test::More;
use Try::Tiny;
use FindBin qw/$Bin/;
use List::Util qw/sum/;
use Audio::TinySoundFont;

my $tsf = Audio::TinySoundFont->new("$Bin/tiny.sf2");
isnt( $tsf, undef, 'Can create a new object' );

# By Name
{
  my $preset = $tsf->preset('test');
  isnt( $preset, undef, 'Can get a preset' );
  is( $preset->name, 'test', 'Name is retrieved' );

  my $preset = try { $tsf->preset('not there') } catch { note $_; undef };
  is( $preset, undef, 'Non-existant preset returns undef' );
}

# By Index
{
  my $preset = $tsf->preset_index(0);
  isnt( $preset, undef, 'Can get a preset' );
  is( $preset->name, '', 'Name is retrieved' );

  my $preset = $tsf->preset_index(1);
  isnt( $preset, undef, 'Can get a preset' );
  is( $preset->name, 'test', 'Name is retrieved' );

  my $preset = try { $tsf->preset_index(2) } catch { note $_; undef };
  is( $preset, undef, 'Terminal preset returns undef' );

  my $preset = try { $tsf->preset_index(3) } catch { note $_; undef };
  is( $preset, undef, 'Non-existant preset returns undef' );
}

done_testing;
