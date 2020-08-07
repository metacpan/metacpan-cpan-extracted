use Test2::V0;
use Test::Alien;
use Alien::Sodium;

skip_all 'requires a shared object or DLL'
  unless Alien::Sodium->dynamic_libs;

alien_ok 'Alien::Sodium';
ffi_ok { symbols => ['sodium_version_string'] }, with_subtest {
  my($ffi) = @_;
  my $version = $ffi->function(sodium_version_string => [] => 'string')->call;
  ok $version, 'version returns okay';
  note "version=$version";
};

done_testing;
