#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(
	no_plan
	);

use_ok('CAD::Drawing');

my $drw = CAD::Drawing->new;
isa_ok($drw, 'CAD::Drawing');

{
	my $addr = $drw->addpolygon([[0,0],[1,1]]);
	ok($addr);
	is_deeply($addr, {id => 0, layer => 0, type => 'plines'});

	my $obj = $drw->getobj($addr);
	ok($obj);
	isa_ok($obj, 'HASH');
	my $color = $drw->Get('color', $addr);
	ok(defined($color), 'color def');
	ok($color == 256, 'color bylayer'); # XXX ?
}
{
	my $addr = $drw->addcircle([0,0], 1, {layer => 'hey', color => 'blue'});
	ok($addr->{layer} eq 'hey', 'layer name');
	ok($addr);
	my $obj = $drw->getobj($addr);
	ok($obj);
	isa_ok($obj, 'HASH');
	ok(exists($obj->{pt}));
	is_deeply($obj->{pt}, [0,0]);
	my $color = $drw->Get('color', $addr);
	ok(defined($color), 'color def');
	ok($color == 5, 'color blue') or warn $color; # XXX ?
	ok(defined(%CAD::Drawing::Defined::color_names), 'accessible hash');
	ok($color == $CAD::Drawing::Defined::color_names{'blue'}, 'blue');
	my @alist = $drw->addr_by_type('hey', 'circles');
	ok(@alist == 1, 'fetch');
	my $objc = $drw->getobj($alist[0]);
	is_deeply($obj, $objc, 'match');
	
}
