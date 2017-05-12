# -*- perl -*-

require 5.004;
use strict;


require DBI;
require Benchmark;


my($i);
sub TimeMe ($$$$) {
    my($startMsg, $endMsg, $code, $count) = @_;
    printf("\n%s\n", $startMsg);
    my($t1) = Benchmark->new();
    $@ = '';
    eval {
	for ($i = 0;  $i < $count;  $i++) {
	    &$code;
	}
    };
    if ($@) {
	print "Test failed, message: $@\n";
    } else {
	my($td) = Benchmark::timediff(Benchmark->new(), $t1);
	my($dur) = $td->cpu_a;
	printf($endMsg, $count, $dur, $count / $dur);
	print "\n";
    }
}


TimeMe("Testing empty loop speed ...",
       "%d iterations in %.1f cpu+sys seconds (%d per sec)",
       sub {
       },
    100000);


my($dbh);
TimeMe("Testing connect/disconnect speed ...",
       "%d connections in %.1f cpu+sys seconds (%d per sec)",
       sub {
	   $dbh = DBI->connect("DBI:RAM:", undef, undef,
			       { 'RaiseError' => 1 });
	   $dbh->disconnect();
       },
    2000);

$dbh = DBI->connect("DBI:RAM:", undef, undef,
                    { 'RaiseError' => 1 });
TimeMe("Testing CREATE/DROP TABLE speed ...",
       "%d files in %.1f cpu+sys seconds (%d per sec)",
       sub {
	   $dbh->do("CREATE TABLE bench (id INTEGER, name CHAR(40),"
		    . " firstname CHAR(40), address CHAR(40),"
		    . " zip CHAR(10), city CHAR(40), email CHAR(40))");
	   $dbh->do("DROP TABLE bench");
       },
    500);

$dbh->do("CREATE TABLE bench (id INTEGER, name CHAR(40),"
    . " firstname CHAR(40), address CHAR(40),"
    . " zip CHAR(10), city CHAR(40), email CHAR(40))");
my(@vals) = (0 .. 499);
my($num);
TimeMe("Testing INSERT speed ...",
       "%d rows in %.1f cpu+sys seconds (%d per sec)",
       sub {
	   ($num) = splice(@vals, int(rand(@vals)), 1);
	   $dbh->do("INSERT INTO bench VALUES (?, 'Wiedmann', 'Jochen',"
		    . " 'Am Eisteich 9', '72555', 'Metzingen',"
		    . " 'joe\@ispsoft.de')", undef, $num);
       },
    500);

my($sth);
TimeMe("Testing SELECT speed ...",
       "%d single rows in %.1f cpu+sys seconds (%.1f per sec)",
       sub {
	   $num = int(rand(500));
	   $sth = $dbh->prepare("SELECT * FROM bench WHERE id = $num");
	   $sth->execute();
	   $sth->fetch() or die "Expected result for id = $num";
       },
    100);


TimeMe("Testing SELECT speed (multiple rows) ...",
       "%d times 100 rows in %.1f cpu+sys seconds (%.1f per sec)",
       sub {
	   $num = int(rand(400));
	   $sth = $dbh->prepare("SELECT * FROM bench WHERE id >= $num"
				. " AND id < " . ($num+100));
	   $sth->execute();
	   ($sth->rows() == 100)
	       or die "Expected 100 rows for id = $num, got " . $sth->rows();
	   while ($sth->fetch()) {
	   }
       },
    100);

