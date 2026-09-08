use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Runtime;

class Alien::lsquic : isa(Alien::Xrepo::Runtime) {

    method pkg_name {
        return [ { name => 'lsquic' } ];
    }
}
#
1;
