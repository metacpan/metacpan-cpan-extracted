#perl -T

use strict;
use warnings;

use Test::More;
use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;

ok $dbh->do("CREATE TYPE mood AS ENUM ('sad', 'ok', 'happy')") == 0,    'Create "mood" ENUM';
ok $dbh->do("CREATE TYPE breed AS ENUM ('maltese', 'Maltese')") == 0,   'Create "breed" table with ENUM';
ok $dbh->do("CREATE TABLE person (name TEXT, current_mood mood)") == 0, 'Create "person" table using "mood" ENUM';

my $row = $dbh->selectrow_arrayref("SELECT 'maltese'::breed = 'Maltese'::breed");
ok $row->[0] == !!0, 'ENUM maltese != Maltese';

$dbh->selectrow_arrayref("SELECT 'MALTESE'::breed");
ok $dbh->errstr, 'Invalid ENUM value';


ok $dbh->do(q{INSERT INTO person VALUES
    ('Pedro', 'happy'),
    ('Mark', NULL),
    ('Pagliacci', 'sad'),
    ('Mr. Mackey', 'ok')
}) == 4, 'Insert data in "person" table';

ok !$dbh->do("INSERT INTO person VALUES ('Hannes', 'quackity-quack')"), 'Insert invalid ENUM value';

ok $dbh->errstr, 'Invalid ENUM value';


done_testing;
