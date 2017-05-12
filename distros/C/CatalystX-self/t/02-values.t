BEGIN {
	use lib 't/lib';
	use strict;
	use warnings;
	use Test::More tests => 7;

	use_ok( 'CatalystX::self' );
	use_ok( 'MyTest' );
}

my $t = new MyTest;

ok($t,'Test package is intact');
ok($t->test_self eq $t,'self looks intact');
ok($t->test_catalyst('cat') eq 'cat','catalyst looks intact');
ok(scalar($t->test_args('cat','one','two')) == 2,'args looks intact');
ok(ref(($t->test_args('cat',{}))[0]) eq 'HASH','ref to args looks correct');
1;
