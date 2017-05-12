BEGIN {
	use lib 't/lib';
	use strict;
	use warnings;
	use Test::More tests => 6;
	use_ok( 'CatalystX::self' );
	use_ok( 'MyTest' );
}

my $t = new MyTest;

ok($t,'Test package looks goo');
ok($t->can('this'),'self -> this');
ok($t->can('c'),'catalyst -> c');
ok($t->can('hiya'),'args -> hiya');

1;