use Test::More;
use Csistck;

plan tests => 4;

my $ret = host 'test' => noop(1), noop(0);
isa_ok($ret, 'ARRAY');

$ret = host('test');
isa_ok($ret, 'ARRAY');

for my $test (@{$ret}) {
    isa_ok($test, 'Csistck::Test');
}

