use Test::Alien;
use Test2::Tools::Basic;
use Alien::pkgconf;

alien_ok 'Alien::pkgconf';

run_ok(['pkgconf', '--version'])
  ->success
  ->note;

my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
  ok( Foo::pkgconf_compare_version("1.2.3","1.2.3") == 0 );
  ok( Foo::pkgconf_compare_version("1.2.3","1.2.4") != 0 );
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
