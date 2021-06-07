use Test2::V0 -no_srand => 1;
use 5.020;
use Archive::Libarchive::EntryLinkResolver;

subtest 'basic' => sub {

  my $e = Archive::Libarchive::EntryLinkResolver->new;
  isa_ok $e, 'Archive::Libarchive::EntryLinkResolver';

};

done_testing;
