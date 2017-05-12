#!/usr/local/bin/perl -T

# for some reason on my Solaris 5.00551 perl, doing
# use Apache::ASP as opposed to use lib qw(.); use ASP
# would make a difference between having an error and
# not having one during "make test", really odd
#
# use Apache::ASP;
#

use lib qw(blib/lib lib);
use Apache::ASP::CGI;

use strict;
#$SIG{__DIE__} = \&Carp::confess;

#    print STDERR $^]." $^V $PERL_VERSION --- \n";
&Apache::ASP::CGI::do_self();

__END__

<% 
  $Response->Include('session.inc'); 
%>
