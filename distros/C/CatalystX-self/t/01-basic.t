BEGIN {
	use lib 't/lib';
	use strict;
	use warnings;
	use Test::More tests => 6;

	use_ok( 'CatalystX::self' );
	use_ok( 'MyTest' );
}

my $t = new MyTest;

ok($t,'Test package is intact');
ok($t->can('self'),'Test package has self');
ok($t->can('catalyst'),'Test package has catalyst');
ok($t->can('args'),'Test package has args');

1;
