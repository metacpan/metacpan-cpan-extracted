use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::LibYAML;

skip_all 'test requires a dynamic build' unless Alien::LibYAML->dynamic_libs;

alien_ok 'Alien::LibYAML';

ffi_ok  { symbols => [ 'yaml_get_version_string' ] }, with_subtest {
  my($ffi) = @_;
  my $yaml_get_version_string = $ffi->function('yaml_get_version_string' => [] => 'string');
  ok $yaml_get_version_string->(), "has a version yo";
  note "yaml_get_version_string = ", $yaml_get_version_string->();
};

done_testing;
