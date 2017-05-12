#!/usr/bin/env perl -w

package Ancestor;

package Base1; @ISA = qw( Ancestor );
sub new { bless {}, $_[0] }

package Base2;
sub new { bless {}, $_[0] }

package Der; @ISA = qw( Base1 Base2 );

package main;

use Class::Multimethods;

multimethod mm => (Der) => sub
{
	# mm(superclass($_[0] => Missing));
	mm(superclass($_[0] => Base2));
	# mm(superclass($_[0]));
	print "mm(Der)\n";
};

multimethod mm => (Ancestor) => sub
{
	print "mm(Ancestor)\n";
};

multimethod mm => (Base2) => sub
{
	print "mm(Base2)\n";
};

multimethod mm => (Base1) => sub
{
	print "mm(Base1)\n";
};

mm(Base1->new());
mm(Base2->new());
mm(Der->new());
