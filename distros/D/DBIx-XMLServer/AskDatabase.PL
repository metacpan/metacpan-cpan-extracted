print <<EOF;
To run the tests for DBIx::XMLServer, we need to have access to a
database.  Unfortunately, DBD::CSV isn't quite sophisticated enough
for this purpose, so you can now type in the name of a database that
the test script should use.  Within this database, which should
already exist, the test script will create new tables called
`dbixtest1' and `dbixtest2'; the tables will be deleted after the
test.  You should type a string which can be passed to DBI::connect,
such as `DBI:mysql:test'.

If you do not wish to do anything other than very basic tests on the
module, just press ENTER here.
EOF

print "Please enter a database: ";
my $dbname = <STDIN>; chop $dbname;
my $name='';
my $pass='';

if($dbname) { 
  print <<EOF; 
You will now be asked for a user name and password for the database.
If either of these is not needed, just press ENTER.  Note that the
user name and password will be stored for now in the file `t/dbname',
so people might be able to see them.  Don't use anything sensitive.
EOF
  print "User name: ";
  $name = <STDIN>; chop $name;
  print "Password: ";
  $pass = <STDIN>; chop $pass;
}

open FILE, ">t/dbname";
print FILE "$dbname,$name,$pass\n";
