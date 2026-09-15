use v5.40;
use blib;
use Test2::V0;
use Exotic::Zlib;
#
my $zlib = Exotic::Zlib->new;
isa_ok $zlib, ['Exotic::Zlib'],          'isa Exotic::Zlib';
isa_ok $zlib, ['Alien::Xrepo::Runtime'], 'isa Alien::Xrepo::Runtime';
is [ $zlib->package_names ], ['zlib'], 'package_names is zlib';
#
done_testing;
