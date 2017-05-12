# Initialize and destroy an instance to the library
use Test2::Bundle::More;
use Test::Alien 0.05;
use Alien::libvas;

alien_ok 'Alien::libvas';
my $xs = do { local $/; <DATA> };
diag "Checking libvas version";
xs_ok {xs => $xs, verbose => 1}, with_subtest {
    my($module) = @_;

    my $lib_ver    = $module->xs_version_lib;
    diag "library version $lib_ver\n";
    my $header_ver = $module->xs_version_header;
    diag "header  version $header_ver\n";

    is $lib_ver, $header_ver, "Header and library versions don't match!";
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <vas.h>

const char* xs_version_lib(const char *class) {
    return vas_get_version();
}

const char* xs_version_header(const char *class) {
    return VAS_VERSION;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *xs_version_lib(class);
 const char *class;

const char *xs_version_header(class);
 const char *class;
