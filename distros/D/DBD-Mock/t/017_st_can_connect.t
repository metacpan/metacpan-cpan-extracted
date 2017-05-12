use strict;

use Test::More tests => 23;

BEGIN {
    use_ok('DBD::Mock'); 
    use_ok('DBI');
}

my $dbh = DBI->connect('DBI:Mock:', '', '', { RaiseError => 1, PrintError => 0 });
isa_ok($dbh, "DBI::db");
ok($dbh->{RaiseError}, '... RaiseError is set correctly');
ok(! $dbh->{PrintError}, '... PrintError is set correctly');

my $sth_exec = $dbh->prepare('SELECT foo FROM bar');
isa_ok($sth_exec, "DBI::st");

# turn off the handle between the prepare and execute...
$dbh->{mock_can_connect} = 0;

# check our value is correctly set
is($dbh->{mock_can_connect}, 0, '... can connect is set to 0');

# and check the side effects of that
ok(!$dbh->{Active}, '... the handle is not Active');
ok(!$dbh->ping(), '... and ping returns false');

# now try to execute it

eval { $sth_exec->execute() };
ok($@, '... we got an exception');
like($@, qr/No connection present/, '... we got the expected execption');

# turn off the database between execute and fetch

$dbh->{mock_can_connect} = 1;

# check our value is correctly set
is($dbh->{mock_can_connect}, 1, '... can connect is set to 1');

# and check the side effects of that
ok($dbh->{Active}, '... the handle is Active');
ok($dbh->ping(), '... and ping returns true');

$dbh->{mock_add_resultset} = [[ qw(foo bar   ) ],  # column headers
                              [ qw(this that ) ],  # first row values
                              [ qw(never seen) ]]; # second row values
                               
my $sth_fetch = $dbh->prepare('SELECT foo, bar FROM baz');
isa_ok($sth_fetch, "DBI::st");

eval { $sth_fetch->execute() };
ok(!$@, '... executed without exception');

my $row = eval { $sth_fetch->fetchrow_arrayref() };
ok(!$@, '... the first row was returned without execption');
is_deeply($row, [ qw(this that) ], '... we got back the expected data in the first row');

# now turn off the database
$dbh->{mock_can_connect} = 0;

# check our value is correctly set
is($dbh->{mock_can_connect}, 0, '... can connect is set to 0');

# and check the side effects of that
ok(!$dbh->{Active}, '... the handle is not Active');
ok(!$dbh->ping(), '... and ping returns false');

$row = eval { $sth_fetch->fetchrow_arrayref() };
ok($@, '... we got the exception');
like($sth_fetch->errstr, 
     qr/^No connection present/,
     '... fetching row against inactive db throws expected exception' );
