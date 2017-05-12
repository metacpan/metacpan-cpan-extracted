use Test::More tests => 7;

use App::Rad;

# kids, don't try this at home...
my $c = {};
bless $c, 'App::Rad';
$c->_init();

$c->register_commands({
        -ignore_prefix => '_',
        -ignore_suffix => 'cmd',
        -ignore_regexp => '\d',
});

sub foo { return 'hello'; }

sub _foo { return 'internal _foo!!!'; }

sub foocmd { return 'internal foocmd!!!'; }

sub foo1bar { return 'internal foo1bar!!!'; }

sub bar { return 'hi'; }

sub default { return 'This is default. Over and out.'; }

ok(!$c->is_command('default'), '"default" must not be set as a command');
ok($c->is_command('bar'), 'bar should be a valid command');
ok($c->is_command('foo'), 'foo should be a valid command');
ok($c->is_command('help'), 'help should be a valid command');
ok(!$c->is_command('_foo'), '_foo should *not* be a valid command');
ok(!$c->is_command('foocmd'), 'foocmd should *not* be a valid command');
ok(!$c->is_command('foo1bar'), 'foo1bar should *not* be a valid command');

