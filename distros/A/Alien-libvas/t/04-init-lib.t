# Initialize and destroy an instance to the library
use Test2::Bundle::More;
use Test::Alien 0.05;
use Alien::libvas;

alien_ok 'Alien::libvas';
my $xs = do { local $/; <DATA> };
xs_ok {xs => $xs, verbose => 1}, with_subtest {
    my($module) = @_;
    my $handle = $module->xs_vas_open($$); # Opening own VAS always succeeds
    ok $handle;
    $module->xs_vas_close($handle);
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <vas.h>

void* xs_vas_open(const char *s, int pid) {
    return vas_open(pid, 0);
}

void xs_vas_close(const char *s, void *handle) {
    vas_close(handle);
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

void *xs_vas_open(class, pid);
 const char *class;
 int pid;

void xs_vas_close(class, handle);
 const char *class;
 void *handle;

