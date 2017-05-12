
use strict;
use warnings;

use Test::More;

use Color::Library;
use Test::File::ShareDir::Dist { 'Color-Library-Dictionary-XKCD' => 'share' };

{
  my $windows_blue = Color::Library->color('windows blue');
  ok( !defined $windows_blue, 'windows blue is not in the default search space' );
}

{
  my $windows_blue = Color::Library->color( [qw/xkcd/] => 'windows blue' );
  ok( defined $windows_blue, 'windows blue is in the xkcd search space' );
}

{
  my $xkcd = Color::Library->XKCD();
  ok( defined $xkcd, 'XKCD returns something' );
  my $color = $xkcd->color('windows blue');
  ok( defined $color, "windows blue in the XKCD namespace" );
}
done_testing;
