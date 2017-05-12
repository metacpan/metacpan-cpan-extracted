# Initialize and destroy an instance to the library
use Test2::Bundle::More;
use Test::Alien 0.05;
use Acme::Alien::__cpu_model;

alien_ok 'Acme::Alien::__cpu_model';
my $xs = do { local $/; <DATA> };
diag 'Library at '. Acme::Alien::__cpu_model->libs;
xs_ok $xs, with_subtest {
    my($module) = @_;
    ok $module->__cpu_model_addr;
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

extern int __cpu_model;

void* __cpu_model_addr(const char *class) {
    (void)class;
    return &__cpu_model;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

void *__cpu_model_addr(class);
 const char *class;

