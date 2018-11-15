use strict;
use warnings;
use Test::More;
#use Config;
use Test::Alien;
use Alien::geos::af;

alien_ok 'Alien::geos::af';

diag ('libs: '   . Alien::geos::af->libs // '');
diag ('cflags: ' . Alien::geos::af->cflags // '');
eval {
    diag ('Dynamic libs: ' . join (':', Alien::geos::af->dynamic_libs));
};
warn $@ if $@;

diag ('bin dir: ' . Alien::geos::af->bin_dir // '== unable to locate bin dir ==');
#my $bin = Alien::geos::af->bin_dir // '';

#  nasty hack
$ENV{LD_LIBRARY_PATH}   = Alien::geos::af->dist_dir . '/lib';
$ENV{DYLD_LIBRARY_PATH} = Alien::geos::af->dist_dir . '/lib';


TODO: {
    local $TODO = 'known to fail under several variants - help appreciated';
      #if $^O =~ /darwin|bsd/i;
    my $xs = do { local $/; <DATA> };
    xs_ok {xs => $xs, verbose => 1}, with_subtest {
      my($module) = @_;
      ok $module->version;
    };
}


done_testing();

 
__DATA__

//  A very simple test.  It really only tests that we can load geos.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "stdio.h"
#include <geos.h>

int main()
{
   printf("Hello, World!");
   return 0;
}

const char *
version(const char *class)
{
   return "v1";
}

MODULE = TA_MODULE PACKAGE = TA_MODULE
 
const char *version(class);
    const char *class;

