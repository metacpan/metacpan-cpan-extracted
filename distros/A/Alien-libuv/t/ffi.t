use Test2::V0;
use Test::Alien;
use Alien::libuv;

alien_ok 'Alien::libuv';
ffi_ok { symbols => ['uv_version_string'] }, with_subtest {
  my($ffi) = @_;
  my $version = $ffi->function(uv_version_string => [] => 'string')->call;
  ok $version, 'version returns okay';
  note "version=$version";  
};

done_testing;
