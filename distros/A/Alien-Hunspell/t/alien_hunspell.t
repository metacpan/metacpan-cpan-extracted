use Test2::V0 -no_srand => 1;
use Test::Alien::CPP;
use Alien::Hunspell;
use lib 't/lib';
use Test2::Require::Dev;

alien_ok 'Alien::Hunspell';

subtest 'xs' => sub {

  my $xs = do { local $/; <DATA> };

  xs_ok { xs => $xs, verbose => 1 }, with_subtest {
    my $ptr = My::Hunspell::Hunspell_create("corpus/supp.aff","corpus/supp.dic");
    ok $ptr, "ptr = $ptr";
    My::Hunspell::Hunspell_destroy($ptr);
    ok 1, "did not crash";
  };
};

subtest 'ffi' => sub {

  skip_all 'Test requires dynamic libraries' unless Alien::Hunspell->dynamic_libs;

  note "libs:";
  note "  - $_" for Alien::Hunspell->dynamic_libs;

  ffi_ok { symbols => [qw( Hunspell_create Hunspell_destroy )] }, with_subtest {
    my($ffi) = @_;


    $ffi->attach(Hunspell_create => ['string','string'] => 'opaque');
    my $ptr = Hunspell_create("corpus/supp.aff", "corpus/supp.dic");

    ok $ptr, "ptr = $ptr";

    $ffi->attach(Hunspell_destroy => ['opaque'] => 'void');
    Hunspell_destroy($ptr);

    ok 1, "did not crash";
  };
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
  CODE:
    Hunspell_destroy((Hunhandle*) handle);
