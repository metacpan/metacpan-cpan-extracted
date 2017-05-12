# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MySperql.t'

#########################
# Change these vars and extend the exit below for testing

$db    = 'mydb';
$user  = 'myuser';
$pass  = 'mypass';
$table = 'mytable';

# 
#########################

use DBI;
use DBIx::MySperql qw(DBConnect SQLExec GetFieldNames $dbh);
#use Test::More tests => 4;
use Test::More tests => 1;

BEGIN { use_ok('DBIx::MySperql') };

exit;
__END__

#########################

# Open connect
$dbh = DBConnect(database => $db, host => 'localhost', user => $user, pass => $pass);
  
ok($dbh, 'DBConnect');

# Get table
$sql = "select * from $table limit 5";
$sth = SQLExec($sql, '$sth');
@fields = GetFieldNames($sth);
print join(', ', @fields) . "\n";
ok(@fields, 'Field Names');

$rows = SQLExec($sql, '\@@');
foreach $row (@$rows) {
	$text .= join(', ', @$row) . "\n";
}
 
print $text;

ok($text, 'Table Select');


