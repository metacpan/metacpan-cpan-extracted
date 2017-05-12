#!/usr/bin/perl -w

use Getopt::Long;
use XML::DOM;
use App::BackupPlan;
use strict;

#-------Variables----------------
my $configFile;
my $hasHelp;
my $tar;
my $logFile;
my %policies; 



#-------Subs---------------------
sub printHelp {
  print "This Perl performs a  regular, recursive backup of a directory structure\n";
  print "and cleans up the target directory of old backup files:\n";
  print "Syntax: backup.pl [-c <configFile> [-t <tar method>] | -h]\n";
  print "  -c <configFile>\tThe configuration file\n";
  print "  -l <log4per>\tThe log4Perl config file\n";
  print "  -t <tar method>\tTar method: system for system tar, or perl for Archive::Tar\t\n";
  print "  -h\t\t\tPrints this help.\n";
  exit;
}




#--------Main---------------------
GetOptions('c=s'     => \$configFile,
		   'l=s'     => \$logFile,
		   't=s'	 => \$tar,
  	   	   'h'       => \$hasHelp);
  	   	   
#--print help is specifically requested  	   	   
&printHelp if $hasHelp;
#--or print help if nothing else to do
#&printHelp unless defined($configFile);  	

$App::BackupPlan::TAR = $tar if defined $tar;

#----main functionality is here
my $plan = new App::BackupPlan($configFile, $logFile);
$plan->run;
   	   	



