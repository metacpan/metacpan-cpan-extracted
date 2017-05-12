#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 70;
use Test::NoWarnings;

use Data::Peek;

my %special = ( 9 => "\\t", 10 => "\\n", 13 => "\\r" );
sub neat
{
    my $neat = $_[0];
    defined $neat or return "undef";
    my $ref = ref $neat ? "\\" : "" and $neat = $$neat;
    join "", $ref, map {
	my $cp = ord $_;
	$cp >= 0x20 && $cp <= 0x7e
	    ? $_
	    : $special{$cp} || sprintf "\\x{%02x}", $cp
	} split m//, $neat;
    } # neat

foreach my $test (
	[ undef,	undef, undef, undef, undef, 0, undef	],
	[ 0,		undef, 0,     undef, undef, 0, undef	],
	[ 1,		undef, 1,     undef, undef, 0, undef	],
	[ 0.5,		undef, undef, 0.5,   undef, 0, 0	],
	[ "",		"",    undef, undef, undef, 0, 0	],
	[ \0,		undef, undef, undef, 0,     0, undef	],
	[ \"a",		undef, undef, undef, "a",   0, undef	],
	) {
    (undef, my @exp) = @$test;
    my $in = neat ($test->[0]);
    ok (my @v = DDual ($test->[0]),	"DDual ($in)");
    is (scalar @v, 5,	"5 elements");
    is ($v[0], $exp[0], "PV $in ".DPeek ($v[0]));
    is ($v[1], $exp[1], "IV $in ".DPeek ($v[1]));
    is ($v[2], $exp[2], "NV $in ".DPeek ($v[2]));
    is ($v[3], $exp[3], "RV $in ".DPeek ($v[3]));
    is ($v[4], $exp[4], "MG $in ".DPeek ($v[4]));

    defined $v[1] and next;
    {   no warnings;
	my $x = 0 + $test->[0];
	}
    TODO: { local $TODO = "Do all perl versions upgrade?";
	ok (@v = DDual ($test->[0]),	"DDual ($in + 0)");
	is ($v[1], $exp[5], "IV $in ".DPeek ($v[1]));
	}
    }

TODO: {	local $TODO = "How magic is \$? accross perl versions?";
    my @m = DDual ($?);
    is ($m[4], 3,     "\$? has magic");
    is ($m[0], undef, "PV \$? w/o get");
    is ($m[1], undef, "IV \$? w/o get");
    is ($m[2], undef, "NV \$? w/o get");
    is ($m[3], undef, "RV \$? w/o get");
    }

TODO: {	local $TODO = "How magic is \$? accross perl versions?";
    my @m = DDual ($?, 1);
    is ($m[4], 3,     "\$? has magic");
    is ($m[0], undef, "PV \$? w/  get");
    is ($m[1], 0,     "IV \$? w/  get");
    is ($m[2], undef, "NV \$? w/  get");
    is ($m[3], undef, "RV \$? w/  get");
    }

1;
