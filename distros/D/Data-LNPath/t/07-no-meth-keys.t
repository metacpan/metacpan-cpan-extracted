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

use Data::LNPath qw/lnpath/, { errors => { allow_meth_keys => undef } };

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

is(eval{lnpath($data, 'four/magic({ a => "b" })')}, undef, 'ehhh');
sub thing {
	return $_[0] || 100;
}

done_testing();
