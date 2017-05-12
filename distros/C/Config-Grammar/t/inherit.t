#!/usr/bin/perl -w

use strict;
use lib 'lib';
use lib 't';

use Test;
use DebugDump;

BEGIN {
	plan tests => 28;
}

use Config::Grammar::Dynamic;

ok(1);

# _default, _inherited, _recursive

my $parser = new Config::Grammar::Dynamic({
	_sections => [ 'top' ],
	_vars => [ (qw(a b c d)) ],
	_recursive => [ 'top' ],
	a => { _doc => "The 'A' variable", _default => 5, },
	b => { _doc => "The 'B' variable", _default => 6, },
	c => { _doc => "The 'C' variable", },
	d => { _doc => "The 'D' variable", _default => 11 },
	top => {
		_sections => [ 'bottom' ],
		_vars => [ (qw(a b c d)) ],
		_inherited => [ (qw(a b)) ],
		a => { _doc => "The 'A' variable", _default => 7, },
		b => { _doc => "The 'B' variable", _default => 8, },
		c => { _doc => "The 'C' variable", _default => 9, },
		d => { _doc => "The 'D' variable", },
		bottom => {
			_vars => [ (qw(a b c d)) ],
			_inherited => [ (qw(b d)) ],
			a => { _doc => "The 'A' variable"},
			b => { _doc => "The 'B' variable", _default => 8, },
			c => { _doc => "The 'C' variable", _default => 9, },
			d => { _doc => "The 'D' variable", },
		},
	},
});

# inherit.cfg:
# b = 4
# d = 1
# *** top ***
# c = 2
# +bottom
# d = 3
# +top
# a = 5
# ++top
# b = 6
# +++bottom
# c = 7

if (@ARGV and $ARGV[0] eq '--gen') {
	open(P, ">t/inherit.pod");
	print P $parser->makepod;
	close P;

	my $cfg = $parser->parse('t/inherit.cfg');
	defined $cfg or die("ERROR: $parser->{err}");

	open(P, ">t/inherit.dump");
	print P DebugDump::debug_dump($cfg);
	close P;

	open(P, ">t/inherit.templ");
	print P $parser->maketmpl;
	close P;
	exit 0;
}


{ open(F, "<t/inherit.pod") or die("open inherit.pod: $!");
local $/ = undef;
my $pod = <F>;
close F;
my $pod2 = $parser->makepod;
ok($pod, $pod2);
}

{
open(F, "<t/inherit.templ") or die("open inherit.templ: $!");
local $/ = undef;
my $tmpl = <F>;
close F;
my $tmpl2 = $parser->maketmpl;
ok($tmpl, $tmpl2);
}

my $cfg = $parser->parse('t/inherit.cfg');
defined $cfg or die("ERROR: $parser->{err}");

ok($cfg->{a}, 5);
ok($cfg->{top}{a}, 7);
ok($cfg->{top}{bottom}{a}, undef);

ok($cfg->{b}, 4);
ok($cfg->{top}{b}, 4);
ok($cfg->{top}{bottom}{b}, 4);

ok($cfg->{c}, undef);
ok($cfg->{top}{c}, 2);
ok($cfg->{top}{bottom}{c}, 9);

ok($cfg->{d}, 1);
ok($cfg->{top}{d}, undef);
ok($cfg->{top}{bottom}{d}, 3);

ok($cfg->{top}{top}{a}, 5);
ok($cfg->{top}{top}{b}, 4);
ok($cfg->{top}{top}{c}, 9);
ok($cfg->{top}{top}{d}, undef);

ok($cfg->{top}{top}{top}{a}, 5);
ok($cfg->{top}{top}{top}{b}, 6);
ok($cfg->{top}{top}{top}{c}, 9);
ok($cfg->{top}{top}{top}{d}, undef);

ok($cfg->{top}{top}{top}{bottom}{a}, undef);
ok($cfg->{top}{top}{top}{bottom}{b}, 6);
ok($cfg->{top}{top}{top}{bottom}{c}, 7);
ok($cfg->{top}{top}{top}{bottom}{d}, undef);

{
open(F, "<t/inherit.dump") or die("open inherit.dump: $!");
local $/ = undef;
my $dump = <F>;
close F;
ok($dump, DebugDump::debug_dump($cfg));
}

# $cfg2 = $parser->parse('t/inherit1.cfg');
