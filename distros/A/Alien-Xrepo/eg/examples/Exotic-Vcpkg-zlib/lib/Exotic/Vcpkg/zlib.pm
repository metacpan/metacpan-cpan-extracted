use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Runtime;
#
class Exotic::Vcpkg::zlib v1.0.0 : isa(Alien::Xrepo::Runtime) {
    method recipe { { name => 'Exotic-Vcpkg-zlib', packages => [ { name => 'vcpkg::zlib' }, { name => 'vcpkg' } ] } }
};
#
1;
