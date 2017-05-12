#!/usr/bin/perl -w

use strict;
$| = 1;

if ($ENV{'GATEWAY_INTERFACE'}) {
 # run these if you run it via CGI
 require CGI;
 my $query = new CGI;
 print $query->header(-type=>'text/plain');
}

print "1..6\n";
#print "Basically create/open/close/drop test: 1..6\n";

print "Load the module: use DB_File::DB_Database\n";
eval 'use DB_File::DB_Database';
if ($@ ne '') {
	print "'use DB_File::DB_Database' Failed!\n";
	die;
}

my $loaded = 1;
END	{ print "not ok\n" unless $loaded; }
print "ok\n";
print "This is DB_File::DB_Database version $DB_File::DB_Database::VERSION\n";
my $dir = ( -d "t" ? "t" : "." );
my @files = <$dir/dbtest1*>;
if (@files) {
	print "Dropping: @files\n";
	unlink @files;
}

#$DB_File::DB_Database::DEBUG = 0;        # We want to see any problems

# 2 #############################################################
print "Create new DB_File::DB_Database file\n";
my $newtable = DB_File::DB_Database->create(     "name"        => "$dir/dbtest1",
                                        "field_names" => [ "Name", "sex", "age", "school" ],
                                        "field_types" => [ "C",    "c",    "N",     "C"   ],
                                        'permits'     => 0640 );
print DB_File::DB_Database->errstr(), 'not ' unless defined $newtable;
print "ok\n";
exit unless defined $newtable;     # It doesn't make sense to continue here ;-)

# 3 #############################################################
print "Close DB_File::DB_Database file\n";
$newtable->close;
print DB_File::DB_Database->errstr(), 'not ' unless defined $newtable;
print "ok\n";

# 4 #############################################################
print "Open a existed DB_File::DB_Database file\n";
my $table = new DB_File::DB_Database("$dir/dbtest1");
print DB_File::DB_Database->errstr(), 'not ' unless defined $table;
print "ok\n";
# 5 #############################################################
print "Check for the fields definition\n";
my @field_name = $table->field_names;
my @field_name_expected = ("NAME","SEX","AGE","SCHOOL");
foreach $_ (0..@field_name-1) {
	if (not $field_name[$_] eq $field_name_expected[$_]) {
		print "Getting Filed_name : ","@field_name ","\n";
		print "Expected result    : ","@field_name_expected ","\n";
		print "not ";
		last;
	}
}
my @field_type = $table->field_types;
my @field_type_expected = ("C","C","N","C");
foreach $_ (0..@field_type-1) {
	if (not $field_type[$_] eq $field_type_expected[$_]) {
		print "Getting Filed_type : ","@field_type ","\n";
		print "Expected result    : ","@field_type_expected ","\n";
		print "not ";
		last;
	}
}
print "ok\n";

# 6 #############################################################
print "Drop the DB_File::DB_Database file\n";
$table->NullError;
$table->drop or print $table->errstr, 'not ';
print "ok\n";

