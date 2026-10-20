use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Runtime;
#
class Exotic::Zlib v1.0.0 : isa(Alien::Xrepo::Runtime) {
    method recipe { { name => 'Exotic-Zlib', packages => [ { name => 'zlib' } ] } }
};
#
1;
