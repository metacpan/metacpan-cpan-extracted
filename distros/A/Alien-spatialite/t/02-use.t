use strict;
use warnings;
use Test::More;
#use Config;
use Test::Alien;
use Alien::spatialite;

alien_ok 'Alien::spatialite';

#  nasty hack
$ENV{LD_LIBRARY_PATH}   = Alien::spatialite->dist_dir . '/lib';
$ENV{DYLD_LIBRARY_PATH} = Alien::spatialite->dist_dir . '/lib';


diag ('libs: '   . Alien::spatialite->libs);
diag ('cflags: ' . Alien::spatialite->cflags);
eval {
    diag ('Dynamic libs: ' . join ':', Alien::spatialite->dynamic_libs);
};
warn $@ if $@;

diag ('bin dir: ' . join (' ', Alien::spatialite->bin_dir));
my @bin = Alien::spatialite->bin_dir;
warn "no bin dir found via bin_dir method\n" if not @bin;

TODO: {
    local $TODO = 'leftover from gdal - might not need to be todo';
      #if $^O =~ /darwin|bsd/i;
    my $xs = do { local $/; <DATA> };
    xs_ok {xs => $xs, verbose => 1}, with_subtest {
      my($module) = @_;
      ok $module->version;
    };
}


done_testing();

 
__DATA__

//  A very simple test.  It really only tests that we can load proj4.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "stdio.h"
#include <spatialite.h>

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

