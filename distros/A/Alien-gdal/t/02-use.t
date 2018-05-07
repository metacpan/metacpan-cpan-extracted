use strict;
use warnings;
use Test::More;
#use Config;
use Test::Alien;
use Alien::gdal;

alien_ok 'Alien::gdal';

diag ('libs: '   . Alien::gdal->libs);
diag ('cflags: ' . Alien::gdal->cflags);
diag ('Dynamic libs: ' . join ':', Alien::gdal->dynamic_libs);
diag ('bin dir: ', Alien::gdal->bin_dir);
my $bin = Alien::gdal->bin_dir;

#  nasty hack
$ENV{LD_LIBRARY_PATH} = Alien::gdal->dist_dir . '/lib';

#if ($^O !~ /mswin/i) {
    #diag join "", `ls -l $bin`;
    diag '=====';
    diag "Calling $bin/gdalwarp --version";
    diag join "\n", `$bin/gdalwarp --version`;
    diag '=====';
#}


TODO: {
    local $TODO = 'known to fail under several variants - help appreciated';
      #if $^O =~ /darwin|bsd/i;
    my $xs = do { local $/; <DATA> };
    xs_ok {xs => $xs, verbose => 1}, with_subtest {
      my($module) = @_;
      ok $module->version;
    };
}

#  check we can run one of the utilities
TODO: {
    local $TODO = 'There are known issues running utilities';

    run_ok([ "$bin/gdalwarp", '--version' ])
      ->success
      ->out_like(qr{GDAL \d+\.\d+\.\d+, released \d{4}/\d{2}/\d{2}}); 
}

done_testing();

 
__DATA__

//  A very simple test.  It really only tests that we can load gdal.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "stdio.h"
#include <gdal.h>

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

