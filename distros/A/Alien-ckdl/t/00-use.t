use strict;
use warnings;
use Test::More tests => 3;

use_ok 'Alien::ckdl';

ok defined(Alien::ckdl->cflags), 'cflags defined';
ok defined(Alien::ckdl->libs),   'libs defined';

diag "cflags: " . Alien::ckdl->cflags;
diag "libs:   " . Alien::ckdl->libs;
