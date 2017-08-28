use Test2::Bundle::More;
use Test::Alien 0.05;
use Alien::libpid;

alien_ok 'Alien::libpid';
my $xs = do { local $/; <DATA> };
xs_ok { xs => $xs, verbose =>1}, with_subtest {
    my($module) = @_;
    is $module->xs_pid_self, $$, "Getting own pid";
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libpid.h>

/* using unsigned long for portability */

unsigned long xs_pid_self(const char *s) {
    (void)s;
    return (unsigned long)pid_self();
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

unsigned long xs_pid_self(class);
 const char *class;

