use Test2::V0;
use Test::Alien;
use Alien::OpenSSL;

skip_all 'Test does not (yet) work on cygwin' # TODO
  if $^O eq 'cygwin';

skip_all 'Test requires dynamic libs'
  unless Alien::OpenSSL->dynamic_libs;

alien_ok 'Alien::OpenSSL';

note "dynamic=$_" for Alien::OpenSSL->dynamic_libs;

ffi_ok with_subtest {
  my($ffi) = @_;
  $ffi->ignore_not_found(1);
  my $version_function = $ffi->function('OpenSSL_version' => ['int'] => 'string') ||
                         $ffi->function('SSLeay_version'  => ['int'] => 'string');
  ok($version_function, 'has SSLeay or OpenSSL _version function');
  if($version_function)
  {
    my $version = $version_function->call(0);
    ok $version, 'version function returns a value';
    note "version = $version";
  }
};

done_testing;
