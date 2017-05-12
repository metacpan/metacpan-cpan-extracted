#!/usr/bin/perl -w

use strict;

use File::Spec;

use lib '.', File::Spec->catdir( File::Spec->curdir, 't', 'lib' );

use Alzabo::Test::Utils;

use Test::More;


my @rdbms_names = Alzabo::Test::Utils->rdbms_names;

unless (@rdbms_names)
{
    plan skip_all => 'no test config provided';
    exit;
}

my $tests_per_run = 11;
my $mysql_tests = 2;
my $pg_tests = 2;

my $tests = $tests_per_run * @rdbms_names;
$tests += $mysql_tests if grep { $_ eq 'mysql' } @rdbms_names;
$tests += $pg_tests if grep { $_ eq 'pg' } @rdbms_names;

plan tests => $tests;



Alzabo::Test::Utils->remove_all_schemas;


foreach my $rdbms (@rdbms_names)
{
    my $s = Alzabo::Test::Utils->make_schema($rdbms);

    my %connect = Alzabo::Test::Utils->connect_params_for($rdbms);

    $s->table('employee')->delete_column( $s->table('employee')->column('name') );


    eval_ok( sub { $s->create(%connect) },
	     "Create schema (via diff) with one column deleted" );

    $s->table('department')->make_column( name => 'foo',
					  type => 'int',
					  nullable => 1 );

    eval_ok( sub { $s->create(%connect) },
	     "Create schema (via diff) with one column added" );

    $s->delete_table( $s->table('department') );

    eval_ok( sub { $s->create(%connect) },
	     "Create schema (via diff) with one table deleted" );

    $s->make_table( name => 'cruft' );
    $s->table('cruft')->make_column( name => 'cruft_id',
				     type => 'int',
				     primary_key => 1,
				   );

    eval_ok( sub { $s->create(%connect) },
	     "Create schema (via diff) with one table added" );

    my $idx = ($s->table('project')->indexes)[0];

    $s->table('project')->delete_index($idx);

    eval_ok( sub { $s->create(%connect) },
	     "Create schema (via diff) with one index deleted" );

    $s->table('cruft')->make_column( name => 'cruftiness',
				     type => 'int',
				     nullable => 1,
				     default => 10 );

    eval_ok( sub { $s->create(%connect) },
	     "Create schema (via diff) with one column (null and with a default) added" );

    $s->driver->handle->do( 'INSERT INTO cruft (cruft_id, cruftiness) VALUES (1, 2)' );
    $s->driver->handle->do( 'INSERT INTO cruft (cruft_id, cruftiness) VALUES (2, 4)' );

    my $float_type = $rdbms eq 'pg' ? 'float8' : 'float';
    $s->table('cruft')->column('cruftiness')->set_type($float_type);
    $s->table('cruft')->set_name('new_cruft');

    eval_ok( sub { $s->create(%connect) },
	     "Create schema (via diff) with a table name change and column type change" );

    my ($val) =
        $s->driver->handle->selectrow_array( 'SELECT cruftiness FROM new_cruft WHERE cruft_id = 2' );
    is( $val, 4,
        "Data should be preserved across table name change" );

    $s->table('new_cruft')->column('cruft_id')->set_name('new_cruft_id');

    eval_ok( sub { $s->create(%connect) },
	     "Create schema (via diff) with a column name change" );

    ($val) =
        $s->driver->handle->selectrow_array( 'SELECT cruftiness FROM new_cruft WHERE new_cruft_id = 2' );
    is( $val, 4,
        "Data should be preserved across column name change" );

    {
        # Test table rename followed by drop column

        my $table = $s->table('employee');
        $table->set_name('new_emp_table');

        $table->delete_column( $table->column('smell') );

        my $sql = join "\n", $s->make_sql;

        if ( $rdbms eq 'mysql' )
        {
            like( $sql, qr/RENAME TABLE\s+employee\s+TO\s+new_emp_table/i,
                  'SQL should include rename to new table name' );
            like( $sql, qr/ALTER TABLE\s+new_emp_table/i,
                    'ALTER TABLE should refer to new table name' );
        }
        elsif ( $rdbms eq 'pg' )
        {
            like( $sql, qr/DROP TABLE\s+"employee"/i,
                  'SQL should include dropping table with old name' );
            like( $sql, qr/CREATE TABLE\s+"new_emp_table"/i,
                  'SQL should include creation of table with new name' );
        }
    }

    {
        # will instantiate with renamed table from above block
        $s->create(%connect);

        # a bug (which should be fixed) caused bogus SQL to be
        # generated when comparing this schema to a live DB with the
        # rename already done.
        my $sql = join "\n", $s->sync_backend_sql(%connect);
        $sql ||= '';

        is( $sql, '',
            'No SQL should be generated when syncing to a backend after instantiating'
            . ' with a renamed table'
          );
    }
}
