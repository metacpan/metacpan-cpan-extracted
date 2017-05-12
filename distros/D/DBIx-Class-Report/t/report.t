#!/usr/bin/env perl
BEGIN {
    $ENV{SCHEMA_LOADER_BACKCOMPAT} = 1;

    #    $ENV{DBIC_TRACE}               = 1;
}

use strict;
use warnings;
use File::Temp qw(tempfile);
use DBI;
use DBIx::Class::Report;
use DBIx::Class::Schema::Loader 'make_schema_at';
use Test::Most;

# EXLOCK prevents locking under OS X
my ( $fh, $filename )
  = tempfile( 'dbic_reportXXXX', EXLOCK => 0, UNLINK => 1 );

my $dsn = "dbi:SQLite:dbname=$filename";
my $dbh = DBI->connect(
    $dsn, "", "",
    {   RaiseError                 => 1,
        AutoCommit                 => 1,
        sqlite_see_if_its_a_number => 1
        , # https://metacpan.org/pod/DBD::SQLite#Functions-And-Bind-Parameters ,
    }
);

load_database($dbh);

make_schema_at(
    'Sample::DBIx::Class',
    {},    #    { debug => 1 },
    [ $dsn, '', '' ]
);

my $expected = [
    [ 'Alice', 3 ],
    [ 'Bob',   2 ],
];
eq_or_diff $dbh->selectall_arrayref(<<'SQL'), $expected, 'DB sanity check';
  SELECT c.name, count(*) as total
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.name
  HAVING total >= 2
SQL

my $report_sql = <<'SQL';
  SELECT c.name, count(*) as total
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.name
  HAVING total >= ?
SQL

my $schema = Sample::DBIx::Class->connect( sub {$dbh} );
my $sales_per_customers = DBIx::Class::Report->new(
    columns => ['name', 'total' => { data_type => 'integer' }],
    sql     => $report_sql,
    schema  => $schema,
    base_class => 'Test::ReportBaseClass',
    methods => {
        reversed_name =>
          sub { my $self = shift; return scalar reverse $self->name },
    },
);

my $customer_rs = $schema->resultset('Customers');
#while ( my $customer = $customer_rs->next ) {
#    diag $customer->name;
#}

my $resultset = $sales_per_customers->fetch(2);

is 0 + $dbh, 0 + $resultset->result_source->storage->dbh,
  'We should be sharing the same database handle';

is $resultset->count, 2,
  'We should have two matching records from our resultset';

$resultset = $sales_per_customers->fetch(3);

is $resultset->count, 1,
  '... and we should be able to call fetch() again with different arguments';

my $result = $resultset->single;
is $result->name,  'Alice', '... and get the correct name';
is $result->total, 3,       '... and the correct total';
is $result->reversed_name, 'ecilA',
  '... and we can add arbitrary methods to the result objects';

is $result->_test_base_class => 'base class',
    "Should have created the object with the correct base class";

TODO: {
    local $TODO = 'Why the heck is this fetch not throwing an exception?';
    explain
      "Maybe related to https://rt.cpan.org/Public/Bug/Display.html?id=29058";

    # calling ->search->first guarantees that the SQL is actually executed
    throws_ok { $sales_per_customers->fetch()->search->first }
    qr/Wrong number of bind parameters/,
      'Calling fetch() with the wrong number of bind parameters should fail';
}

done_testing;

#
# End of tests
#

sub load_database {
    $dbh->do(<<'SQL');
CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT    NOT NULL,
    age         INTEGER NOT NULL
);
SQL

    $dbh->do(<<'SQL');
CREATE TABLE orders (
    order_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id INTEGER NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
SQL

    $dbh->do(<<'SQL');
INSERT INTO customers (name, age) VALUES
    ('Alice',    47),
    ('Bob',      19),
    ('Charline', 32);
SQL

    $dbh->do(
        "INSERT INTO orders (customer_id) SELECT customer_id FROM customers WHERE name = 'Alice'"
    );
    $dbh->do(
        "INSERT INTO orders (customer_id) SELECT customer_id FROM customers WHERE name = 'Alice'"
    );
    $dbh->do(
        "INSERT INTO orders (customer_id) SELECT customer_id FROM customers WHERE name = 'Alice'"
    );
    $dbh->do(
        "INSERT INTO orders (customer_id) SELECT customer_id FROM customers WHERE name = 'Bob'"
    );
    $dbh->do(
        "INSERT INTO orders (customer_id) SELECT customer_id FROM customers WHERE name = 'Bob'"
    );
    $dbh->do(
        "INSERT INTO orders (customer_id) SELECT customer_id FROM customers WHERE name = 'Charline'"
    );
}

package Test::ReportBaseClass;
use parent 'DBIx::Class::Core';

sub _test_base_class { "base class" }
