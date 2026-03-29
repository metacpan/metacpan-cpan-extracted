use Test2::V0;
use Test::Alien;
use Alien::libssh;

alien_ok 'Alien::libssh';

my $xs = <<'END';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libssh/libssh.h>

MODULE = MyAlienTest PACKAGE = MyAlienTest

int
can_ssh_new(klass)
    const char *klass
  CODE:
    ssh_session s = ssh_new();
    RETVAL = s ? 1 : 0;
    if (s) ssh_free(s);
  OUTPUT:
    RETVAL

END

xs_ok $xs, with_subtest {
    my ($module) = @_;
    ok $module->can_ssh_new, 'ssh_new() works via libssh';
};

done_testing;
