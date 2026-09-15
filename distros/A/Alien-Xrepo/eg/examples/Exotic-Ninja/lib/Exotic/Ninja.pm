use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Runtime;
#
class Exotic::Ninja v1.0.0 : isa(Alien::Xrepo::Runtime) {
    method recipe { { name => 'Exotic-Ninja', packages => [ { name => 'ninja' } ] } }
};
#
1;
