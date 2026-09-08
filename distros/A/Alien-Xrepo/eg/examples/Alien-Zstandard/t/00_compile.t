use v5.40;
use blib;
use Test2::V0;
use Alien::Zstandard;
#
my $zstd = Alien::Zstandard->new;
isa_ok $zstd, ['Alien::Zstandard'],      'isa Alien::Zstandard';
isa_ok $zstd, ['Alien::Xrepo::Runtime'], 'isa Alien::Xrepo::Runtime';
is [ $zstd->package_names ], ['zstd'], 'package_names is zstd';
#
done_testing;
