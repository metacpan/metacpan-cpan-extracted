use Test2::V0;
use Test::Alien;
use Alien::FluentBit;

alien_ok 'Alien::FluentBit';
note 'cflags '.Alien::FluentBit->cflags;
note 'libs '.Alien::FluentBit->libs;
note 'bin_dir '.Alien::FluentBit->bin_dir;

ok( -x Alien::FluentBit->fluentbit, 'fluent-bit executable' );

# Workaround bug where Test::Alien doesn't rewrite the rpath
# It needs to point to the temp dir, not the final perl lib install dir
my $libs= Alien::FluentBit->libs;
my ($libpath)= ($libs =~ m{-L(/\S+)});
$libs =~ s{-Wl,-rpath,(/\S+)}{-Wl,-rpath,$libpath};
local *Alien::FluentBit::libs= sub { $libs };
local *Alien::FluentBit::libs_static= sub { $libs };
local *Alien::FluentBit::libs_dynamic= sub { $libs };

xs_ok { xs => do { local $/; <DATA> }, verbose => 1 }, with_subtest {
   is TestFluent::loadit(), 1, 'Created fluentbit context';
};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <fluent-bit-minimal.h>

MODULE = TestFluent PACKAGE = TestFluent
 
int
loadit()
   INIT:
      flb_ctx_t *ctx;
   CODE:
      if ((ctx= flb_create()) != NULL) {
         RETVAL= 1;
         flb_destroy(ctx);
      } else {
         RETVAL= 0;
      }
   OUTPUT:
      RETVAL
