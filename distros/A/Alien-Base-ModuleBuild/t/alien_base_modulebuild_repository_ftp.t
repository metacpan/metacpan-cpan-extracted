use Test2::V0 -no_srand => 1;
use Alien::Base::ModuleBuild::Repository::FTP;

is(
  Alien::Base::ModuleBuild::Repository::FTP->is_network_fetch,
  1
);

is(
  Alien::Base::ModuleBuild::Repository::FTP->is_secure_fetch,
  0
);

done_testing;

