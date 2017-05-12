#!/usr/bin/perl -w
#
# Tests for Data::Toolkit::Connector

use strict;

use lib '../lib';

use Carp;
use Test::Simple tests => 15;

use Data::Toolkit::Connector;
use Data::Toolkit::Connector::CSV;
use Data::Toolkit::Entry;
use Data::Toolkit::Map;
use Data::Dumper;
use Text::CSV_XS;

# Test files may be in the current directory or down one level (e.g. if we are running under Test::Harness)
#
my $CSV1 = -f '4-csv1.csv' ? '4-csv1.csv' : 'tests/4-csv1.csv';

my $verbose = 0;
ok (Data::Toolkit::Connector::CSV->debug($verbose) == $verbose, "Setting Connector debug level to $verbose");


my $conn1 = Data::Toolkit::Connector->new({testJunk => 'plugh'});
ok (($conn1 and $conn1->isa( "Data::Toolkit::Connector" )), "Create new Data::Toolkit::Connector object");

my $conn2 = Data::Toolkit::Connector::CSV->new({testStuff => 'yada'});
ok (($conn2 and $conn2->isa( "Data::Toolkit::Connector::CSV" )), "Create new Data::Toolkit::Connector::CSV object");

#
# Prepare environment for CSV reading
#
my $fh;
open SOURCE, "< $CSV1" or die "Cannot open file $CSV1 - test cannot continue";

sub getSource {
	return <SOURCE>;
}

my $csv = Text::CSV_XS->new() or die "Cannot create Text::CSV_XS object";

# my $fields;
# while ($fields = $csv->getline($fh) and defined($fields->[0])) {
# 	print "GOT: ", (join ':', @$fields), "\n";
# }

ok ($conn2->parser( $csv ), "Assign CSV parser");
ok ($conn2->datasource( \&getSource ), "Assign datasource");
ok ($conn2->columns( ['one','two','three'] ), "Assign column names");

my $entry;
# while ($entry = $conn2->next()) {
# 	print $entry->dump(), "\n";
# }

$entry = $conn2->next();
ok ( ($entry and $entry->get('one')->[0] eq 'first'), "Read first line of CSV file");
$entry = $conn2->next();
ok ( ($entry and $entry->get('three')->[0] eq 'here'), "Read second line of CSV file");
ok ( ($conn2 and $conn2->linecount() == 2), "Line count is correct");
# print "LINE: ", $conn2->currentline(), "\n";
ok ( ($conn2 and $conn2->currentline() eq 'second,line,here,too'), "Current line returned correctly");
$entry = $conn2->next();
ok ( ($entry and $entry->get('two')->[0] eq 'set'), "Read third line of CSV file");
$entry = $conn2->next();
ok ( !$entry, "Read past end of CSV file" );

#
# Close file and re-open for more tests
#
close SOURCE;
open SOURCE, "< $CSV1" or die "Cannot open file $CSV1 - test cannot continue";
ok ($conn2->datasource( sub { <SOURCE> } ), "Assign closure as datasource");

my @fields = $conn2->colsFromFile();
ok ( ($fields[0] eq 'first'), "Obtain field names from first line of CSV file");
$entry = $conn2->next();
ok ( ($entry and $entry->get('first')->[0] eq 'second'), "Read second line of CSV file");

