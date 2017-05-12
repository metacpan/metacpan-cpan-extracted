#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;

use AnyEvent;
use AnyEvent::Delay::Simple qw(delay easy_delay);


local $ENV{PERL_ANYEVENT_LOG} = 'log=nolog';

BEGIN {
	package FooBar;

	sub new { return bless({}, shift()); }

	sub foo { pop()->send('baz'); }

	sub bar { $_[0]->{qux} = $_[1]; }

	package FooBarEasy;

	sub new { return bless({}, shift()); }

	sub foo { return 'baz'; }

	sub bar { $_[0]->{qux} = $_[1]; }
}


my $cv  = AE::cv;
my $obj = FooBar->new;

delay(
	$obj,
	\&FooBar::foo,
	\&FooBar::bar,
	sub {
		$cv->send();
		fail();
	},
	sub {
		my $self = shift();

		$cv->send();

		ok @_ == 1; # cv
		is ref($self), 'FooBar';
		cmp_deeply {%$self}, {qux => 'baz'};
	},
);
$cv->recv();

$cv  = AE::cv;
$obj = FooBar->new;

delay(
	$obj,
	\&FooBar::foo,
	sub {
		ok @_ == 3;
		is ref($_[0]), 'FooBar';
		is $_[1], 'baz';

		die();
	},
	\&FooBar::bar,
	sub {
		$cv->send();

		ok @_ == 3;
		is ref($_[0]), 'FooBar';
	},
	sub {
		$cv->send();
		fail();
	},
);
$cv->recv();

$cv  = AE::cv;
$obj = FooBarEasy->new;

easy_delay(
	$obj,
	\&FooBarEasy::foo,
	\&FooBarEasy::bar,
	sub {
		$cv->send();
		fail();
	},
	sub {
		my $self = shift();

		$cv->send();

		ok @_ == 1;
		is ref($self), 'FooBarEasy';
		cmp_deeply {%$self}, {qux => 'baz'};
		is $_[0], 'baz';
	},
);
$cv->recv();

$cv  = AE::cv;
$obj = FooBarEasy->new;

easy_delay(
	$obj,
	\&FooBarEasy::foo,
	sub {
		ok @_ == 2;
		is ref($_[0]), 'FooBarEasy';
		is $_[1], 'baz';

		die();
	},
	\&FooBarEasy::bar,
	sub {
		$cv->send();
		ok @_ == 2;
		is ref($_[0]), 'FooBarEasy';
	},
	sub {
		$cv->send();
		fail();
	},
);
$cv->recv();


done_testing;
