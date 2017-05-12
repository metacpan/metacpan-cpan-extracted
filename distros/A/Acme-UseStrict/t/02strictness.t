use Test::Exception tests => 2;
use Acme::UseStrict qr/use strict/i;
no strict;

lives_ok {
	no Acme::UseStrict;
	*{"foo"} = sub {};
	foo();
	'use strict';
	*{"bar"} = sub {};
	bar();
}
	'Lives OK';

throws_ok {
	*{"foo"} = sub {};
	foo();
	'USE STRICT';
	*{"bar"} = sub {};
	bar();
}
	qr/symbol ref/,
	'Throws OK';
