#!perl -T

use strict;
use warnings;
use Test::More;

use Test::More tests => 5;
use Alien::FreeImage;

diag "CONFIG VALUES:";
diag "PREFIX='" . (Alien::FreeImage->config('PREFIX') || '') . "'";
diag "LIBS  ='" . (Alien::FreeImage->config('LIBS')   || '') . "'";
diag "INC   ='" . (Alien::FreeImage->config('INC')    || '') . "'";

like( Alien::FreeImage->config('LIBS'),   qr/.+/, "Testing non empty config('LIBS')" );
like( Alien::FreeImage->config('INC'),    qr/.+/, "Testing non empty config('INC')" );
like( Alien::FreeImage->config('PREFIX'), qr/.+/, "Testing non empty config('PREFIX')" );

SKIP: {
  is( (-d Alien::FreeImage->config('PREFIX')), 1, "Testing existance of 'PREFIX' directory" );
  is( (-f Alien::FreeImage->config('PREFIX') . '/FreeImage.h'), 1, "Testing existance of 'PREFIX/FreeImage.h'" );
}
