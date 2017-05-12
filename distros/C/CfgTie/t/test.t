#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

$loaded=1;
BEGIN { $| = 1; print "1..27\n"; }
END {print "not ok $loaded\n" if $loaded;}
require Tie::Hash;
print "ok $loaded\n"; $loaded++;
use CfgTie::Cfgfile;
print "ok $loaded\n"; $loaded++;
use CfgTie::TieAliases;
print "ok $loaded\n"; $loaded++;
use CfgTie::filever;
print "ok $loaded\n"; $loaded++;
use CfgTie::TieRCService;
print "ok $loaded\n"; $loaded++;
use CfgTie::TieNamed;
print "ok $loaded\n"; $loaded++;
use CfgTie::CfgArgs;
print "ok $loaded\n"; $loaded++;
use CfgTie::TieGeneric;
print "ok $loaded\n"; $loaded++;
use CfgTie::TieGroup;
print "ok $loaded\n"; $loaded++;
use CfgTie::TieHost;
print "ok $loaded\n"; $loaded++;
use CfgTie::TieUser;
print "ok $loaded\n"; $loaded++;
use CfgTie::TieMTab;
print "ok $loaded\n"; $loaded++;
use CfgTie::TieNet;
print "ok $loaded\n"; $loaded++;
use CfgTie::TiePh;
print "ok $loaded\n"; $loaded++;
use CfgTie::TieProto;
print "ok $loaded\n"; $loaded++;
use CfgTie::TieRsrc;
print "ok $loaded\n"; $loaded++;
use CfgTie::TieServ;
print "ok $loaded\n"; $loaded++;
use CfgTie::TieShadow;
print "ok $loaded\n"; $loaded++;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#Wimpy testing
#Step 2: test for any PERL files that we can benefit from use or require
foreach my $I ('Getopt::Long', 'File::Find')
 {
    if (!eval "require $I")
      {
	 print STDERR "require $I; doesn't seemed to work: not installed?  This reduces functionality a bit.\n";
      }
}

#Step 3: test for any other files that we can need
my $FileNMsgs={
	'/usr/bin/perl'=> 'Your perl is slightly different, you may have to modify the utilities included to change this',
	'/usr/sbin/groupmod' => '/usr/sbin/groupmod is not present.  You will not be able to employ CfgTie::TieGroup to change group information.  (Future versions will be more flexible)',
	'/usr/sbin/groupdel' => '/usr/sbin/groupdel is not present.  You will not be able to employ CfgTie::TieGroup to change group information.  (Future versions will be more flexible)',
	'/usr/sbin/shadowmod' => '/usr/sbin/shadowmod is not present.  You will not be able to employ CfgTie::TieShadow to change password information.  (Future versions will be more flexible)',
	'/usr/sbin/shadowdel' => '/usr/sbin/shadowdel is not present.  You will not be able to employ CfgTie::TieShadow to change password information.  (Future versions will be more flexible)',
	'/usr/sbin/userdel' => '/usr/sbin/userdel is not present.  You will not be able to employ CfgTie::TieUser to change user information.  (Future versions will be more flexible)',
	'/usr/sbin/usermod' => '/usr/sbin/usermod is not present.  You will not be able to employ CfgTie::TieUser to change user information.  (Future versions will be more flexible)',
	};
foreach my $I (keys %FileNMsgs)
 {
    if (!-e $I)
      {
	 print STDERR $FileNMsgs{$I},"\n";
      }
}

my %Aliases;
tie %Aliases, 'CfgTie::TieAliases';
print "ok $loaded\n"; $loaded++;
tie %Aliases, 'CfgTie::TieAliases', 'test/aliases';
my $N=scalar keys %Aliases;
if ($N < 1)
{
   print "not ok $loaded\n";
}
else
{
   print "ok $loaded\n";
}
$loaded++;
my %Generic; tie %Generic, 'CfgTie::TieGeneric';
print "ok $loaded\n"; $loaded++;
my %Groups; tie %Groups, 'CfgTie::TieGroup';
print "ok $loaded\n"; $loaded++;
my %Groups2; tie %Groups2, 'CfgTie::TieGroup', 't/group';
print "ok $loaded\n"; $loaded++;
$N=scalar keys %Groups2;
if ($N < 1)
{
   print "not ok $loaded\n";
}
else
{
   print "ok $loaded\n";
}
$loaded++;
#We use our own named.boot file since not all machines have one (ie, people who
#have not installed named!)
my %DNS; tie %DNS, 'CfgTie::TieNamed','t/named.boot';
print "ok $loaded\n"; $loaded++;
$N=scalar keys %DNS;
if ($N < 1)
{
   print "not ok $loaded\n";
}
else
{
   print "ok $loaded\n";
}
$loaded++;
my %Users; tie %Users, 'CfgTie::TieUser';
print "ok $loaded\n"; $loaded++;

$loaded=0;
