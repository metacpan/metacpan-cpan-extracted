use strict;
use warnings;
use Test::More;
#use Config;
use Test::Alien;
use Alien::Proj4;

alien_ok 'Alien::Proj4';

#  nasty hack
$ENV{LD_LIBRARY_PATH}   = Alien::Proj4->dist_dir . '/lib';
$ENV{DYLD_LIBRARY_PATH} = Alien::Proj4->dist_dir . '/lib';


diag ('libs: '   . Alien::Proj4->libs);
diag ('cflags: ' . Alien::Proj4->cflags);
eval {
    diag ('Dynamic libs: ' . join ':', Alien::Proj4->dynamic_libs);
};
diag $@ if $@;

diag ('bin dir: ' . join (' ', Alien::Proj4->bin_dir));
my @bin = Alien::Proj4->bin_dir;
diag "no proj bin dir found via bin_dir method\n" if not @bin;

diag 'Checking dynamic lib existence';
foreach my $file (Alien::Proj4->dynamic_libs) {
    my $exists = -e $file;
    my $is_link = -l $file;
    diag "$file "
        . ($exists  ? 'exists' : 'cannot be found')
        . ', and '
        . ($is_link ? 'is a symbolic link ' : 'is not a symbolic link');
}


#  some very basic tests for the projection info
my $info = eval {
    Alien::Proj4->load_projection_information
};
is $@, '', 'got projection information without error';
#  could check some of the hash contents, but not sure it's worth it
is ref $info, 'HASH', 'projection info is a hash ref'
  or diag explain $info;

TODO: {
    local $TODO = 'leftover from gdal, not sure we even need it given the planned usage';
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
#include <proj.h>

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

