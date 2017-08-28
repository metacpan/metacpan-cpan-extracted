use strict;
use warnings;
use Alien::Libarchive3;
use Test::More tests => 1;

diag '';
diag '';
diag '';
diag '';

my $alien = Alien::Libarchive3->new;

diag 'libarchive';
diag '  cflags       : ', join ' ', $alien->cflags;
diag '  libs         : ', join ' ', $alien->libs;
diag '  install_type : ', $alien->install_type;

if($alien->can('version'))
{
  diag '  version      : ', (eval { $alien->version } || 'unknown');
}
else
{
  eval {
    require Archive::Ar::Libarchive;
    diag '  version      : ', Archive::Ar::Libarchive::_libarchive_version();
  };
}

diag '';
diag '';
diag '';

pass 'okay';
