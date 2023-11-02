use Test::More;
use Test::Pod::Coverage 1.00;
pod_coverage_ok($_, { also_private => [ qr/^BUILDARGS$/ ] })
  for grep { $_ ne 'CPAN::Changes::HasEntries' } all_modules;
done_testing;
