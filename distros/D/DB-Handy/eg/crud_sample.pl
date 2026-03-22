#!/usr/bin/perl
######################################################################
# 01_crud_sample.pl - Basic CRUD operations using DB::Handy
######################################################################
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;

use FindBin ();
use lib "$FindBin::Bin/../lib";
use DB::Handy;
use File::Path ();

my $base_dir = './sample_db';
File::Path::rmtree($base_dir) if -d $base_dir;

print "--- DB::Handy CRUD Sample ---\n\n";

# 1. Initialize Database
print "[1] Initialize Database...\n";
my $db = DB::Handy->new(base_dir => $base_dir);
$db->create_database('school');

# 2. Connect via DBI-like interface
my $dbh = DB::Handy->connect($base_dir, 'school');

# 3. CREATE (Create Table)
print "[2] Create Table 'student'...\n";
$dbh->do("CREATE TABLE student (id INT PRIMARY KEY, name VARCHAR(20), score INT)");

# 4. INSERT (Create Records)
print "[3] Insert Data...\n";
my $sth_ins = $dbh->prepare("INSERT INTO student (id, name, score) VALUES (?, ?, ?)");
$sth_ins->execute(1, 'Alice', 85);
$sth_ins->execute(2, 'Bob',   70);
$sth_ins->execute(3, 'Carol', 95);
$sth_ins->finish;

# 5. SELECT (Read)
print "\n[4] Select Data (ORDER BY score DESC)...\n";
my $sth_sel = $dbh->prepare("SELECT id, name, score FROM student ORDER BY score DESC");
$sth_sel->execute;
while (my $row = $sth_sel->fetchrow_hashref) {
    print "  ID: $row->{id}, Name: $row->{name}, Score: $row->{score}\n";
}
$sth_sel->finish;

# 6. UPDATE (Update)
print "\n[5] Update Data (Bob's score -> 80)...\n";
$dbh->do("UPDATE student SET score = 80 WHERE name = 'Bob'");

# 7. DELETE (Delete)
print "[6] Delete Data (Alice drops out)...\n";
$dbh->do("DELETE FROM student WHERE name = 'Alice'");

# 8. SELECT again
print "\n[7] Select Data (After Update & Delete)...\n";
$sth_sel->execute;
while (my $row = $sth_sel->fetchrow_hashref) {
    print "  ID: $row->{id}, Name: $row->{name}, Score: $row->{score}\n";
}
$sth_sel->finish;

$dbh->disconnect;
print "\n--- End of Sample ---\n";
