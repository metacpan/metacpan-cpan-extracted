package PTest;
use warnings;
use strict;
require Carp;

#use Class::Framework -this=>"this",-fields=>qw( a b cde ),qw( -hatargs -hatfields -varargs -varfields -varthis -hatthis -subthis -subclass -varclass -hatclass );
use Class::Framework qw( a b cde -varargs -varfields -hatthis -varthis -this _ ),-debug=>$ENV{debug}?1:0,-fieldvarprefix=>"this_";

sub mymeth :Method(. arg1) {
#	no strict 'vars';
	local $\ = "\n";
	print "varthis: $_";
	print "hatthis: ${^__}";
	${^_a} .= "(2)";
	print "varfields: a=>$this_a,b=>$this_b,cde=>$this_cde";
	print "hatfields: a=>${^_a},b=>${^_b},cde=>${^_cde}";
	print "objfields: ".join(",",map { "$_=>".${^__}->{$_} } qw( a b cde ));
	print "objaccess: ".join(",",map { "$_=>".${^__}->$_() } qw( a b cde ));
#	print "varargs: arg1=>$arg1";
	print "hatargs: arg1=>${^_arg1}";
	Carp::carp "Carping...";
	Carp::cluck "Clucking...";
}

sub oink :ClassMethod;

sub oink {
	mymeth("oink");
	die "Oink";
};

=pod

sub mymeth :Method(. arg1) {
#	no strict 'vars';
	local $\ = "\n";
	print "subthis: ".this;
	print "varthis: $this";
	print "hatthis: ${^_this}";
	${^_a} .= "(2)";
	print "varfields: a=>$a,b=>$b,cde=>$cde";
	print "hatfields: a=>${^_a},b=>${^_b},cde=>${^_cde}";
	print "objfields: ".join(",",map { "$_=>".this->{$_} } qw( a b cde ));
	print "objaccess: ".join(",",map { "$_=>".this->$_() } qw( a b cde ));
#	print "varargs: arg1=>$arg1";
	print "hatargs: arg1=>${^_arg1}";
	die;
}

=cut

1;
