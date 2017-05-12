use strict;

use Test::More tests => 27;

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');
}

# test misc. attributes of $dbh

my $dbh = DBI->connect('DBI:Mock:', '', '');
isa_ok($dbh, 'DBI::db'); 

$dbh->{AutoCommit} = 1;
ok($dbh->{AutoCommit}, '... it handles AutoCommit as well');

$dbh->{AutoCommit} = 0;
ok(! $dbh->{AutoCommit}, '... and turns off AutoCommit as well');

for (0 .. 5) {
    my $sth = $dbh->prepare('SELECT * FROM foo');
    $sth->execute();
}

is(scalar(@{$dbh->{mock_all_history}}), 6, '... we have 6 statements');

$dbh->{mock_clear_history} = 1;

is(scalar(@{$dbh->{mock_all_history}}), 0, '... we have 0 statements');

# test the misc. attributes of $sth

$dbh->{mock_add_resultset} = [['foo'], [1], [2], [3]];

my $SQL = 'SELECT foo FROM bar WHERE baz = ?';

# prepare a statement
my $sth = $dbh->prepare($SQL);

# mock_is_executed
is($sth->{mock_is_executed}, 'no', '... not executed yet');

# execute and bind the param
$sth->execute('test');

is($sth->{mock_is_executed}, 'yes', '... has been executed now');
    
# mock_my_history
my $history = $sth->{mock_my_history};
ok($history, '... got something back for our history');
isa_ok($history, 'DBD::Mock::StatementTrack');

# mock_statement
is($sth->{mock_statement}, $SQL, '... our statement is as expected');

# mock_fields
is_deeply(
    $sth->{mock_fields}, 
    [ 'foo' ], 
    '... our fields is as expected');

# mock_records
is_deeply(
    $sth->{mock_records}, 
    [[1], [2], [3]], 
    '... we have 3 records');

# mock_num_records
is($sth->{mock_num_records}, 3, '... we have 3 records');

# mock_current_record_num
is($sth->{mock_current_record_num}, 0, '... we are at record number 0');

# mock_is_finished
is($sth->{mock_is_finished}, 'no', '... we are not yet finished');

# mock_is_depleted
ok(!$sth->{mock_is_depleted}, '... nor are we depleted');

for (1 .. 3) {
    is(($sth->fetchrow_array())[0], $_, '... got the expected row');
    is($sth->{mock_current_record_num}, $_, '... we are at record number ' . $_);    
}

# mock_is_depleted
ok($sth->{mock_is_depleted}, '... now we are depleted');

# mock_is_finished
is($sth->{mock_is_finished}, 'no', '... we are not yet finished');

$sth->finish();

# mock_is_finished
is($sth->{mock_is_finished}, 'yes', '... and we are now finished');
