use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Runtime;
#
class Exotic::Lsquic v1.0.0 : isa(Alien::Xrepo::Runtime) {
    method recipe { { name => 'Exotic-Lsquic', packages => ['lsquic'] } }
    }
    #
    1;
