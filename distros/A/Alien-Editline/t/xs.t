use Test2::Bundle::Extended;
use Test::Alien;
use Alien::Editline;

alien_ok 'Alien::Editline';

xs_ok do { local $/; <DATA> }, with_subtest {
  plan 2;
  my $ptr = EditLine::history_init();
  ok $ptr, "ptr = $ptr";
  EditLine::history_end($ptr);
  ok 1, 'history_end did not crash!';
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <histedit.h>

MODULE = EditLine PACKAGE = EditLine

void *
history_init()

void
history_end(history)
    void *history;
