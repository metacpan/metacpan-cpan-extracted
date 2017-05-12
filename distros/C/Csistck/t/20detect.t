use Test::More;

plan tests => 4;

use Csistck;

my $pkgref = {
    dpkg => 'test-server',
    emerge => 'testd',
    pkg_info => 'net-test',
    default => 'test'
};

is(Csistck::Test::Pkg->new($pkgref, type => 'dpkg')->pkg_name, 'test-server');
is(Csistck::Test::Pkg->new($pkgref, type => 'emerge')->pkg_name, 'testd');
is(Csistck::Test::Pkg->new($pkgref, type => 'pkg_info')->pkg_name, 'net-test');
is(Csistck::Test::Pkg->new($pkgref, type => 'rpm')->pkg_name, 'test');

