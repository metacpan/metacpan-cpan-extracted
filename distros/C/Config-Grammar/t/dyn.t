#!/usr/bin/perl -w

use strict;
use lib 'lib';
use lib 't';

use Test;
use DebugDump;

BEGIN {
	plan tests => 7;
}

use Config::Grammar::Dynamic;

ok(1);

# _dyn, _dyndoc, _varlist, _sub for sections

my $sub = sub {
	my ($val, $list) = @_;
	return "Should get a second argument"
		unless ref $list eq 'ARRAY';
	for ($val) {
		/4/ and do {
			@$list and return "b wasn't first?";
			next;
		};
		/2/ and do {
			1 == @$list or return "a wasn't second?";
			$list->[0] eq 'b' or return "b wasn't before a?";
			next;
		};
		/3/ and do {
			2 == @$list or return "c wasn't third?";
			$list->[0] eq 'b' or return "c: b wasn't first?";
			$list->[1] eq 'a' or return "c: a wasn't second?";
			next;
		};
		return "unexpected value";
	}
	return undef;
};

my $parser = new Config::Grammar::Dynamic({
	_sections => [ 'test' ],
	_vars => [ qw(a) ],
	a => {
		_dyn => sub {
			my $name = shift;
			die("\$name should be 'a'") unless $name eq 'a';
			my $val = shift;
			my $grammar = shift;
			return unless $val == 2;
			push @{$grammar->{_vars}}, ('b', 'c');
			$grammar->{c}{_default} = 5;
		},
		_sub => sub {
			my $val = shift;
			my $nothing = shift;
			return "Shouldn't get a second argument" if defined $nothing;
			return undef;
		},
		_dyndoc => {
			1 => q{Values other than 2 have no effect},
			2 => q{This creates new variables 'b' and 'c'},
		},
	},
	test => {
		_sub => sub {
			my $name = shift;
			return "\$name should be 'test', but got '$name'" unless $name eq 'test';
			return undef;
		},
		_sections => [ '/s+/' ],
		'/s+/' => {
			_varlist => 1,
			_vars => [ qw(a b c) ],
			_dyn => sub {
				my ($re, $name, $grammar) = @_;
				die("\$re should be '/s+/'") unless $re eq '/s+/';
				my $realre = qr/s+/;
				die("\$name should match \$re") unless $name =~ $realre;
				pop @{$grammar->{_vars}} if length($name) > 2;
			},
			_sub => sub {
				my $name = shift;
				my $re = qr/s+/;
				die("\$name should match \$re") unless $name =~ $re;
				return undef;
			},

			_dyndoc => {
				s => q{Less than three 's' letters have no effect},
				ss => q{Less than three 's' letters still have no effect},
				sss => q{More than two 's' letters do have an effect},
			},
			a => { _sub => $sub },
			b => { _sub => $sub },
			c => { _sub => $sub },
		},
	},
});

# dyn1.cfg should fail:
# a = 3
# b = 3

# dyn2.cfg should be OK and result in c==5
# a = 2
# b = 3
# *** test ***
# +s
# b = 4
# a = 2
# c = 3

if (@ARGV and $ARGV[0] eq '--gen') {
	open(P, ">t/dyn2.pod");
	print P $parser->makepod;
	close P;

	my $cfg = $parser->parse('t/dyn2.cfg');
	defined $cfg or die("ERROR: $parser->{err}");

	open(P, ">t/dyn2.dump");
	print P DebugDump::debug_dump($cfg);
	close P;

	open(P, ">t/dyn2.templ");
	print P $parser->maketmpl;
	close P;
	exit 0;
}


{ open(F, "<t/dyn2.pod") or die("open t/dyn2.pod: $!");
local $/ = undef;
my $pod = <F>;
close F;
my $pod2 = $parser->makepod;
ok($pod2, $pod);
}

{
open(F, "<t/dyn2.templ") or die("open t/dyn2.templ: $!");
local $/ = undef;
my $tmpl = <F>;
close F;
my $tmpl2 = $parser->maketmpl;
ok($tmpl2, $tmpl);
}

my $cfg = $parser->parse('t/dyn1.cfg');
ok($cfg, undef);

$cfg = $parser->parse('t/dyn2.cfg');
defined $cfg or die("ERROR: $parser->{err}");

ok($cfg->{a}, 2);
ok($cfg->{b}, 3);
ok($cfg->{c}, 5);


