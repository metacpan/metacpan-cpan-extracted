use Test2::V0 -no_srand => 1;
use Alien::libuuid;
use Test::Alien;
use FFI::Platypus;
use FFI::Platypus::Memory qw( malloc free );

alien_ok 'Alien::libuuid';

ffi_ok with_subtest {
  my($ffi) = @_;

  my $uuid = malloc(16);
  $ffi->function(uuid_generate_random => ['opaque'] => 'void')->call($uuid);
  free($uuid);
  ok 1;
};

# First xs includes directly uuid.h 
my $xs = <<'EOF';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <uuid.h>

MODULE = libuuid PACKAGE = libuuid

void 
uuid_generate_random()
  CODE:
    uuid_t out;
    uuid_generate_random(out);
  OUTPUT: 

EOF

xs_ok $xs, with_subtest {
  libuuid::uuid_generate_random();
  ok 1;
};

# Second xs includes uuid/uuid.h 
# (related to uuid.pc.patch)
$xs = <<'EOF';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <uuid/uuid.h>

MODULE = libuuid PACKAGE = libuuid

void 
uuid_generate_random()
  CODE:
    uuid_t out;
    uuid_generate_random(out);
  OUTPUT: 

EOF

xs_ok $xs, with_subtest {
  libuuid::uuid_generate_random();
  ok 1;
};


done_testing
