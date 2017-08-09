use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::Hunspell;
use lib 't/lib';
use Test2::Require::Dev;

alien_ok 'Alien::Hunspell';

my $xs = do { local $/; <DATA> };

xs_ok { xs => $xs, verbose => 1, cpp => 1 }, with_subtest {
  my $ptr = My::Hunspell::Hunspell_create("t/supp.aff","t/supp.dic");
  ok $ptr, "ptr = $ptr";
  My::Hunspell::Hunspell_destroy($ptr);
  ok 1, "did not crash";
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <hunspell.h>

MODULE = My::Hunspell PACKAGE = My::Hunspell

void *
Hunspell_create(affpath, dpath);
    const char *affpath;
    const char *dpath;

void
Hunspell_destroy(handle);
    void *handle;
