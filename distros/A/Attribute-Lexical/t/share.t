use warnings;
use strict;

use Test::More tests => 18;

sub foo { }

my(@lex_attributes, @pkg_attributes);
sub atthandler { push @lex_attributes, [@_[0..2,4..$#_]] }
BEGIN {
	package P0::UNIVERSAL;
	sub MODIFY_CODE_ATTRIBUTES {
		my $invocant = shift;
		my $target = shift;
		my @unhandled;
		foreach(@_) {
			if(/\AP0/) {
				push @pkg_attributes, [ $target, $_ ];
			} else {
				push @unhandled, $_;
			}
		}
		return @unhandled;
	}
	push @UNIVERSAL::ISA, __PACKAGE__;
}

@lex_attributes = @pkg_attributes = ();
eval q{
	sub foo :L0;
};
isnt $@, "";
is_deeply \@lex_attributes, [];
is_deeply \@pkg_attributes, [];

@lex_attributes = @pkg_attributes = ();
eval q{
	use Attribute::Lexical "CODE:L0" => \&atthandler;
	sub foo :L0;
};
is $@, "";
is_deeply \@lex_attributes, [ [\&foo,"L0",undef] ];
is_deeply \@pkg_attributes, [];

@lex_attributes = @pkg_attributes = ();
eval q{
	sub foo :P0;
};
is $@, "";
is_deeply \@lex_attributes, [];
is_deeply \@pkg_attributes, [ [\&foo,"P0"] ];

@lex_attributes = @pkg_attributes = ();
eval q{
	use Attribute::Lexical "CODE:L0" => \&atthandler;
	sub foo :P0;
};
is $@, "";
is_deeply \@lex_attributes, [];
is_deeply \@pkg_attributes, [ [\&foo,"P0"] ];

@lex_attributes = @pkg_attributes = ();
eval q{
	use Attribute::Lexical "CODE:L0" => \&atthandler;
	sub foo :P0(a) :L0(b) :P0(c) :L0(d);
};
is $@, "";
is_deeply \@lex_attributes, [ [\&foo,"L0","b"], [\&foo,"L0","d"] ];
is_deeply \@pkg_attributes, [ [\&foo,"P0(a)"], [\&foo,"P0(c)"] ];

@UNIVERSAL::ISA = grep { $_ ne "P0::UNIVERSAL" } @UNIVERSAL::ISA;
my $have_atthandlers = eval("use Attribute::Handlers; 1");
SKIP: {
	skip "Attribute::Handlers not available", 3 unless $have_atthandlers;
	my @hdl_attributes;
	@lex_attributes = @hdl_attributes = ();
	eval q{
		sub H0 :ATTR(CODE,BEGIN) { push @hdl_attributes, [ @_[2..3] ] }
		use Attribute::Lexical "CODE:L0" => \&atthandler;
		sub foo :H0(a) :L0(b) :H0(c) :L0(d);
	};
	is $@, "";
	is_deeply \@lex_attributes, [ [\&foo,"L0","b"], [\&foo,"L0","d"] ];
	is_deeply \@hdl_attributes, [ [\&foo,"H0"], [\&foo,"H0"] ];
}

1;
