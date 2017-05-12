#!/usr/bin/perl

use Config::MyConfig2;
use strict;
use Data::Dumper;
use File::Basename;

my $dirname = dirname(__FILE__);

print "\n* Trying to use $dirname/myconfig-demo.cfg\n";

my $myconfig = Config::MyConfig2->new(
	conffile => "$dirname/myconfig-demo.cfg"
);

my $conftemplate;
$conftemplate->{global}->{rsync} = { type => 'single', match => '.+' };
$conftemplate->{global}->{sendmail} = { type => 'single', match => '.+' };
$conftemplate->{global}->{tar} = { type => 'single', match => '.+' };
$conftemplate->{global}->{ssh} = { type => 'single', match => '.+' };
$conftemplate->{global}->{rsync} = { type => 'single', match => '.+' };
$conftemplate->{global}->{debuglevel} = { type => 'single', match => '^\d$' };

$conftemplate->{backup}->{hostname} = { type => 'single', match => '^[a-zA-Z0-9\.]+$' };
$conftemplate->{backup}->{backupschedule} = { type => 'list', match => '^[Mon]|[Tue]|[Wed]|[Thu]|[Fri]|[Sat]|[Sun]$' };
$conftemplate->{backup}->{archiveschedule} = { type => 'list', match => '^[Mon]|[Tue]|[Wed]|[Thu]|[Fri]|[Sat]|[Sun]$' };
$conftemplate->{backup}->{archivemaxdays} = { type => 'list', match => '^\d+$' };
$conftemplate->{backup}->{add} = { type => 'list', match => '.+' };
$conftemplate->{backup}->{excl} = { type => 'list', match => '.+' };

$myconfig->SetupDirectives($conftemplate);

my $config = $myconfig->ReadConfig();

print "\n* Dump original configuration\n";

print Dumper (\$config);

print "\n* Get a global value\n";

my $global_value = $myconfig->GetGlobalValue('rsync');
print "Global value rsync: $global_value\n";

print "\n* Get some directive values\n";
my @backup_identifiers = $myconfig->GetDirectiveIdentifiers('backup');
foreach my $identifier (@backup_identifiers)
{
	my $backup_value_array_ref = $myconfig->GetDirectiveVaue('backup',$identifier,'backupschedule');
	foreach my $val (@$backup_value_array_ref)
	{
		print "Backup directive with identifier $identifier, parameter archiveschedule has value $val\n";	
	}	
}

print "\n* Change some values\n";

my $error;

print "  - Changing tar to /has/been/changed: ";
$error = $myconfig->SetGlobalValue('tar','/has/been/changed');
$error ? print "$error\n" : print "ok\n";

print "  - Changing debuglevel to /has/been/changed: ";
$error = $myconfig->SetGlobalValue('debuglevel','ultra-maximum');
$error ? print "$error\n" : print "ok\n";

print "  - Inserting new backup directive with the name new-directive: ";
$error = $myconfig->SetDirectiveValue('backup','new-directive','hostname','somenewhostname.com');
$error ? print "$error\n" : print "ok\n";

print "  - Adding new archiveschedule day for directive server-system: ";
$error = $myconfig->SetDirectiveValue('backup','server-system','archiveschedule','Thu');
$error ? print "$error\n" : print "ok\n";

my $file = 'new_demo.cfg';
print "\n* Write the modified configuration file to $file\n";
$myconfig->WriteConfig('Server Backup Configuration File',$file);
