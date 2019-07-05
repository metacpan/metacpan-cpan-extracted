use Test2::V0;
use Test::Alien;
use Alien::WhiteDB;

alien_ok 'Alien::WhiteDB';

xs_ok do { local $/; <DATA> }, with_subtest {
    my ($mod) = @_;
    is $mod->check(), 'ok';
}, 'xs';

ffi_ok { symbols => ['wg_attach_local_database'] }, 'ffi';

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <whitedb/dbapi.h>

const char * check(const char *class)
{
    void * test = wg_attach_local_database(10*1024*1024);
    wg_delete_local_database(test);
    return "ok";
}

MODULE = TA_WhiteDB PACKAGE = TA_WhiteDB

const char *check(class);
const char *class;
