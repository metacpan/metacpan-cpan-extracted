use Test::More;
use Test::Alien 0.05;
use Alien::HIDAPI;

alien_ok 'Alien::HIDAPI';
my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
    my($module) = @_;
    is $module->xs_hid_init, 0, "Initialize HIDAPI";
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <hidapi.h>

int xs_hid_init(const char *s) {
    (void)s;
    return hid_init();
}
MODULE = TA_MODULE PACKAGE = TA_MODULE

int xs_hid_init(class);
 const char *class;
