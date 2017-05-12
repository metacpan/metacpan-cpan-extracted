#!perl -w

use strict;
use constant HAS_THREADS => eval{ require threads };
use Test::More;

BEGIN{
	if($INC{'Devel/Cover.pm'}){
		plan skip_all => '(under -d:Cover)';
	}

	if(HAS_THREADS){
		plan tests => 17;
	}
	else{
		plan skip_all => 'requires threads';
	}

}

use threads;
use threads 'yield';
use threads::shared;

use Data::Util qw(:all);

BEGIN{
	package Foo;
	sub new{
		bless {} => shift;
	}
	package Bar;
	our @ISA = qw(Foo);

	package Baz;
	sub new{
		bless [] => shift;
	}
}

{
	ok is_instance(Foo->new, 'Foo'), 'in the main thread';
	ok is_instance(Bar->new, 'Foo');

	ok !is_instance(Baz->new, 'Foo');
}

my $thr1 = async{
	yield;
	ok is_instance(Foo->new, 'Foo'), 'in a thread (1)';
	yield;
	ok is_instance(Bar->new, 'Foo');
	yield;
	ok !is_instance(Baz->new, 'Foo');

	eval{
		instance(Foo->new, 'Bar');
	};
	like $@, qr/Validation failed/;

	return 1;
};

my $thr2 = async{
	yield;
	ok is_instance(Foo->new, 'Foo'), 'in a thread (2)';
	yield;
	ok is_instance(Bar->new, 'Foo');
	yield;
	ok !is_instance(Baz->new, 'Foo');

	eval{
		instance(Foo->new, 'Bar');
	};
	like $@, qr/Validation failed/;

	return 1;
};

{
	ok is_instance(Foo->new, 'Foo'), 'in the main thread';
	ok is_instance(Bar->new, 'Foo');

	ok !is_instance(Baz->new, 'Foo');

	eval {
		instance(Foo->new, 'Bar');
	};
	like $@, qr/Validation failed/;
}

ok $thr2->join(), 'join a thread (2)';
ok $thr1->join(), 'join a thread (1)';

