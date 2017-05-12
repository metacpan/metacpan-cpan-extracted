#!/usr/bin/perl -w

use strict;
use lib '../../lib';
use Code::Class::C;

my $gen = Code::Class::C->new();

$gen->class('Shape',
	subs => {
		'getLargest(s:Shape):Shape' => 'c/Shape.getLargest.c',
		'calcArea():float' => q{
			return 0.0;
		},
	},
);

$gen->class('Circle',
	isa => ['Shape'],
	attr => {
		'radius' => 'float',
	},
	subs => {
		'calcArea():float' => q{
			return 3.1415 * getRadius(self) * getRadius(self);
		},
	},
);

$gen->class('Square',
	isa => ['Shape'],
	attr => {
		'width' => 'float',
	},
	subs => {
		'calcArea():float' => q{
			return getWidth(self) * getWidth(self);
		},
	},
);

$gen->class('Rectangle',
	isa => ['Square'],
	attr => {
		'height' => 'float',
	},
	subs => {
		'calcArea():float' => q{
			return getWidth(self) * getHeight(self);
		},
		'calcOutline():float' => q{
			return getWidth(self) * 2 + getHeight(self) * 2;
		},	
	},
);

$gen->readFile('c/Triangle.c');

$gen->generate(
	file    => './main.c',
	headers => ['stdio','opengl'],
	main    => 'c/main.c',
	bottom  => q{
		void whatTheHell (int i) {
			/* do sth. ... */
		}
	}, 
);

# compile file with gcc
system('make');
