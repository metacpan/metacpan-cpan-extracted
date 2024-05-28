use strict;
use warnings;
use Test::More;
#use Config;
use Test::Alien;
use Alien::gdal;

alien_ok 'Alien::gdal';


my $success = ffi_ok();


if (!$success) {
   diag ('libs: '   . Alien::gdal->libs);
   diag ('cflags: ' . Alien::gdal->cflags);
   eval {
       diag ('Dynamic libs: ' . join ':', Alien::gdal->dynamic_libs);
   };
   warn $@ if $@;
   
   diag ('bin dir: ' . join (' ', Alien::gdal->bin_dir));
   my @bin = Alien::gdal->bin_dir;
   warn "no gdal bin dir found via bin_dir method\n" if not @bin;
   #$bin = Alien::gdal->dist_dir . '/bin';
   my $datadir = Alien::gdal->data_dir;
   warn "no gdal data dir found via data_dir method\n" if not $datadir;
   diag "Data dir: $datadir";
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

