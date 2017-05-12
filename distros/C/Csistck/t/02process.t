use Test::More;
use Csistck;
use Csistck::Test::Pkg;

plan tests => 4;

# First on NOOP
ok(noop(0)->execute('check')->isa('Csistck::Test::Return'), 
  'Test return type');
ok(noop(0)->execute('check')->failed, 'Test failed evaluation');
ok(noop(1)->execute('check')->passed, 'Test passed evaluation');
ok(noop(1)->execute('repair')->failed, 'Missing repair operation');

1;
