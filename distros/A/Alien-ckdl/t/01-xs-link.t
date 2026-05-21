use strict;
use warnings;
use Test::More;
use Test::Alien;
use Alien::ckdl;

# Smoke-test: compile a tiny C program against the freshly installed ckdl,
# create a string parser, run a single event, and verify it returns a node.
alien_ok 'Alien::ckdl';

xs_ok { xs => <<'XS', with_subtest => sub {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <kdl/kdl.h>

int kdl_smoketest()
{
    kdl_str doc = kdl_str_from_cstr("hello \"world\"\n");
    kdl_parser* p = kdl_create_string_parser(doc, KDL_DEFAULTS);
    if (!p) return -1;

    kdl_event_data* ev = kdl_parser_next_event(p);
    int ok = (ev != NULL && ev->event == KDL_EVENT_START_NODE);

    kdl_destroy_parser(p);
    return ok ? 1 : 0;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

int kdl_smoketest()
XS
    my ($module) = @_;
    is $module->kdl_smoketest, 1, 'parsed a node via ckdl';
}};

done_testing;
