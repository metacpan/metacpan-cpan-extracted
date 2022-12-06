use strict;
use warnings;
use Test::More;
#use Config;
use Test::Alien;
use Alien::freexl;

alien_ok 'Alien::freexl';

#  nasty hack
$ENV{LD_LIBRARY_PATH}   = Alien::freexl->dist_dir . '/lib';
$ENV{DYLD_LIBRARY_PATH} = Alien::freexl->dist_dir . '/lib';

diag ('Install type: ' . Alien::freexl->install_type);
diag ('libs: '   . Alien::freexl->libs);
diag ('cflags: ' . Alien::freexl->cflags);
eval {
    diag ('Dynamic libs: ' . join ':', Alien::freexl->dynamic_libs);
};
warn $@ if $@;

diag ('bin dir: ' . join (' ', Alien::freexl->bin_dir));
my @bin = Alien::freexl->bin_dir;
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
#include <freexl.h>

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

