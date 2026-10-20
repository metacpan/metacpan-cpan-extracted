use v5.40;
use blib;
use Test2::V0;
use Exotic::Vcpkg::zlib;
#
my $vcpkg = Exotic::Vcpkg::zlib->new;
isa_ok $vcpkg, ['Exotic::Vcpkg::zlib'],   'isa Exotic::Vcpkg::zlib';
isa_ok $vcpkg, ['Alien::Xrepo::Runtime'], 'isa Alien::Xrepo::Runtime';
is [ $vcpkg->package_names ], [ 'vcpkg::zlib', 'vcpkg' ], 'package_names is vcpkg::zlib then the vcpkg tool';
#
done_testing;
