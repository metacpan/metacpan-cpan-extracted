#!perl -w

use strict;
use Test::More tests => 8;

use Class::Monadic qw(:all);

{
	package T1;
	my $count = 0;
	sub new{
		$count++;
		return bless {}, shift;
	}
	sub count{ $count }
	sub DESTROY{ $count-- }
}
{
	package T2;
	my $count = 0;
	sub new{
		$count++;
		return bless {}, shift;
	}
	sub count{ $count }
	sub DESTROY{ $count-- }
}

is(T1->count, 0);
is(T2->count, 0);

for my $i(1 .. 2){
	my $x = T1->new;
	my $c = T2->new;

	monadic($x)->add_method(foo => sub{ $c });


	is(T1->count, 1, 'object');
	is(T2->count, 1, 'meta');
}

is(T1->count, 0, 'object');
is(T2->count, 0, 'meta');
