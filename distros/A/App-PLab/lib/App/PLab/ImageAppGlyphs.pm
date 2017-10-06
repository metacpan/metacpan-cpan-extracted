package bga;

use constant next           => 0;
use constant prev           => 1;
use constant tile_m         => 2;
use constant cells          => 3;
use constant calcstatistics => 4;
use constant drawprocesses  => 5;
use constant processes      => 6;

package App::PLab::ImageAppGlyphs;

use Prima::StdBitmap;

my $testing = 0;
my $bmImageFile = Prima::Utils::find_image( '', "App::PLab::ImageApp.gif");

sub icon  { return Prima::StdBitmap::load_std_bmp( index => $_[0], icon => 1, copy => 0, file => $bmImageFile); }
sub image { return Prima::StdBitmap::load_std_bmp( index => $_[0], icon => 0, copy => 0, file => $bmImageFile); }

1;
