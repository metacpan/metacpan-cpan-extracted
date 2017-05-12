use FindBin;
use lib $FindBin::RealBin . '/lib';
use Test::More tests => 4;

use App::Rad qw(MyStubPlugin);

# kids, don't try this at home...
my $c = {};
bless $c, 'App::Rad';
$c->_init();

can_ok($c, 'my_other_method');

$c->stash->{baz} = 'foo';
my $ret = $c->my_other_method(qw(some bar));

is($ret, 'foobar', 'plugin method calling');

eval {
    $c->_my_very_own();
};
ok($@, '_my_very_own() should be an internal plugin method');

my @plugins = $c->plugins;

my @plugins_expected = qw(MyStubPlugin);
is_deeply(\@plugins, \@plugins_expected, 'loaded plugins should match');
