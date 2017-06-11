#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 4;
use Alien::IUP;

diag "CONFIG VALUES:";
diag "PREFIX=" . (Alien::IUP->config('PREFIX') || '');
diag "INC   =" . (Alien::IUP->config('INC') || '');
diag "LIBS  =" . (Alien::IUP->config('LIBS') || '');

like( Alien::IUP->config('LIBS'), qr/.+/, "Testing non empty config('LIBS')" );
#note: INC and PREFIX might be empty, thus not testing here

SKIP: {
  skip 'Empty PREFIX (using already installed IUP)', 3 unless defined Alien::IUP->config('PREFIX');
  is( (-d Alien::IUP->config('PREFIX')), 1, "Testing existance of 'PREFIX' directory" );
  is( (-d Alien::IUP->config('PREFIX') . '/include'), 1, "Testing existance of 'PREFIX/include' directory" );
  is( (-d Alien::IUP->config('PREFIX') . '/lib'), 1, "Testing existance of 'PREFIX/lib' directory" );
}
