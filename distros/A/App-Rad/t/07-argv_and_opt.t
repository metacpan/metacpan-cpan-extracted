use Test::More tests => 18;

use App::Rad;

@ARGV = qw(commandname bla -x -abc --def --test1=2 --test2=test ble -vvv -x);

# kids, don't try this at home...
my $c = {};
bless $c, 'App::Rad';
$c->_init();
$c->_get_input();

is(scalar @ARGV, 9, '@ARGV should have 6 elements');
is(scalar @{$c->argv}, 2, '$c->argv should have 2 arguments');
is(keys %{$c->options}, 8, '$c->options should have 6 elements');

is($c->cmd, 'commandname', 'command name should be set');

is_deeply(\@ARGV, ['bla', '-x', '-abc', '--def', '--test1=2', '--test2=test', 'ble', '-vvv', '-x'], 
   '@ARGV should have just the passed arguments, not the command name'
  );

is_deeply($c->argv, ['bla', 'ble'], '$c->argv arguments should be consistent');
is($c->options->{'a'}, 1, "'-a' should be set");
is($c->options->{'b'}, 1, "'-b' should be set");
is($c->options->{'c'}, 1, "'-c' should be set");

ok(!defined $c->options->{'abc'}, "'--abc' should *not* be set");
ok(!defined $c->options->{'d'}  , "'-d' should *not* be set");
ok(!defined $c->options->{'e'}  , "'-e' should *not* be set");
ok(!defined $c->options->{'f'}  , "'-f' should *not* be set");

ok(defined $c->options->{'def'}, "'--def' should be set");
is($c->options->{'test1'}, 2, "'--test1' should be set to '2'");
is($c->options->{'test2'}, 'test', "'--test2' should be set to 'test'");
is($c->options->{'v'}, 3, "single arguments can be incremented when put together");
is($c->options->{'x'}, 2, "single arguments can be incremented when invoked separately");
