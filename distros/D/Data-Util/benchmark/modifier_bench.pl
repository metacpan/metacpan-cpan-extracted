#!perl -w
use strict;
use Benchmark qw(:all);

use FindBin qw($Bin);
use lib $Bin, "$Bin/../example/lib";
use Common;

{
	package Base;
	sub f{ 42 }
	sub g{ 42 }
	sub h{ 42 }
}

my $i = 0;
sub around{
	my $next = shift;
	$i++;
	goto &{$next};
}
{
	package DUMM;
	use parent -norequire => qw(Base);
	use Method::Modifiers;

	before f => sub{ $i++ };
	around g => \&main::around;
	after  h => sub{ $i++ };
}
{
	package CMM;
	use parent -norequire => qw(Base);
	use Class::Method::Modifiers;

	before f => sub{ $i++ };
	around g => \&main::around;
	after  h => sub{ $i++ };
}
{
	package MOP;
	use parent -norequire => qw(Base);
	use Moose;

	before f => sub{ $i++ };
	around g => \&main::around;
	after  h => sub{ $i++ };
}

signeture
	'Data::Util' => \&Data::Util::modify_subroutine,
	'Moose' => \&Moose::around,
	'Class::Method::Modifiers' => \&Class::Method::Modifiers::around,
;

print "Calling methods with before modifiers:\n";
cmpthese -1 => {
	du => sub{
		my $old = $i;
		DUMM->f();
		$i == ($old+1) or die $i;
	},
	cmm => sub{
		my $old = $i;
		CMM->f();
		$i == ($old+1) or die $i;
	},
	moose => sub{
		my $old = $i;
		MOP->f();
		$i == ($old+1) or die $i;
	}
};

print "\n", "Calling methods with around modifiers:\n";
cmpthese -1 => {
	du => sub{
		my $old = $i;
		DUMM->g();
		$i == ($old+1) or die $i;
	},
	cmm => sub{
		my $old = $i;
		CMM->g();
		$i == ($old+1) or die $i;
	},
	moose => sub{
		my $old = $i;
		MOP->g();
		$i == ($old+1) or die $i;
	}
};
print "\n", "Calling methods with after modifiers:\n";
cmpthese -1 => {
	du => sub{
		my $old = $i;
		DUMM->h();
		$i == ($old+1) or die $i;
	},
	cmm => sub{
		my $old = $i;
		CMM->h();
		$i == ($old+1) or die $i;
	},
	moose => sub{
		my $old = $i;
		MOP->h();
		$i == ($old+1) or die $i;
	}
};
