#!/usr/bin/perl
# 
# This example shows you that Config::Natural can be also used to 
# read configuration files files maintained by the system. 
# In this case we read the file /etc/hostconfig, present on Mac OS X
# and Darwin-based systems. 
# 
use strict;
use Config::Natural;

my $host = new Config::Natural { quiet => 1 };
eval {
  $host->read_source('/etc/hostconfig');
};
print <<'' and exit if $@;
Sorry but this example is for Mac OS X or Darwin systems. 

# find all active services
my @services = ();
for my $service ($host->all_parameters) {
    push @services, lc $service if $host->param($service) eq '-YES-'
}

my $hostname = $host->param('HOSTNAME');
$hostname = $hostname eq '-AUTOMATIC-' ? $host->param('APPLETALK_HOSTNAME') : $hostname;
$hostname = $hostname eq '-AUTOMATIC-' ? `hostname` : $hostname;

my $arch = `arch`; chomp $arch;

print <<"END";
Hello, happy Mac user!

Your Macintosh appears to be called $hostname
@{[ $arch ne 'ppc' and "Oops! It seems this is not a Macintosh but an $arch-based machine." ]}
The services currently active are: @{[ join ', ', sort @services ]}
END

