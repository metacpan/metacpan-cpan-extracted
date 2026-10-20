use v5.40;
use blib;
use Test2::V0;
use Exotic::Zstandard;
#
my $zstd = Exotic::Zstandard->new;
isa_ok $zstd, ['Exotic::Zstandard'],     'isa Exotic::Zstandard';
isa_ok $zstd, ['Alien::Xrepo::Runtime'], 'isa Alien::Xrepo::Runtime';
is [ $zstd->package_names ], ['zstd'], 'package_names is zstd';
#
done_testing;
