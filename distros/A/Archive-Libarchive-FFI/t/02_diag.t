use strict;
use warnings;
use Alien::Libarchive3;
use Test::More tests => 1;

diag '';
diag '';
diag '';
diag '';

my $alien = 'Alien::Libarchive3';

diag 'libarchive';
diag '  cflags       : ', $alien->cflags;
diag '  libs         : ', $alien->libs;
diag '  dlls         : ', $_ for $alien->dynamic_libs;
diag '  version      : ', $alien->version;

diag '';
diag '';
diag '';

pass 'okay';
