# Actually use the library for something
# Here  it opens the perl interpreter's VAS
use Test2::Bundle::More;
use Test::Alien 0.05;
use Alien::libvas;

sub propagate_error {
    my $module = shift;
    diag 'vas_error: ' . $module->xs_vas_error if $module->xs_vas_error
}

alien_ok 'Alien::libvas';
my $xs = do { local $/; <DATA> };
xs_ok {xs => $xs, verbose => 1}, with_subtest {
    my($module) = @_;

    my $handle = $module->xs_vas_open($$); # Opening own VAS always succeeds
    propagate_error($module);
    ok $handle, "Opening own pid $$ => $handle";

    my $ptr = $module->xs_val(42);

    my $ret = $module->xs_vas_read($handle, $ptr);
    propagate_error($module);

    is $ret, 42, "Reading static variable";

    my $nbytes = $module->xs_vas_write($handle, $ptr, 1337);
    propagate_error($module);

    is $nbytes, $module->xs_sizeof_int, "Writing an int to static variable";

    isnt $module->xs_deref($module->xs_val(0)), 42;
    is $module->xs_deref($module->xs_val(0)), 1337, "Reading vas_written int";
    
    $module->xs_vas_close($handle);
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <vas.h>

void* xs_vas_open(const char *s, int pid) {
    return vas_open(pid, VAS_O_REPORT_ERROR);
}

int xs_vas_read(const char *s, void* vas, unsigned long src) {
    int dst;

    int nbytes = vas_read(vas, src, &dst, sizeof dst);

    return nbytes >= 0 ? dst : -1;
}

int xs_vas_write(const char *s, void* vas, unsigned long dst, int src) {
    int nbytes = vas_write(vas, dst, &src, sizeof src);
    return nbytes;
}

void xs_vas_close(const char *s, void *handle) {
    vas_close(handle);
}

const char *xs_vas_error(const char *s) {
    return vas_error(NULL);
}

void *xs_val(const char *s, int newval) {
    static int val;
    if (newval != 0)
        val = newval;

    return &val;
}

int xs_sizeof_int(const char *s) {
    return (int)sizeof (int);
}

int xs_deref(const char *s, void *ptr) {
    return *(int*)ptr;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

void *xs_vas_open(class, pid);
 const char *class;
 int pid;

void xs_vas_close(class, handle);
 const char *class;
 void *handle;

int xs_vas_write(class, handle, dst, src);
 const char *class;
 void *handle;
 unsigned long dst;
 int src;

int xs_vas_read(class, handle, src);
 const char *class;
 void *handle;
 unsigned long src;

const char *xs_vas_error(class);
 const char *class;

void *xs_val(class, newval);
 const char *class;
 int newval;

int xs_sizeof_int(class);
 const char *class;

int xs_deref(class, ptr);
 const char *class;
 void *ptr;

