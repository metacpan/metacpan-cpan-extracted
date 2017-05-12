#!/usr/bin/perl

eval {
	eval { require Apache; }
	if($@){
		die "You have to have mod_perl and Apache installed in order to be able to use this module.\n";
		die $@;
	}
}
print "OK\n";
exit 0;