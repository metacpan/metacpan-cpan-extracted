#!./perl

#
# test out connecting to an arserver
#

# TEST    DESC
# 1       explicit ars_Login / ars_Logoff
# 2       explicit login, implicit Logoff via GC
# 3       OO login / logoff

use ARS;
require './t/config.cache';

print "1..3\n";

# make non-oo connect

# test 1 -> login/logout

my($ctrl) = ars_Login(&CCACHE::SERVER, 
		      &CCACHE::USERNAME, 
 		      &CCACHE::PASSWORD, "", "", &CCACHE::TCPPORT);

if(!defined($ctrl)) {
  print "not ok [1 $ars_errstr]\n";
} else {
  print "ok [1]\n";
  ars_Logoff($ctrl);
}

{
  my ($c2) = ars_Login (&CCACHE::SERVER, 
			&CCACHE::USERNAME, 
			&CCACHE::PASSWORD, "", "", &CCACHE::TCPPORT);

  if (!defined($c2)) {
    print "not ok [2 $ars_errstr]\n";
  } else {
    print "ok [2]\n";
  }
}

# if built with debugging, we should see $c2 be
# DESTROYed at this point


# make an OO connection. note that we disable exception
# catching so we can detect the errors manually.

# test 3 -> constructor

my $c = new ARS(-server => &CCACHE::SERVER, 
                -username => &CCACHE::USERNAME,
		-password => &CCACHE::PASSWORD,
		-tcpport  => &CCACHE::TCPPORT,
		-catch => { ARS::AR_RETURN_ERROR => undef,
			    ARS::AR_RETURN_WARNING => undef,
			    ARS::AR_RETURN_FATAL => undef
			  },
	       -debug => undef);

if($c->hasErrors() || $c->hasFatals() || $c->hasWarnings()) {
  print "not ok [3 $ars_errstr]\n";
#  print "messages: ", $c->messages(), "\n";
} else {
  print "ok [3]\n";
}

# exitting will cause $c to destruct, calling ars_Logoff() in the
# process.

exit 0;

