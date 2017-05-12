#!/usr/bin/perl -w

use strict;
$| = 1;

if ($ENV{'GATEWAY_INTERFACE'}) {
 # run these if you run it via CGI
 require CGI;
 my $query = new CGI;
 print $query->header(-type=>'text/plain');
}

print "1..2\n";
#print "Read and Write test: 1..2\n";

print "Load the module: use DB_File::DB_Database\n";
eval 'use DB_File::DB_Database';
if ($@ ne '') {
	print "'use DB_File::DB_Database' Failed!\n";
	die;
}

my $loaded = 1;
END	{ print "Error when: use DB_File::DB_Database\n" unless $loaded; }

print "This is DB_File::DB_Database version $DB_File::DB_Database::VERSION\n";
my $dir = ( -d "t" ? "t" : "." );
my @files = <$dir/dbtest2*>;
if (@files) {
	print "Dropping: @files\n";
	unlink @files;
}

#$DB_File::DB_Database::DEBUG = 0;        # We want to see any problems

#   #############################################################
my $newtable = DB_File::DB_Database->create(     "name"        => "$dir/dbtest2",
                                        "field_names" => [ "Name", "sex", "age", "school" ],
                                        "field_types" => [ "C",    "c",    "N",     "C"   ],
                                        'permits'     => 0640 );
print DB_File::DB_Database->errstr(), 'Error Creating new DB_File::DB_Database file' unless defined $newtable;
exit unless defined $newtable;     # It doesn't make sense to continue here ;-)

# 1 #############################################################
print "Write data\n";
my @result = $newtable->set_record("1", "Judy", "girl", "18", "SEU");
print "Error writing data\n","not" if $result[0] ne "1";
@result = $newtable->set_record("2", "Kite", "girl", "24", "MSU");
print "Error writing data\n","not" if $result[0] ne "2";
print "ok\n";

#   #############################################################
$newtable->close;
print DB_File::DB_Database->errstr(), 'Error Closing DB_File::DB_Database file' unless defined $newtable;

#   #############################################################
my $table = new DB_File::DB_Database("$dir/dbtest2");
print DB_File::DB_Database->errstr(), 'not ' unless defined $table;

# 2 #############################################################
print "Read data\n";
my @data = $table->get_record("1");
my @data_expected = ("1", "Judy", "girl", "18", "SEU");
foreach $_ (0..@data-1) {
	if (not $data[$_] eq $data_expected[$_]) {
		print "Getting data       : ","@data ","\n";
		print "Expected result    : ","@data_expected ","\n";
		print "not ";
		last;
	}
}
print "ok\n";

#   #############################################################
$table->close;
print DB_File::DB_Database->errstr(), 'Error Closing DB_File::DB_Database file' unless defined $table;

exit;
