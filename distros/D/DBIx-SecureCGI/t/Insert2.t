use lib 't';
use share;

plan tests => 3;

my $dbh = new_dbh;
my $table_i = new_table 'id int auto_increment primary key, i int';

my @test_i = (
    "{i=>undef}"		=> [{id=>1,i=>undef}],
    "{i=>0}"			=> [{id=>1,i=>0}],
    "{i=>1}"			=> [{id=>1,i=>1}],
    );

my $sth = $dbh->prepare("SELECT * FROM $table_i");
while (@test_i) {
    my ($test, $wait) = (shift @test_i, shift @test_i);
    $dbh->Insert($table_i, eval($test));
    $sth->execute();
    is_deeply($sth->fetchall_arrayref({}), $wait, $test);
    $dbh->do("TRUNCATE TABLE $table_i");
}

done_testing();
