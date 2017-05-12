#!perl -w

use Test::More tests => 16;

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}
sub BINMODE {}

my $Original_File = 'TempDB.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 86 /Users/dan/work/dan/Class-DBI-Test-TempDB/lib/Class/DBI/Test/TempDB.pm

use_ok('Class::DBI::Test::TempDB');


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 187 /Users/dan/work/dan/Class-DBI-Test-TempDB/lib/Class/DBI/Test/TempDB.pm

ok(Class::DBI::Test::TempDB->build_test_db('t/files/config.yaml', 't/files/testdb.sqlite'),
    'build test database');
ok(-e 't/files/testdb.sqlite', 'db file created');
ok(Class::DBI::Test::TempDB->tear_down_connection, 'tear_down_connection');
ok(!(-e 't/files/testdb.sqlite'), 'db file removed');


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 235 /Users/dan/work/dan/Class-DBI-Test-TempDB/lib/Class/DBI/Test/TempDB.pm

use File::Temp;

can_ok('Class::DBI::Test::TempDB', 'build_connection');
can_ok('Class::DBI::Test::TempDB', 'dsn');
can_ok('Class::DBI::Test::TempDB', 'connect_class_to_test_db');
can_ok('Class::DBI::Test::TempDB', 'tear_down_connection');

package Car;

use base 'Class::DBI';
Car->table('car');
Car->columns(All => qw/id make/);

package Car::TestDBI;

use base Class::DBI::Test::TempDB;

package main;

ok(Car::TestDBI->build_test_db('t/files/config.yaml'),
    'build test database');

my $dbh = Car::TestDBI->db_Main;

$dbh->do(qq{
    insert into car values (null, 'chevy')
}) or diag $dbh->errstr;

my @DSN = (Car::TestDBI->dsn, '', '', { AutoCommit => 1 });
Car->set_db(Main => @DSN);

my @cars = Car->retrieve_all;
my $car = $cars[0];
ok(eq_array([$car->id, $car->make], [1, 'chevy']), 'retrieve data from temp file');
ok($car->delete, 'delete CDBI object');

Car::TestDBI->tear_down_connection;
ok (!(-e Car::TestDBI->dbfile), 'tear_down_connection(): temp file');

Car::TestDBI->build_connection('/tmp/dbitestbase_test');
is(Car::TestDBI->dsn(), 'dbi:SQLite:dbname=/tmp/dbitestbase_test', 'dsn()');

$dbh = Car::TestDBI->db_Main;
Car->clear_object_index;

$dbh->do(qq{
    create table car (
        id          integer primary key,
        make        varchar(255)
    )
}) or diag $dbh->errstr;

$dbh->do(qq{
    insert into car values (null, 'nissan')
}) or diag $dbh->errstr;

Car::TestDBI->connect_class_to_test_db('Car');

@cars = Car->retrieve_all;
$car = $cars[0];
ok(eq_array([$car->id, $car->make], [1, 'nissan']), 'retrieve data from named file');

Car::TestDBI->tear_down_connection;
ok (!(-e Car::TestDBI->dbfile), 'tear_down_connection(): named file');


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

