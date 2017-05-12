#!perl -w

use strict;

use Benchmark qw(:all);

use FindBin qw($Bin);
use lib $Bin;
use Common;

use Data::Util qw(:all);

signeture 'Data::Util' => \&install_subroutine;


my $pkg  = do{ package Foo; __PACKAGE__ };

sub foo{ 42 }


print "Installing a subroutine:\n";
cmpthese timethese -1 => {
	installer => sub{
		no warnings 'redefine';
		install_subroutine($pkg, foo => \&foo);
	},
	direct => sub{
		no warnings 'redefine';
		no strict 'refs';
		*{$pkg . '::foo'} = \&foo;
	},
};

print "\nInstalling 2 subroutines:\n";
cmpthese timethese -1 => {
	installer => sub{
		no warnings 'redefine';
		install_subroutine($pkg, foo => \&foo, bar => \&foo);
	},
	direct => sub{
		no warnings 'redefine';
		no strict 'refs';
		*{$pkg . '::foo'} = \&foo;
		*{$pkg . '::bar'} = \&foo;
	},
};

print "\nInstalling 4 subroutines:\n";
cmpthese timethese -1 => {
	installer => sub{
		no warnings 'redefine';
		install_subroutine($pkg,
			foo => \&foo,
			bar => \&foo,
			baz => \&foo,
			baz => \&foo,
		);
	},
	direct => sub{
		no warnings 'redefine';
		no strict 'refs';
		*{$pkg . '::foo'} = \&foo;
		*{$pkg . '::bar'} = \&foo;
		*{$pkg . '::baz'} = \&foo;
		*{$pkg . '::bax'} = \&foo;
	},
};
