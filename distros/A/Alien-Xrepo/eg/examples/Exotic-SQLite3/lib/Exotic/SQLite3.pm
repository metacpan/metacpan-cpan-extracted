use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Runtime;
class Exotic::SQLite3 v1.0.0 : isa(Alien::Xrepo::Runtime) {
    method recipe { { name => 'Exotic-SQLite3', packages => [ { name => 'sqlite3', toolchain => 'mingw' } ] } }
};
#
1;
