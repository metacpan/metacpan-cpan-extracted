package #hide
	AnyEvent::Connection::Util;

use common::sense 2;m{
use strict;
use warnings;
};
use Carp;

sub import {
	my $me = shift;
	my $pk = caller;
	for (@_ ? @_ : qw(dumper)) {
		defined &$_ or croak "$_ is not exported by $me";
		*{$pk.'::'.$_} = \&$_;
	}
	return;
}

sub dumper (@) {
	eval { require Data::Dumper;1 } or return @_;
	no strict 'refs';
	*{ caller().'::dumper' } = sub (@) {
		my $s = Data::Dumper->new([@_])
			#->Maxdepth(3)
			->Terse(1)
			->Indent(1)
			->Purity(0)
			->Useqq(1)
			->Quotekeys(0)
			->Dump;
		$s =~ s{\\x\{([a-f0-9]{1,4})\}}{chr hex $1}sge;
		$s;
	};
	goto &{ caller().'::dumper' };
}

1;
