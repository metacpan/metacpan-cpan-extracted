#!perl -w

use strict;

use Config::Manager;
use Config::Manager::Conf;
use Config::Manager::Report;
use Config::Manager::User;

#######################################################################
#                                                                     #
#  We cannot use Config::Manager::Base here because of its automatic  #
#  initialization, which requires the configuration files to be       #
#  in place, and we cannot assume that they have been installed       #
#  already at this time! Likewise for Config::Manager::File and       #
#  Config::Manager::SendMail, which use Config::Manager::Base.        #
#                                                                     #
#######################################################################

# ======================================================================
#   $ver = $Config::Manager::VERSION;
#   $ver = $Config::Manager::Conf::VERSION;
#   $ver = $Config::Manager::Report::VERSION;
#   $ver = $Config::Manager::User::VERSION;
# ======================================================================

print "1..4\n";

my $n = 1;
if ($Config::Manager::VERSION eq "1.7")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($Config::Manager::Conf::VERSION eq "1.7")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($Config::Manager::Report::VERSION eq "1.7")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($Config::Manager::User::VERSION eq "1.7")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

