#!perl -w

use strict;
use Benchmark qw(:all);

use Class::Monadic qw(monadic);
use Object::Accessor;

{
	package CM;
	sub new{ bless {}, shift }
}
{
	package M;
	use Mouse;

	has foo =>
		is => 'rw',
	;
	__PACKAGE__->meta->make_immutable();
}

print "Create and add fields\n";

cmpthese -1 => {
	'Class::Monadic' => sub{
		my $o = CM->new();
		monadic($o)->add_field('foo');
	},
	'Mouse' => sub{
		my $o = M->new();
	},
};

print "\nField accesses\n";
my $cm = CM->new;
monadic($cm)->add_field('foo');

my $m = M->new;

cmpthese timethese -1 => {
	'Class::Monadic' => sub{
		for(1 .. 5){
			$cm->set_foo($_);

			my $sum = 0;
			for(1 .. 5){
				$sum += $cm->get_foo();
			}
			$sum == ($_ * 5) or die $sum;
		}
	},
	'Mouse' => sub{
		for(1 .. 5){
			$m->foo($_);

			my $sum = 0;
			for(1 .. 5){
				$sum += $m->foo();
			}
			$sum == ($_ * 5) or die $sum;
		}
	},
};
