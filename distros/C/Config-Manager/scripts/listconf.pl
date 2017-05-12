#!perl -w

$running_under_some_shell = $running_under_some_shell = 0; # silence warning

###############################################################################
##                                                                           ##
##    Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.                  ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

###############################################################################
## Header (controls the automatic initialization in Config::Manager::Base!): ##
###############################################################################

package Config::Manager::listconf;

##############
## Imports: ##
##############

use strict;
use vars qw( @ARGV );

use Config::Manager::Base qw( ReportErrorAndExit );
##########################################################
## This automatically initializes Config::Manager::Conf ##
## and Config::Manager::Report! Note that the order of  ##
## your "use" statements is essential here:             ##
## Config::Manager::Base must always be "use"d first,   ##
## before all other Config::Manager::* modules!         ##
##########################################################

use Config::Manager::Conf;
use Config::Manager::User qw(:all);

my($self,$user,$conf,$list,$line);

$self = $0;
$self =~ s!^.*[/\\]!!;
$self =~ s!\.+(?:pl|bat|sh)$!!i;

if (@ARGV > 1)
{
    &Usage();
    &ReportErrorAndExit("Wrong number of parameters!");
}

if (@ARGV)
{
    if ($ARGV[0] =~ /^--?(?:h|\?|help|hilfe)/i)
    {
        &Usage();
        exit 0; # 0 = OK
    }
    $user = shift;
}
else
{
    &ReportErrorAndExit()
        unless (defined ($user = &user_id()));
}

&ReportErrorAndExit()
    unless (defined ($conf = &user_conf($user)));

unless (defined ($list = $conf->get_all()))
{
    $line = Config::Manager::Conf->error();
    $line =~ s!\s+$!!;
    &ReportErrorAndExit(
        "Error while trying to read configuration data:",
        $line );
}

unless ((-t STDOUT) && (open(MORE, "| more")))
{
    unless (open(MORE, ">-"))
    {
        &ReportErrorAndExit("Can't open STDOUT: $!");
    }
}

foreach $line (@{$list})
{
    $line =~ s!\s+$!!;
    print MORE "$line\n";
}

close(MORE);

exit 0; # 0 = OK

sub Usage
{
    print <<"VERBATIM";

Usage:

  $self -h
  $self [<login>]

  Lists all configuration constants of the specified
  or the current user (i.e., the caller of this tool).

VERBATIM
}

__END__

