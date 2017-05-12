use Test::More tests => 3;

use App::Rad;

# kids, don't try this at home...
my $c = {};
bless $c, 'App::Rad';
$c->_init();

is($c->cmd, undef, 'no command should be set upon startup');

$c->cmd = 'somecommand';
is($c->cmd, 'somecommand', 'developer should be able to set $c->cmd');

$c->command = 'anothercommand';
is($c->cmd, 'anothercommand', 'developer should be able to set $c->cmd');
