use Test::More;
use Csistck;

plan tests => 1;

my $ret = role 'test' => noop(1);
isa_ok($ret, 'CODE');

