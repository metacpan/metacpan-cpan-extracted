#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

{
	package Test::Obj;

	sub new { bless {}, shift };
	sub plus {
		my ($self, $one, $two) = @_; 
		my $plus = $one + $two;
		return $plus;
	}

	sub minus {
		my ($self, $one, $two) = @_; 
		my $minus = $one - $two;
		return $minus;
	}

	sub crazy_world {
		return $_[1] || 100;	
	}
	
	sub magic {
		my $self = shift;
		return $_[0];
	}
}

use Data::LNPath qw/lnpath/;

my $data = {
	one => {
		a => [qw/10 2 3/],
		b => { a => 10, b => 1, c => 1 },
		c => 1
	},
	two => [qw/1 2 3/],
	three => 10,
	four => Test::Obj->new(),
	five => 0,
};

sub thing {
	return $_[0] || 100;
}

is(lnpath($data, '/three'), 10, 'three');
is(lnpath($data, 'one/a/1'), 10, 'one->a->1');
is(lnpath($data, 'one/b/a'), 10, 'one->b->a');
is(lnpath($data, 'one/b/c'), 1, 'one->b->c');
is(lnpath($data, 'two/2'), 2, 'two->2');
is(lnpath($data, 'two/2/3/4'), 2, 'two->2->3->4');
is(lnpath($data, 'four/plus(10, 2)'), 12, 'four->plus(10, 2)');
is(lnpath($data, 'four/minus(200, crazy_world)'), 100, 'four->plus(200, crazy_world)');
is(lnpath($data, 'four/minus(200, crazy_world(50))'), 150, 'four->plus(200, crazy_world(50))');
is(lnpath($data, 'four/plus(200, &thing)'), 300, 'four->plus(200, &thing)');
is(lnpath($data, 'four/plus(200, &thing(50))'), 250, 'four->plus(200, &thing(50))');
is_deeply(lnpath($data, 'four/magic({ a => "b" })'), { a => 'b' }, 'hash');
is_deeply(lnpath($data, 'four/magic({a=>"b"})'), { a => 'b' }, 'hash');
is_deeply(lnpath($data, 'four/magic([ "a", "b" ])'), [ "a", "b" ], 'array');
is_deeply(lnpath($data, 'four/magic(["a","b"])'), [ "a", "b" ], 'array');
is_deeply(lnpath($data, 'four/magic([crazy_world,&thing])'), [ 100, 100 ], 'array');
is(lnpath($data, '/five'), 0, 'five');


done_testing();
