package Exotic::Raylib6;
use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Runtime;
#
class Exotic::Raylib6 v1.0.0 : isa(Alien::Xrepo::Runtime) {

    # raylib is built shared so ffi_lib-style consumers (Affix and FFI::Platypus) can attach
    # straight to the DLL; pinned to the 6.0 line so the resolved package never drifts out from
    # under the example.
    method recipe { { name => 'Exotic-Raylib6', packages => [ { name => 'raylib', version => '6.0.x', kind => 'shared' } ] } }
};
#
1;
