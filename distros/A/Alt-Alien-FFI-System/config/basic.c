#include <ffi.h>

int
my_foo(int i)
{
  if(i != 64)
    return 0;
  return 42;
}

int
main(int argc, char *argv[])
{
  ffi_cif cif;
  ffi_type *args[1];
  void *values[1];
  int in = 64;
  int ret;
  
  args[0] = &ffi_type_sint32;
  
  if(ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 1, &ffi_type_sint32, args) == FFI_OK)
  {
    values[0] = &in;
    ffi_call(&cif, (void*)my_foo, &ret, values);
    if(ret == 42)
      return 0;
  }
  
  return 2;
}
