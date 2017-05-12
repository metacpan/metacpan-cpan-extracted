#!perl -T

use strict;
use warnings;
use Test::More;

use Test::More tests => 4;
use Alien::Tidyp;

diag "CONFIG VALUES:";
diag "LIBS=" . (Alien::Tidyp->config('LIBS') || '');
diag "INC=" . (Alien::Tidyp->config('INC') || '');
diag "PREFIX=" . (Alien::Tidyp->config('PREFIX') || '');

like( Alien::Tidyp->config('LIBS'), qr/.+/, "Testing non empty config('LIBS')" );
#note: INC and PREFIX might be empty, thus not testing here

SKIP: {
  skip 'Empty PREFIX (using already installed tidyp)', 3 unless defined Alien::Tidyp->config('PREFIX');
  is( (-d Alien::Tidyp->config('PREFIX')), 1, "Testing existance of 'PREFIX' directory" );
  is( (-d Alien::Tidyp->config('PREFIX') . '/include'), 1, "Testing existance of 'PREFIX/include' directory" );
  is( (-d Alien::Tidyp->config('PREFIX') . '/lib'), 1, "Testing existance of 'PREFIX/lib' directory" );
}
