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

##############
## Imports: ##
##############

use strict;
use vars qw( @ARGV );

use Config::Manager::Conf qw(whoami);

my $DEFAULT = 'Manager';

my($self,$owner,$which,$scope,$user,$error,$conf,$list,$line);

$self = $0;
$self =~ s!^.*[/\\]!!;
$self =~ s!\.+(?:pl|bat|sh)$!!i;

foreach (@ARGV)
{
    if (/^--?(?:h|\?|help|hilfe)/i)
    {
        &Usage();
        exit 0; # 0 = OK
    }
}

if (@ARGV > 2)
{
    &Usage();
    die "$self: wrong number of parameters!\n";
}

unless (($owner,$which) = &whoami())
{
    die "$self: can't find your login in the environment!\n";
}

$scope = shift || $DEFAULT;
$user  = shift || $owner;

$error = '';
$ENV{$which} = $user if ($owner ne $user);
eval
{
    if (defined ($conf = Config::Manager::Conf->new()))
    {
        if (defined $conf->init( $scope ))
        {
            unless (defined ($list = $conf->get_files()))
            {
                $error = "can't get all config files: " . $conf->error();
            }
        }
        else
        {
            $error = "can't initialize new config object: " . $conf->error();
        }
    }
    else { $error = "can't create new config object"; }
};
$ENV{$which} = $owner if ($owner ne $user);

if (($@ ne '') or ($error ne ''))
{
    $@     =~ s!\s+$!!;
    $error =~ s!\s+$!!;
    if (($@ ne '') and ($error ne '')) { $error = $@ . ': ' . $error; }
    else                               { $error = $@        . $error; }
    die "$self: $error\n";
}

#unless ((-t STDOUT) && (open(MORE, "| more")))
#{
#    unless (open(MORE, ">-"))
#    {
#        die "$self: can't open STDOUT: $!\n";
#    }
#}

foreach $line (@{$list})
{
    print "$line\n";
}

#close(MORE);

exit 0; # 0 = OK

sub Usage
{
    print <<"VERBATIM";

Usage:

  $self -h
  $self <scope>
  $self <scope> <login>
  $self    ''   <login>

  Lists all configuration files of the current
  (or specified) user in the default (or specified)
  scope (i.e., the named chain of configuration files)
  in the order they were read in.

VERBATIM
}

__END__

