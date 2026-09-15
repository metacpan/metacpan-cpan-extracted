use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Runtime;
#
class Exotic::Zstandard v1.0.0 : isa(Alien::Xrepo::Runtime) {
    method recipe { { name => 'Exotic-Zstandard', packages => [ { name => 'zstd', kind => 'shared' } ] } }
};
#
1;
