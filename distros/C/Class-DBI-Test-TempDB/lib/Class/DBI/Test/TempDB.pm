#!/usr/bin/perl -w

=head1 NAME

Class::DBI::Test::TempDB - Maintain a SQLite database for testing CDBI

=head1 Version

Version 1.0

=cut

our $VERSION = '1.01';

=head1 Synopsis

     package Music::TempDB;
     use base qw/Class::DBI::Test::TempDB/;

     __PACKAGE__->build_test_db();

     END {
         __PACKAGE__->tear_down_connection(); 
        # remove the db file at unload time
     }

     1;

     # ...Meanwhile, somewhere in Music::CD:

     =begin testing

     use Music::TempDB;
     # have our class use the test db:
     Music::TempDB->connect_class_to_test_db('Music::CD');

     # create some data in our test db:
     my $cd = Music::CD->create({
        title => "Jimmy Thudpucker's Greatest Hits",
        year  => 1978
     });

     # make sure it looks right:
     is($cd->year, 1978, 'year');
     # etc.

     # ... when done testing, delete data:
     $cd->delete();

     =end testing


=head1 Description

In testing, we generally want tests to create and destroy all their own data.
When writing Class::DBI-based projects, it's helpful to have a test database in
which to do this, so that we can (a) be sure we're not stepping on production
data, and (b) be sure of exactly what data is in the test database at the
beginning/end of each test.

Class::DBI::Test::TempDB handles the creation and destruction of a temporary
SQLite database on disk; it also allows you to point your Class::DBI classes at
the test database. You can then get on with creating, testing and destroying
test data simply by interacting with your Class::DBI classes.

The database can be persistent between tests, or it can be recreated for each
test, from a YAML file describing the schema to be created. It can be stored in
a temp file, or in a file with a user-supplied name.

Everything is done through class methods and subclassing.

=cut

use strict;

package Class::DBI::Test::TempDB;

use base qw/Class::Data::Inheritable Class::DBI/;
use File::Temp qw/tempfile/;
use SQL::Translator;
use Carp;

__PACKAGE__->mk_classdata('dbfile');

=begin testing

use_ok('Class::DBI::Test::TempDB');

=end testing

=head1 Methods

=head2 build_connection

If supplied a parameter, that parameter is used as the name of a database file
to be built (or connected to, if it already exists). If not, creates a
temporary file (using File::Temp). Once the file is created, this method
initializes a SQLite db in it, and points our package connection at it.

=cut

sub build_connection {
    my ($class, $filename) = @_;
    my $DB;
    if ($filename) {
        $DB = $filename;
    } else {
        (undef, $DB) = tempfile();
    }

    $class->dbfile($DB);

    my @DSN = ($class->dsn, '', '', { AutoCommit => 1 });
    $class->set_db(Main => @DSN);
}

=head2 dsn

Returns the string 'dbi:SQLite:dbname=' . <the name of the database file being used>

=cut

sub dsn {
    my $class = shift;
    return "dbi:SQLite:dbname=" . $class->dbfile;
}

=head2 tear_down_connection 

Removes the database file, if it still exists.

=cut

sub tear_down_connection {
    my $class = shift;
    unlink $class->dbfile if (-e $class->dbfile);
}

=head2 connect_class_to_test_db

Overrides the db_Main() method of the passed-in CDBI entity class so that it
calls our db_Main() instead. This is the methodology suggested by the CDBI
documentation for dynamically changing a class's database connection. NB the
warnings there about already-existing instances of the entity class: that is,
this should probably only be done at the beginning of a test script, before any
objects have been instantiated in the entity class.


=cut

sub connect_class_to_test_db {
    my ($class, $entityClass) = @_;

    # don't re-connect the class to our test db if the class is already
    # using it:
    unless ($class->db_Main == $entityClass->db_Main) {
        eval qq{
            sub ${entityClass}::db_Main {
                return $class->db_Main;
            }
        };
        die $@ if $@;
    }
}


=head2 build_test_db

 MyClass::DBI::Test->build_test_db(<$yaml, $dbfile>);

Given the path to a YAML file representing the schema of our production
database, generate a test SQLite database and use it.

By default, $yaml is 'config.yaml' and $dbfile is a temp file (we use
File::Temp, which see for details).

The YAML file is expected to be in the format produced by SQL::Translator
(which see for details); here's an example of a way to produce such a YAML file
from a MySQL database called 'mydatabase':

  mysqldump -d mydatabase | perl -MSQL::Translator -e 
    'my $sql = join "", <STDIN>; my $trans = SQL::Translator->new; 
    print $trans->translate(from => "MySQL", to => "YAML", data => $sql);' 
    > config.yaml

=begin testing

ok(Class::DBI::Test::TempDB->build_test_db('t/files/config.yaml', 't/files/testdb.sqlite'),
    'build test database');
ok(-e 't/files/testdb.sqlite', 'db file created');
ok(Class::DBI::Test::TempDB->tear_down_connection, 'tear_down_connection');
ok(!(-e 't/files/testdb.sqlite'), 'db file removed');

=end testing

=cut

sub build_test_db {
    my ($class, $yaml, $filename) = @_;
    $yaml ||= 'config.yaml';
    $filename ||= '';
    my $trans = SQL::Translator->new;
    my $sqlite_schema = $trans->translate(
        from => "YAML", to => "SQLite", filename => $yaml) or
        die $trans->error;

    # In order to execute the dumped sqlite schema statements against
    # our dbh, we have to get rid of comments (lines starting with "--") and
    # skip BEGIN TRANSACTION and COMMIT lines:

    my @lines = split "\n", $sqlite_schema;
    my @filtered_lines = grep {
        $_ !~ /^\-\-/;
    } @lines;

    $sqlite_schema = join "\n", @filtered_lines;

    my @statements = split /;/, $sqlite_schema;

    unlink $filename if (-e $filename);

    $class->build_connection($filename);

    # execute dumped sql schema against dbh:
    foreach (@statements) {
        next if /^BEGIN\sTRANSACTION/;
        next if /^\W*COMMIT/;
        $class->db_Main->do($_) or warn $class->db_Main->errstr;
    }

    return $class->db_Main;
}

=begin testing

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

=end testing

=head1 See Also

L<Class::DBI>, L<SQL::Translator>, L<File::Temp>

=head1 Limitations

Of course, this module can only handle things that SQLite can handle.

=head1 Author

Dan Friedman, C<< <lamech@cpan.org> >>

=head1 Acknowledgements

Thanks to Kirrily "Skud" Robert for early design input.

Thanks to Tony Bowden for module naming help.

Lots of ideas were taken from the testsuite that accompanies Class::DBI.

=head1 Bugs

Please report any bugs or feature requests to
C<bug-class-dbi-test-tempdb@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 Copyright & License

Copyright 2004 Dan Friedman, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Class::DBI::Test::TempDB
