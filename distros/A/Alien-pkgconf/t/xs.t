use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::pkgconf;

alien_ok 'Alien::pkgconf';

run_ok(['pkgconf', '--version'])
  ->success
  ->note;

my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
  ok( Foo::pkgconf_compare_version("1.2.3","1.2.3") == 0 );
  ok( Foo::pkgconf_compare_version("1.2.3","1.2.4") != 0 );

  cmp_ok( Foo::pkgconf_version(), ">", 10502, "pkgconf is at least 1.5.2" );
  note "version = @{[ Foo::pkgconf_version() ]}";

  # For now 1.9.x is unfortunately not supported 
  cmp_ok( Foo::pkgconf_version(), "<", 10900, "pkgconf is not 1.9.x or 2.x" );
};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libpkgconf/libpkgconf.h>

MODULE = Foo PACKAGE = Foo

int
pkgconf_compare_version(a,b)
    const char *a;
    const char *b;

int
pkgconf_version()
  CODE:
    RETVAL = LIBPKGCONF_VERSION;
  OUTPUT:
    RETVAL
