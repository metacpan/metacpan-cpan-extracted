use strict;
use warnings;
use Alien::Libarchive::Installer;
use Test::More tests => 1;

diag '';
diag '';
diag '';
diag '';

my $alien = Alien::Libarchive::Installer->system_install( test => "ffi" );

diag 'libarchive';
diag '  cflags       : ', join ' ', @{ $alien->cflags };
diag '  libs         : ', join ' ', @{ $alien->libs };
diag '  dlls         : ', (eval { join ' ', $alien->dlls } || "not found: $@");
diag '  version      : ', (eval { $alien->version } || 'unknown');

diag '';
diag '';
diag '';

pass 'okay';
