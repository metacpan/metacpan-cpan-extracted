use Test2::V0 -no_srand => 1;
use 5.020;
use Archive::Libarchive::DiskRead;
use Test::Archive::Libarchive;

subtest 'basic' => sub {

  my $dr = Archive::Libarchive::DiskRead->new;
  isa_ok $dr, 'Archive::Libarchive::DiskRead';

};

done_testing;
