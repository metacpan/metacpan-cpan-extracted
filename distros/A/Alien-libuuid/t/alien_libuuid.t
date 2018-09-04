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

done_testing
