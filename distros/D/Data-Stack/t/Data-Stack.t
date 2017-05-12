use Test::More tests => 16;
BEGIN { use_ok('Data::Stack') };

my $estack = new Data::Stack();
ok(defined($estack), 'New Stack');
isa_ok($estack, 'Data::Stack', 'isa');
ok($estack->empty(), 'Stack is empty');

my @foo = (1, 2);
my $stack = new Data::Stack(@foo);
ok(defined($stack), 'New Stack w/items');
ok(!$stack->empty(), 'Stack is not empty');
ok($stack->count() == 2, 'Stack count');
ok($stack->pop() == $foo[0], 'Pop is right');
ok($stack->count() == 1, 'Stack count');
ok($stack->pop() == $foo[1], 'Pop is right');
ok($stack->count() == 0, 'Stack count');
ok($stack->empty(), 'Stack is empty');
$stack->push(20);
ok($stack->count() == 1, 'Stack count');
ok($stack->pop() == 20, 'Pop is right');
ok($stack->count() == 0, 'Stack count');
ok($stack->empty(), 'Stack is empty');
