#!perl -w

use strict;
use Test::More tests => 8;
use Test::Exception;
use Class::Monadic qw(:all);

my $foo = 0;
{
	package T;

	sub new{
		return bless {}, shift;
	}

	sub foo{ $foo++ }
}

my $t1 = T->new;
my $t2 = T->new;

my $before = 0;
my $after  = 0;
my $around = 0;
monadic($t1)->add_modifier(before => foo => sub{ $before++ });
monadic($t1)->add_modifier(around => foo => sub{ $around++ });
monadic($t1)->add_modifier(after  => foo => sub{ $after++ });

$t1->foo();
is $foo, 0;
is $before, 1;
is $around, 1;
is $after,  1;

$t2->foo();
is $foo, 1;
is $before, 1;
is $around, 1;
is $after,  1;
