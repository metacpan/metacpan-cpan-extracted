#!/usr/local/bin/perl
# Test script for DBD::SearchServer
# $Revision: 2.7 $

use Carp;
use Cwd;
use DBI;
use strict;



BEGIN {

   if (length($ENV{'FULCRUM_HOME'}) <= 0) {
      $ENV{'FULCRUM_HOME'} = "/home/fulcrum";
      warn "FULCRUM_HOME set to /home/fulcrum!";
   }
   $ENV{'FULSEARCH'} = "./fultest";
   $ENV{'FULTEMP'} = "./fultest";
}

if (! -r "$ENV{FULSEARCH}/test.cat") {
   print "It seems you have not prepared the test table in $ENV{FULSEARCH}\n";
   print "Read the docs and come back later.\n";
   exit 1;
}

unlink ('./dbi.log'); # don't let it grow huge...
DBI->trace(9, './dbi.log');

###############
# Connect to SearchServer (or explode)
##############

print "*** Real-world test of driver...\n";


my $ss_dbh = undef;

print "Connecting to SearchServer... ";
# Note here: Under NT, you have to specify the data source (first parameter)
# while under Unix, only the FULSEARCH var has a role.
# So, iff on NT, set DBI_DSN to the data source name (ONLY the data source name, this is directly passed to SS)
# and else, do not set it.
if (!($ss_dbh = DBI->connect ("dbi:SearchServer:$ENV{DBI_DSN}",'',''))) {
    print "Cannot connect to SearchServer ($DBI::errstr)\n";
    exit 1;
}

print "ok.\n";

print "DBD::SearchServer driver version: $DBD::SearchServer::VERSION\n";

print "Setting SHOW_MATCHES to TRUE... ";
if (!($ss_dbh->do( "set show_matches 'TRUE'"))) {
#   if (!($ss_dbh->do( "set show_matches 'EXTERNAL_COLUMN'"))) {
    print "FAILED: Cannot customize SearchServer show_matches ($DBI::errstr)\n";
    exit 1;
}

print "ok\n";

print "Setting character set to ISO_LATIN1... ";
if (!($ss_dbh->do( "set character_set 'ISO_LATIN1'"))) {
    print "FAILED: Cannot customize SearchServer character_set ($DBI::errstr)\n";
    exit 1;
}

print "ok\n";

print "Removing existing rows... ";
if (!($ss_dbh->do( "delete from test" ))) {
   print "FAILED: Cannot delete ($DBI::errstr)\n";
   exit 1;
}

print "ok\n";

print "Inserting a document into test table... ";

my @statdata = stat ('test.fte');
my $pwd = Cwd::getcwd; # be portable Davide, be portable!
chomp($pwd);
$pwd =~ s/\'/\'\'/g; # if a quote is present in a string, we have to double it in order to escape.

my $cur = undef;
if (!($cur =
      $ss_dbh->prepare("insert into test(title,filesize,ft_sfname) values ('Pippo pippo non lo sa ma quando passa ride tutta la citta pippo pippo non lo sa pippo pippo non lo sa Pippo pippo non lo sa ma quando passa ride tutta la citta pippo pippo non lo sa pippo pippo non lo sa Pippo pippo non lo sa ma quando passa ride tutta la', $statdata[7], '" . $pwd . "/test.fte')"	))) {
   print "FAILED: Cannot prepare insert test.fte ($DBI::errstr)\n";
   exit 1;
}

if (!$cur->execute) {
   print "FAILED: Cannot execute insert test.fte ($DBI::errstr)\n";
   exit 1;
}

print "ok\n";

print "Row id (\$cur->{ss_last_row_id}) for the just inserted row: $cur->{ss_last_row_id} ...";
print "ok\n" if ($cur->{ss_last_row_id} > 0);

$cur->finish;

print "Rebuilding index... ";
if (!($ss_dbh->do( "VALIDATE INDEX test VALIDATE TABLE"))) {
   print "FAILED: Cannot rebuild index ($DBI::errstr)\n";
}

print "ok\n";

$ss_dbh->{PrintError} = 0;
print "Doing a query (expecting 'Data truncated' error)... ";
my $cursor = $ss_dbh->prepare ('select ft_text,ft_sfname,filesize,title from test where title contains \'pippo\'');
if ($cursor) {
   print "(execute) ... ";
   $cursor->execute;
   print "ok, now fetching (fetchrow): ";
   my $text;
   my @row;
   my $eot;
   my $data_truncated = 0;
   while (@row  = $cursor->fetchrow) {
      $data_truncated++ if ($cursor->state =~ /01004/);
   }
   print "checking data truncated condition... ";
   if ($data_truncated == 0) {
      print "FAILED: did not detect 01004 [Data truncated] condition!\n";
      exit 1;
   }
   print "ok\n";
}
else {
   print "FAILED: Prepare failed ($DBI::errstr)\n";
   exit 1;
}

print "Doing another query (this time you'll see the data)... ";
$ss_dbh->{ss_maxhitsinternalcolumns} = 64;
print "\n\t\$dbh->{ss_maxhitsinternalcolumns} set to " . $ss_dbh->{ss_maxhitsinternalcolumns}  . "\n";
# this allows for max 64 matches, or it will be
# truncated still.
$cursor = $ss_dbh->prepare ('select ft_text,ft_sfname,filesize,title from test where title contains \'pippo\'');
if ($cursor) {
   print "\t(execute) ... ";
   $cursor->execute;
   print "\tok, now fetching (fetchrow):\n***\n";
   my $text;
   my @row;
   my $eot;
   my $data_truncated = 0;
   while (@row  = $cursor->fetchrow) {
      $data_truncated++ if ($DBI::state =~ /truncated/);
      $cursor->blob_read (1, 0, 8192, \$text);
      #or (print "+++ RB NOT OK:$DBI::errstr\n");
      $text = $` if ($text =~ /\x00/);
#[32703mpippo.[32723m
      $row[3] =~ s!\e\[32703m!\<M\>!g;
      $row[3] =~ s!\e\[32723m!\</M\>!g;
      print "(FILE: $row[1] TITLE: '$row[3]') "; #$text removed to clean up output
   }
   if ($data_truncated > 0) {
      print "FAILED: Data truncated when it shouldn't be!\n";
      exit 1;
   }
   print "\n***\n... ok\n";
}
else {
   print "FAILED: Prepare failed ($DBI::errstr)\n";
   exit 1;
}

$cursor->finish;
$ss_dbh->disconnect;

print "Exiting\nIf you are here, then most likely all tests were successful.\n";
exit 0;
# end.
