use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::FFI;

alien_ok 'Alien::FFI';
my $xs = do { local $/; <DATA> };
xs_ok { xs => $xs, verbose => 1 }, with_subtest {
  my($module) = @_;
  is( test2(2), 4  );
  is( test2(6), 12 );
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <ffi.h>

/* chaar is the name of the planet the Decepticons retreated to after the fall of Unicron */
unsigned char doublechaar(unsigned char x)
{
  return x*2;
}

int
test2(unsigned char input_value)
{
  ffi_cif         ffi_cif;
  ffi_type       *args[1];
  void           *values[1];
  unsigned char   return_value;
  
  args[0] = &ffi_type_uint8;
  
  if(ffi_prep_cif(&ffi_cif, FFI_DEFAULT_ABI, 1, &ffi_type_uint8, args) == FFI_OK)
  {
    values[0] = &input_value;
    ffi_call(&ffi_cif, (void*) doublechaar, &return_value, values);
    return return_value;
  }
  return -1;
}

MODULE = main PACKAGE = main

int
test2(input_value);
    unsigned char input_value;
  CODE:
    RETVAL = test2(input_value);
  OUTPUT:
    RETVAL
