package PTest2;
use warnings;
use strict;

# either {
use base qw( PTest );
use Class::Framework -field=>"x",-debug=>($ENV{debug}?1:0);
# } or {
#use Class::Framework -base=>"PTest",-field=>"x",-debug=>($ENV{debug}?1:0);
# }

sub meth2($) :Method(. thearg) {
	this->mymeth(${^_thearg});
# The next line would correctly have compliation errors becase the $this_* variables are not defined.
#	print "varfields: a=>$this_a,b=>$this_b,cde=>$this_cde,x=>$this_x";
	local $\ = "\n";
	print "hatfields: a=>${^_a},b=>${^_b},cde=>${^_cde},x=>${^_x}";
	print "objfields: ".join(",",map { "$_=>".this->{$_} } qw( a b cde x ));
	print "objaccess: ".join(",",map { "$_=>".this->$_() } qw( a b cde x ));
}

1;
