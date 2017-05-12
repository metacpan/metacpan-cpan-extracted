#!perl -w

use strict;
use Benchmark qw(:all);

use FindBin qw($Bin);
use lib $Bin;
use Common;

use Data::Util qw(:all);
use Params::Util qw(_INSTANCE); # 0.35 provides a XS implementation
use Scalar::Util qw(blessed);

signeture
	'Data::Util'   => \&is_instance,
	'Params::Util' => \&_INSTANCE,
	'Scalar::Util' => \&blessed,
;

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

	package Unrelated;
	our @ISA = qw(Base);

	package SpecificIsa;
	our @ISA = qw(Base);
	sub isa{
		$_[1] eq 'Foo';
	}
}

foreach my $x (Foo->new, Foo::X::X::X->new, Unrelated->new, undef, {}){
	print 'For ', neat($x), "\n";

	my $i = 0;

	cmpthese -1 => {
		'blessed' => sub{
			for(1 .. 10){
				$i++ if blessed($x) && $x->isa('Foo');
			}
		},
		'_INSTANCE' => sub{
			for(1 .. 10){
				$i++ if _INSTANCE($x, 'Foo');
			}
		},
		'is_instance' => sub{
			for(1 .. 10){
				$i++ if is_instance($x, 'Foo');
			}
		},
	};

	print "\n";
}
