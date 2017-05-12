#!perl -w

use strict;
use Benchmark qw(:all);

use Class::Monadic;
use Object::Accessor;

{
	package CM;
	sub new{ bless {}, shift }
}
{
	package OA;
	our @ISA = qw(Object::Accessor);
	sub new{ bless{}, shift }
}

print "Create and add fields\n";

cmpthese -1 => {
	'Class::Monadic' => sub{
		my $o = CM->new();
		Class::Monadic->initialize($o)->add_field(qw(foo bar));
	},
	'Object::Accessor' => sub{
		my $o = OA->new();
		$o->mk_accessors(qw(foo bar));
	},
};

print "\nAnd field accesses\n";
cmpthese timethese -1 => {
	'Class::Monadic' => sub{
		my $o = CM->new();
		Class::Monadic->initialize($o)->add_field(qw(foo bar));
		for(1 .. 5){
			$o->set_foo($_);

			my $sum = 0;
			for(1 .. 5){
				$sum += $o->get_foo();
			}
			$sum == ($_ * 5) or die $sum;
		}
	},
	'Object::Accessor' => sub{
		my $o = OA->new();
		$o->mk_accessors(qw(foo bar));
		for(1 .. 5){
			$o->foo($_);

			my $sum = 0;
			for(1 .. 5){
				$sum += $o->foo();
			}
			$sum == ($_ * 5) or die $sum;
		}
	},
};
