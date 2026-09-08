use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Runtime;

class Alien::Zstandard : isa(Alien::Xrepo::Runtime) {

    # The xrepo package (and its per-package install profile). Declared here so
    # the consumer resolves without any build step; the xrepo.json recipe next
    # door carries the same declaration for the Alien::Xrepo::Build engine.
    method pkg_name {
        return [ { name => 'zstd', kind => 'shared' } ];
    }
}
#
1;
