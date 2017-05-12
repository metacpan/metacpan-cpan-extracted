#!./perl

#
# test out building qualifiers 
#

# TEST    DESC
# 1       explicit ars_Login / ars_Logoff
# 2       build qual, explicitly destroy it
# 3       build, implicitly destroy (out of scope)
# 4       build, implicitly destroy (exit)

use ARS;
require './t/config.cache';

print "1..4\n";

# test 1 -> login/logout

my($ctrl) = ars_Login(&CCACHE::SERVER, 
		      &CCACHE::USERNAME, 
 		      &CCACHE::PASSWORD, "","", &CCACHE::TCPPORT);

if(!defined($ctrl)) {
  print "not ok [1]\n";
} else {
  print "ok [1]\n";
}

my $q1 = ars_LoadQualifier($ctrl, "ARSperl Test", 
				qq{'Status' = "New"}
			   );
if (defined($q1)) {
	print "ok [2]\n";
} else {
	print "not ok [2] ($ars_errstr)\n";
}

print "expect DESTROY..\n";
undef $q1; # should result in a call to DESTROY
print "did you get it? (ARSPDEBUG must be defined)\n";

{
	my $q2 = ars_LoadQualifier($ctrl, "ARSperl Test", "'Submitter' = \"jcmurphy\"");
	if (defined($q2)) {
		print "ok [3]\n";
	} else {
		print "not ok [3] ($ars_errstr)\n";
	}
}
# implicit call to DESTROY for q2

my $q3 = ars_LoadQualifier($ctrl, "ARSperl Test", "'Create Date' > \"1/1/2000 01:02:03\"");
if (defined($q3)) {
	print "ok [4]\n";
} else {
	print "not ok [4] ($ars_errstr)\n";
}




exit 0; #implicit call to DESTROY for q3

