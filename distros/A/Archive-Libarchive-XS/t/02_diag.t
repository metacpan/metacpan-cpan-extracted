use strict;
use warnings;
use Alien::Libarchive;
use Test::More tests => 1;

diag '';
diag '';
diag '';
diag '';

my $alien = Alien::Libarchive->new;

diag 'libarchive';
diag '  cflags       : ', join ' ', $alien->cflags;
diag '  libs         : ', join ' ', $alien->libs;
diag '  install_type : ', $alien->install_type;
diag '  dlls         : ', (eval { $alien->dlls } || 'not found');
diag '  version      : ', (eval { $alien->version } || 'unknown');

diag '';
diag '';
diag '';

pass 'okay';
