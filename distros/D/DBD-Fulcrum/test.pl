#!/usr/local/bin/perl -w
# Test script for DBD::Fulcrum
# $Revision: 2.2 $

use Carp;
use Cwd;


BEGIN {

   if (length($ENV{'FULCRUM_HOME'}) <= 0) {
      $ENV{'FULCRUM_HOME'} = "/home/fulcrum";
      warn "FULCRUM_HOME set to /home/fulcrum!";
   }
   $ENV{'FULSEARCH'} = "./fultest" if (!defined($ENV{FULSEARCH}));
   $ENV{'FULTEMP'} = "./fultest" if (!defined($ENV{FULTEMP}));
}


# Base DBD Driver Test

print "Testing 'require DBI'...";

require DBI;
print "ok\n";

print "Testing 'import DBI'...";
import DBI;
print "ok\n";

#$DBI::dbi_debug=9;

###############
# Connect to fulcrum (or explode)
##############



my $ful_drh; 

print "Installing driver...";
if (!($ful_drh = DBI->install_driver ('Fulcrum'))) {
    print "FAILED: Cannot install Fulcrum driver ($DBI::errstr)\n";
    exit 1;
}

print "ok.\nDBD::Fulcrum driver version: $ful_drh->{Version}\n";

print "In order to execute the following tests, you MUST have created a table for us to test on.\n";
print "If you haven't already, answer N here and then follow the instructions: ";
$char = getc(STDIN);
if (lc($char) eq 'n') {
   print "\tLaunch the build-dir.sh script to build the test directory:\n";
   print "\t\t./build-dir.sh \$FULCRUM_HOME test-directory\n";
   print "\tfor instance: ./build-dir.sh \$FULCRUM_HOME fultest\n";
   print "\tDo NOT use a production directory since it will be initialized!\n";
   print "\tOutput of the build-dir.sh script will go to build-dir.log\n";
   print "\t++ Sorry, this will NOT work under NT. Just copy the relevant files yourself,\n";
   print "\tby lurking in the abovementioned shell script.\n";
   print "Testing aborted.\n";
   exit 0;
}


$::ful_dbh = undef; # global to avoid parameter passing...

print "Connecting to fulcrum (this is a no op)... ";
# Note here: Under NT, you have to specify the data source (first parameter)
# while under Unix, only the FULSEARCH var has a role.
# So, iff on NT, set DBI_DSN to the data source name (ONLY the data source name, this is directly passed to SS)
# and else, do not set it.
if (!($::ful_dbh = $ful_drh->connect ($ENV{DBI_DSN},'',''))) {
    print "Cannot connect to Fulcrum ($DBI::errstr)\n";
    exit 1;
}

print "ok.\n";

print "Setting SHOW_MATCHES to EXTERNAL_COLUMN... ";
if (!($::ful_dbh->do( "set show_matches 'INTERNAL_COLUMNS'"))) {
#   if (!($::ful_dbh->do( "set show_matches 'EXTERNAL_COLUMN'"))) {
    print "FAILED: Cannot customize Fulcrum show_matches ($DBI::errstr)\n";
    exit 1;
}

print "ok\n";

print "Setting character set to ISO_LATIN1... ";
if (!($::ful_dbh->do( "set character_set 'ISO_LATIN1'"))) {
    print "FAILED: Cannot customize Fulcrum character_set ($DBI::errstr)\n";
    exit 1;
}

print "ok\n";

print "Removing existing rows... ";
if (!($::ful_dbh->do( "delete from test" ))) {
   print "FAILED: Cannot delete ($DBI::errstr)\n";
   exit 1;
}

print "ok\n";

print "Inserting a document into test table... ";

@statdata = stat ('test.fte');
my $pwd = Cwd::getcwd; # be portable Davide, be portable!
chomp($pwd);
$pwd =~ s/\'/\'\'/g; # if a quote is present in a string, we have to double it in order to escape.

my $cur;
if (!($cur =
      $::ful_dbh->prepare("insert into test(title,filesize,ft_sfname) values ('Pippo pippo non lo sa ma quando passa ride tutta la citta pippo pippo non lo sa pippo pippo non lo sa Pippo pippo non lo sa ma quando passa ride tutta la citta pippo pippo non lo sa pippo pippo non lo sa Pippo pippo non lo sa ma quando passa ride tutta la', $statdata[7], '" . $pwd . "/test.fte')"	))) {
   print "FAILED: Cannot prepare insert test.fte ($DBI::errstr)\n";
   exit 1;
}

if (!$cur->execute) {
   print "FAILED: Cannot execute insert test.fte ($DBI::errstr)\n";
   exit 1;
}

print "ok\n";

print "Row id (\$cur->{ful_last_row_id}) for the just inserted row: $cur->{ful_last_row_id} ...";
print "ok\n" if ($cur->{ful_last_row_id} > 0);
   
$cur->finish;

print "Rebuilding index... ";
if (!($::ful_dbh->do( "VALIDATE INDEX test VALIDATE TABLE"))) {
   print "FAILED: Cannot rebuild index ($DBI::errstr)\n";
}

print "ok\n";
#print "Regenerating test file... ";
#open INHDL, "<test.fte" && do {  # open for writing...
#   open TESTHDL, ">$pwd/test.fte" || die "Cannot write in $pwd! ($!)\n";
#   while (<INHDL>) { print TESTHDL $_;   }
#   close INHDL;
#   close TESTHDL;
#};
#print "ok\n";


print "Doing a query (expecting 'Data truncated' error)... ";
#$::ful_dbh->{LongTruncOk} = 0;

#my $cursor = $::ful_dbh->prepare ('select ft_text,ft_sfname,filesize,title from test where title contains \'pippo\'', {fulcrum_MaximumHitsInInternalColumns => 100});
my $cursor = $::ful_dbh->prepare ('select ft_text,ft_sfname,filesize,title from test where title contains \'pippo\'');
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
$DBD::Fulcrum::ful_maxhitsinternalcolumns = 64;
$cursor = $::ful_dbh->prepare ('select ft_text,ft_sfname,filesize,title from test where title contains \'pippo\'');
if ($cursor) {
   print "(execute) ... ";
   $cursor->execute;
   print "ok, now fetching (fetchrow):\n***\n";
   my $text;
   my @row;
   my $eot;
   my $data_truncated = 0;
   while (@row  = $cursor->fetchrow) {
      $data_truncated++ if ($DBI::state =~ /truncated/);
      $cursor->blob_read (1, 0, 8192, \$text);
      #or (print "+++ RB NOT OK:$DBI::errstr\n");
      $text = $` if ($text =~ /\x00/);
      print "(FILE: $row[1] TITLE: '$row[3]') "; #$text removed to clean up output
   }
   if ($data_truncated > 0) {
      print "FAILED: Data truncated when it shouldn't be!\n";
      exit 1;
   }
   print "\n***\n\tok\n";
}
else {
   print "FAILED: Prepare failed ($DBI::errstr)\n";
   exit 1;
}

$cursor->finish;
$ful_dbh->disconnect;

print "Exiting\nIf you are here, then most likely all tests were successful.\n";
exit 0;
# end.

