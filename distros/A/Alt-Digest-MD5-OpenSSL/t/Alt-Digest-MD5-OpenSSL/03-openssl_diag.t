use strict;
use warnings;

use Alien::OpenSSL;
use Test::Alien::Diag;
use Test::More 'tests' => 1;

alien_diag 'Alien::OpenSSL';
ok(1, 'Run OpenSSL diagnostics.');
