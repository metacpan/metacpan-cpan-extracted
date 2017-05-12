#!perl -w

use strict;
use Benchmark qw(:all);

use FindBin qw($Bin);
use lib $Bin;
use Common;

use Data::Util qw(:all), @ARGV;
use Params::Util qw(_INVOCANT);

signeture 'Data::Util' => \&is_invocant, 'Params::Util' => \&_INVOCANT;

BEGIN{
	package Base;
	sub new{
		bless {} => shift;
	}
	
	package Foo;
	our @ISA = qw(Base);
	package Foo::X;
	our @ISA = qw(Foo);
	package Foo::X::X;
	our @ISA = qw(Foo::X);
	package Foo::X::X::X;
	our @ISA = qw(Foo::X::X);
}

print "Benchmark: Data::Util::is_invocant() vs. Params::Util::_INVOCANT() vs. eval{}\n";

foreach my $x (Foo->new, Foo::X::X::X->new(), 'Foo', 'Foo::X::X::X', undef, {}){
	print 'For ', neat($x), "\n";

	my $i = 0;

	cmpthese -1 => {
		'eval{}' => sub{
			for(1 .. 10){
				$i++ if eval{ $x->VERSION; 1 };
			}
		},
		'_INVOCANT' => sub{
			for(1 .. 10){
				$i++ if _INVOCANT($x);
			}
		},
		'is_invocant' => sub{
			for(1 .. 10){
				$i++ if is_invocant($x);
			}
		},
	};

	print "\n";
}
