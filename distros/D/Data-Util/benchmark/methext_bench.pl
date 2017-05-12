#!perl -w

use strict;
use Benchmark qw(:all);

use FindBin qw($Bin);
use lib $Bin, "$Bin/../example/lib";
use Common;

{
	package Base;
	sub e{ $_[1] }

	sub f{ $_[1] }
	sub g{ $_[1] }
	sub h{ $_[1] }
	sub i{ $_[1] }
	sub j{ $_[1] }
}


sub around{
	my $next = shift;
	goto &{$next};
}

{
	package X;
	use parent -norequire => qw(Base);
	use Method::Modifiers;

	before f => sub{ };
	around g => \&main::around;
	after  h => sub{ };

	sub i{
		my $self = shift;
		$self->SUPER::i(@_);
	}
	Data::Util::install_subroutine(
		__PACKAGE__,
		j => Data::Util::modify_subroutine(__PACKAGE__->can('j')),
	);
}

signeture
	'Data::Util' => \&Data::Util::modify_subroutine,
;

print <<'END';
Calling extended methods:
	inher  - no extended, only inherited

	before - extended with :before modifier
	around - extended with :around modifier
	after  - extended with :after modifier
	super  - extended with SUPER:: pseudo class

END

cmpthese -1 => {
	inher => sub{
		X->e(42) == 42 or die;
	},
	before => sub{
		X->f(42) == 42 or die;
	},
	around => sub{
		X->g(42) == 42 or die;
	},
	after => sub{
		X->h(42) == 42 or die;
	},
	super => sub{
		X->i(42) == 42 or die;
	},
#	simple => sub{
#		X->j(42) == 42 or die;
#	},
};
