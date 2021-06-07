use Test2::V0 -no_srand => 1;
use 5.020;
use Archive::Libarchive::Match;

subtest 'basic' => sub {

  my $w = Archive::Libarchive::Match->new;
  isa_ok $w, 'Archive::Libarchive::Match';

};

done_testing;
