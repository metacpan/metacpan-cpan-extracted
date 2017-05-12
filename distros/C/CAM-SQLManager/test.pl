#!/usr/bin/perl -w

use warnings;
use strict;

BEGIN
{ 
   use Test::More tests => 49;
   use_ok("CAM::SQLManager");
}

my $obj;
my $obj2;
my $mgr;
my $loops = 300;
my $start;
my $stop;
my $result;
# HACK: make a fake DBI object
my $dbh = bless({},"DBI");

package this::test;
our @ISA = qw();
sub new {bless {}, shift}
sub getdata {my $self=shift; $self->{data}}
sub setdata {my $self=shift; $self->{data}=shift}

package this::test2;
our @ISA = qw(this::test);
sub getid {my $self=shift; $self->{id}}
sub setid {my $self=shift; $self->{id}=shift}

package main;

$obj = this::test->new();
ok($obj, "Set up test object");

$obj2 = this::test2->new();
ok($obj2, "Set up test object");

my @tests = (
             { key => "id", default => "12"},
             { key => "id", mutator => "setid", accessor => "getid" },
             { key => "foo", as => "id", accessor => "getid" },
             { key => "data" },
             { key => "foo", mutator => "setdata", accessor => "getdata" },
             { key => "foo", as => "data", accessor => "getdata" },
             );

my $value = "test";
my $ntest = 0;
foreach my $test (@tests)
{
   $ntest++;
   $result = &CAM::SQLManager::_obj_set($obj, $test, $value);
   ok($result, "_obj_set $ntest");
   $result = &CAM::SQLManager::_obj_get($obj, $test);
   is($result, $value, "_obj_get $ntest");
   $result = &CAM::SQLManager::_obj_set($obj, $test, undef);
   ok($result, "_obj_set $ntest undef");
   $result = &CAM::SQLManager::_obj_get($obj, $test);
   is($result, $test->{default}, "_obj_get $ntest default");
}
$ntest = 0;
foreach my $test (@tests)
{
   $ntest++;
   $result = &CAM::SQLManager::_obj_set($obj2, $test, $value);
   ok($result, "_obj_set2 $ntest");
   $result = &CAM::SQLManager::_obj_get($obj2, $test);
   is($result, $value, "_obj_get2 $ntest");
}

$start = &getTime();
foreach my $test (@tests)
{
   for (my $i=1; $i <= $loops; $i++)
   {
      $result = &CAM::SQLManager::_obj_set($obj, $test, $value);
      die unless ($result);
      $result = &CAM::SQLManager::_obj_get($obj, $test);
      die unless ($result eq $value);
   }
}
$stop = &getTime();
ok(1, "time test: ".($stop-$start)." seconds per $loops x ".@tests);

$CAM::SQLManager::global_safe_functions = 0;
$start = &getTime();
foreach my $test (@tests)
{
   for (my $i=1; $i <= $loops; $i++)
   {
      $result = &CAM::SQLManager::_obj_set($obj2, $test, $value);
      die unless ($result);
      $result = &CAM::SQLManager::_obj_get($obj2, $test);
      die unless ($result eq $value);
   }
}
$stop = &getTime();
$CAM::SQLManager::global_safe_functions = 1;
ok(1, "time test: ".($stop-$start)." seconds per $loops x ".@tests." (safeties off)");

# Test the XML parsing

my $testfile = "tmp$$.xml";
ok(open(IN, "lib/CAM/SQLManager.pm"), "read in SQLManager.pm");
my $content = join("", <IN>);
close(IN);
my $xml = "";
if ($content =~ /\#\# START TEST XML\s+=pod\s+(.*?)=cut\s+\#\# END TEST XML/s)
{
   $xml = $1;
   ok(1, "Extract test XML");
}
else
{
   ok(0, "Extract test XML");
}
ok(open(OUT, ">$testfile"), "open output file");
print OUT $xml;
close(OUT);

CAM::SQLManager->setDBH($dbh);
CAM::SQLManager->setDirectory(".");
$mgr = CAM::SQLManager->new($testfile);
ok($mgr, "Construct SQLManager and parse test XML");
$mgr = CAM::SQLManager->getMgr($testfile);
ok($mgr, "getMgr");

is(scalar keys %{$mgr->{queries}}, 4, "count queries");

is($mgr->tableName(), "user", "tableName");
is($mgr->keyName(), "username", "keyName");

unlink($testfile);

sub getTime
{
   my($user,$system,$cuser,$csystem)=times;
   return $user+$system+$cuser+$csystem;
}
