use Test2::V0 -no_srand => 1;
use 5.020;
use Archive::Libarchive::Lib;

ok(
  scalar Archive::Libarchive::Lib->lib,
  'has a lib'
);

isa_ok(
  Archive::Libarchive::Lib->ffi,
  'FFI::Platypus',
);

done_testing;
