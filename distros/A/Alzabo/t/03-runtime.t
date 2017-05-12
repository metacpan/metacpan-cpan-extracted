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

my $tests_per_run = 340;
my $test_count = $tests_per_run * @rdbms_names;

my %SINGLE_RDBMS_TESTS = ( mysql => 23,
			   pg => 11,
			 );

foreach my $rdbms ( keys %SINGLE_RDBMS_TESTS )
{
    next unless grep { $_ eq $rdbms } @rdbms_names;

    $test_count += $SINGLE_RDBMS_TESTS{$rdbms};
}

plan tests => $test_count;


Alzabo::Test::Utils->remove_all_schemas;


foreach my $rdbms (@rdbms_names)
{
    if ( $rdbms eq 'mysql' )
    {
        # prevent subroutine redefinition warnings
        local $^W = 0;
	eval 'use Alzabo::SQLMaker::MySQL qw(:all)';
    }
    elsif ( $rdbms eq 'pg' )
    {
        local $^W = 0;
	eval 'use Alzabo::SQLMaker::PostgreSQL qw(:all)';
    }

    Alzabo::Test::Utils->make_schema($rdbms);

    run_tests($rdbms);

    Alzabo::Test::Utils->remove_schema($rdbms);
}

sub run_tests
{
    my $rdbms = shift;

    my $config = Alzabo::Test::Utils->test_config_for($rdbms);

    my $s = Alzabo::Runtime::Schema->load_from_file( name => $config->{schema_name} );

    # tests setting basic parameters and connecting to RDBMS
    {
        eval_ok( sub { $s->set_user('foo') },
                 "Set user for schema to foo" );

        eval_ok( sub { $s->set_password('foo') },
                 "Set password for schema to foo" );

        eval_ok( sub { $s->set_host('foo') },
                 "Set host for schema to foo" );

        eval_ok( sub { $s->set_port(1234) },
                 "Set port for schema to 1234" );

        $s->$_(undef) foreach qw( set_user set_password set_host set_port );

        $s->connect( Alzabo::Test::Utils->connect_params_for($rdbms) );

        $s->set_referential_integrity(1);
    }

    {
        my $dbh = $s->driver->handle;
        isa_ok( $dbh, ref $s->driver->{dbh},
                "Object returned by \$s->driver->handle method" );

        eval_ok( sub { $s->driver->handle($dbh) },
                 "Set \$s->driver->handle" );
    }

    my $emp_t = $s->table('employee');
    my $dep_t = $s->table('department');
    my $proj_t = $s->table('project');
    my $emp_proj_t = $s->table('employee_project');

    my %dep;
    eval_ok( sub { $dep{borg} = $dep_t->insert( values => { name => 'borging' } ) },
	     "Insert borging row into department table" );

    is( $dep{borg}->select('name'), 'borging',
	"The borg department name should be 'borging'" );

    {
	my @all = $dep{borg}->select;
	is( @all, 3,
	    "select with no columns should return all the values" );
	is( $all[1], 'borging',
	    "The second value should be the department name" );

	my %all = $dep{borg}->select_hash;
	is( keys %all, 3,
	    "select_hash with no columns should return two keys" );
	ok( exists $all{department_id},
	    "The returned hash should have a department_id key" );
	ok( exists $all{name},
	    "The returned hash should have a department_id key" );
	is( $all{name}, 'borging',
	    "The value of the name key be the department name" );
    }


    $dep{lying} = $dep_t->insert( values => { name => 'lying to the public' } );

    my $borg_id = $dep{borg}->select('department_id');
    delete $dep{borg};

    eval_ok( sub { $dep{borg} = $dep_t->row_by_pk( pk => $borg_id ) },
	     "Retrieve borg department row via row_by_pk method" );

    isa_ok( $dep{borg}, 'Alzabo::Runtime::Row',
	    "Borg department" );

    is( $dep{borg}->select('name'), 'borging',
	"Department's name should be 'borging'" );

    eval { $dep_t->insert( values => { name => 'will break',
				       manager_id => 1 } ); };

    my $e = $@;
    isa_ok( $e, 'Alzabo::Exception::ReferentialIntegrity',
	    "Exception thrown from attempt to insert a non-existent manager_id into department" );

    my %emp;
    eval_ok( sub { $emp{bill} = $emp_t->insert( values => { name => 'Big Bill',
							    dep_id => $borg_id,
							    smell => 'robotic',
							    cash => 20.2,
							  } ) },
	     "Insert Big Bill into employee table" );

    my %data = $emp{bill}->select_hash( 'name', 'smell' );
    is( $data{name}, 'Big Bill',
	"select_hash - check name key" );
    is( $data{smell}, 'robotic',
	"select_hash - check smell key" );

    is( $emp{bill}->is_live, 1,
        "->is_live should be true for real row" );

    eval { $emp_t->insert( values => { name => undef,
				       dep_id => $borg_id,
				       smell => 'robotic',
				       cash => 20.2,
				     } ); };

    $e = $@;
    isa_ok( $e, 'Alzabo::Exception::NotNullable',
	    "Exception thrown from inserting a non-nullable column as NULL" );

    is( $e->table_name, 'employee',
        "NotNullable exceptions contain table name" );

    is( $e->schema_name, $config->{schema_name},
        "NotNullable exceptions contain schema name" );

    {
	my $new_emp;
	eval_ok( sub { $new_emp = $emp_t->insert( values => { name => 'asfalksf',
							      dep_id => $borg_id,
							      smell => undef,
							      cash => 20.2,
							    } ) },
		 "Inserting a NULL into a non-nullable column that has a default should not produce an exception" );

	eval_ok( sub { $new_emp->delete },
		 "Delete a just-created employee" );
    }

    eval { $emp_t->insert( values => { name => 'YetAnotherTest',
				       dep_id => undef,
				       cash => 1.1,
				     } ) };

    $e = $@;
    isa_ok( $e, 'Alzabo::Exception::Params',
	    "Exception thrown from attempt to insert a NULL into dep_id for an employee" );

    eval { $emp{bill}->update( dep_id => undef ) };
    $e = $@;
    isa_ok( $e, 'Alzabo::Exception::Params',
	    "Exception thrown from attempt to update dep_id to NULL for an employee" );

    {
        my $updated = $emp{bill}->update( cash => undef, smell => 'hello!' );

        ok( $updated, 'update() did change values' );
        ok( ! defined $emp{bill}->select('cash'),
            "Bill has no cash" );
    }

    {
        my $updated = $emp{bill}->update( cash => undef, smell => 'hello!' );

        ok( ! $updated, 'update() did not change values' );
    }

    ok( $emp{bill}->select('smell') eq 'hello!',
	"smell for bill should be 'hello!'" );

    eval { $emp{bill}->update( name => undef ) };
    $e = $@;
    isa_ok( $e, 'Alzabo::Exception::NotNullable',
	    "Exception thrown from attempt to update a non-nullable column to NULL" );

    eval_ok( sub { $dep{borg}->update( manager_id => $emp{bill}->select('employee_id') ) },
	     "Set manager_id column for borg department" );

    eval_ok( sub { $emp{2} = $emp_t->insert( values =>
					     { name => 'unit 2',
					       smell => 'good',
					       dep_id => $dep{lying}->select('department_id') } ) },
	     "Create employee 'unit 2'" );

    my $emp2_id = $emp{2}->select('employee_id');
    delete $emp{2};

    my $cursor;
    my $x = 0;
    eval_ok( sub { $cursor =
                       $emp_t->rows_where
                           ( where => [ $emp_t->column('employee_id'), '=', $emp2_id ] );

		   while ( my $row = $cursor->next )
		   {
		       $x++;
		       $emp{2} = $row;
		   }
                 },
	     "Retrieve 'unit 2' employee via rows_where method and cursor" );

    is( $x, 1,
	"Check count of rows found where employee_id == $emp2_id" );
    is( $cursor->count, 1,
	"Make sure cursor's count() is accurate" );

    is( $emp{2}->select('name'), 'unit 2',
	"Check that row found has name of 'unit 2'" );

    {
	my $row;
	eval_ok( sub { $row =
                           $emp_t->one_row
                               ( where =>
                                 [ $emp_t->column('employee_id'), '=', $emp2_id ] ) },
		 "Retrieve 'unit 2' employee via one_row method" );

	is( $row->select('name'), 'unit 2',
	    "Check that the single row returned has the name 'unit 2'" );
    }

    {
	my $row;
	eval_ok( sub { $row =
                           $emp_t->one_row
                               ( where =>
                                 [ $emp_t->column('employee_id'), '=', $emp2_id ],
                                 quote_identifiers => 1,
                               ) },
		 "Retrieve 'unit 2' employee via one_row method with quote_identifiers" );

	is( $row->select('name'), 'unit 2',
	    "Check that the single row returned has the name 'unit 2'" );
    }

    my %proj;
    $proj{extend} = $proj_t->insert( values => { name => 'Extend',
						 department_id => $dep{borg}->select('department_id') } );
    $proj{embrace} = $proj_t->insert( values => { name => 'Embrace',
						  department_id => $dep{borg}->select('department_id')  } );

    $emp_proj_t->insert( values => { employee_id => $emp{bill}->select('employee_id'),
				     project_id  => $proj{extend}->select('project_id') } );

    $emp_proj_t->insert( values => { employee_id => $emp{bill}->select('employee_id'),
				     project_id  => $proj{embrace}->select('project_id') } );

    my $fk = $emp_t->foreign_keys_by_table($emp_proj_t);
    my @emp_proj;
    my @cursor_counts;
    eval_ok( sub { $cursor = $emp{bill}->rows_by_foreign_key( foreign_key => $fk );
		   while ( my $row = $cursor->next )
		   {
		       push @emp_proj, $row;
                       push @cursor_counts, $cursor->count;
		   } },
	     "Fetch rows via ->rows_by_foreign_key method (expect cursor)" );

    is( scalar @emp_proj, 2,
	"Check that only two rows were returned" );
    is( $emp_proj[0]->select('employee_id'), $emp{bill}->select('employee_id'),
	"Check that employee_id in employee_project is same as bill's" );
    is( $emp_proj[0]->select('project_id'), $proj{extend}->select('project_id'),
	"Check that project_id in employee_project is same as extend project" );

    foreach (1..2)
    {
        is( $cursor_counts[$_ - 1], $_,
            "cursor->count should be 1..2" );
    }

    my $emp_proj = $emp_proj[0];
    $fk = $emp_proj_t->foreign_keys_by_table($emp_t);

    my $emp;
    eval_ok( sub { $emp = $emp_proj->rows_by_foreign_key( foreign_key => $fk ) },
	     "Fetch rows via ->rows_by_foreign_key method (expect row)" );
    is( $emp->select('employee_id'), $emp_proj->select('employee_id'),
	"The returned row should have bill's employee_id" );

    $x = 0;
    my @rows;

    eval_ok( sub { $cursor = $emp_t->all_rows;
		   $x++ while $cursor->next
	         },
	     "Fetch all rows from employee table" );
    is( $x, 2,
	"Only 2 rows should be found" );

    $cursor->reset;
    my $count = $cursor->all_rows;

    is( $x, 2,
	"Only 2 rows should be found after cursor reset" );

    {
        my $cursor;
        eval_ok( sub { $cursor =
                           $s->join( join     => [ $emp_t, $emp_proj_t, $proj_t ],
                                     where    =>
                                     [ $emp_t->column('employee_id'), '=',
                                       $emp{bill}->select('employee_id') ],
                                     order_by => $proj_t->column('project_id'),
                                     quote_identifiers => 1,
                                   ) },
                 "Join employee, employee_project, and project tables where employee_id = bill's employee id with quote_identifiers" );

        my @rows = $cursor->next;

        is( scalar @rows, 3,
            "3 rows per cursor ->next call" );
        is( $rows[0]->table->name, 'employee',
            "First row is from employee table" );
        is( $rows[1]->table->name, 'employee_project',
            "Second row is from employee_project table" );
        is( $rows[2]->table->name, 'project',
            "Third row is from project table" );

        my $first_proj_id = $rows[2]->select('project_id');
        @rows = $cursor->next;
        my $second_proj_id = $rows[2]->select('project_id');

        ok( $first_proj_id < $second_proj_id,
            "Order by clause should cause project rows to come back" .
            " in ascending order of project id" );
    }

    {
        my $cursor;
        eval_ok( sub { $cursor =
                           $s->join( join     => [ $emp_t, $emp_proj_t, $proj_t ],
                                     where    =>
                                     [ [ $proj_t->column('project_id'), '=',
                                         $proj{extend}->select('project_id') ],
                                       'or',
                                       [ $proj_t->column('project_id'), '=',
                                         $proj{embrace}->select('project_id') ],
                                     ],
                                     order_by => $proj_t->column('project_id') ) },
                 "Join employee, employee_project, and project tables with OR in where clause" );

        1 while $cursor->next;

        is( $cursor->count, 2,
            "join with OR in where clause should return two sets of rows" );
    }

    # Alias code
    {
	my $e_alias;
	eval_ok( sub { $e_alias = $emp_t->alias },
		 "Create an alias object for the employee table" );

	my $p_alias;
	eval_ok( sub { $p_alias = $proj_t->alias },
		 "Create an alias object for the project table" );

	eval_ok( sub { $cursor =
                           $s->join( join     => [ $e_alias, $emp_proj_t, $p_alias ],
                                     where    => [ $e_alias->column('employee_id'), '=', 1 ],
                                     order_by => $p_alias->column('project_id'),
                                   ) },
		 "Join employee, employee_project, and project tables where" .
                 " employee_id = 1 using aliases" );

	my @rows = $cursor->next;

	is( scalar @rows, 3,
	    "3 rows per cursor ->next call" );
	is( $rows[0]->table->name, 'employee',
	    "First row is from employee table" );
	is( $rows[1]->table->name, 'employee_project',
	    "Second row is from employee_project table" );
	is( $rows[2]->table->name, 'project',
	    "Third row is from project table" );
    }

    # Alias code & multiple joins to the same table
    {
	my $p_alias = $proj_t->alias;

	eval_ok( sub { $cursor = $s->join( select   => [ $p_alias, $proj_t ],
					   join     => [ $p_alias, $emp_proj_t, $proj_t ],
					   where    => [ [ $p_alias->column('project_id'), '=', 1 ],
							 [ $proj_t->column('project_id'), '=', 1 ] ],
					 ) },
		 "Join employee_project and project table (twice) using aliases" );

	my @rows = $cursor->next;

	is( scalar @rows, 2,
	    "2 rows per cursor ->next call" );
	is( $rows[0]->table->name, 'project',
	    "First row is from project table" );
	is( $rows[1]->table->name, 'project',
	    "Second row is from project table" );
	is( $rows[0]->table, $rows[1]->table,
	    "The two rows should share the same table object (the alias should be gone at this point)" );
    }

    {
	my @rows;
	eval_ok( sub { @rows = $s->one_row( tables   => [ $emp_t, $emp_proj_t, $proj_t ],
					    where    => [ $emp_t->column('employee_id'), '=', 1 ],
					    order_by => $proj_t->column('project_id') ) },
		 "Join employee, employee_project, and project tables where employee_id = 1 using one_row method" );

	is( $rows[0]->table->name, 'employee',
	    "First row is from employee table" );
	is( $rows[1]->table->name, 'employee_project',
	    "Second row is from employee_project table" );
	is( $rows[2]->table->name, 'project',
	    "Third row is from project table" );
    }

    $cursor = $s->join( join     => [ $emp_t, $emp_proj_t, $proj_t ],
			where    => [ $emp_t->column('employee_id'), '=', 1 ],
			order_by => [ $proj_t->column('project_id'), 'desc' ] );
    @rows = $cursor->next;
    my $first_proj_id = $rows[2]->select('project_id');
    @rows = $cursor->next;
    my $second_proj_id = $rows[2]->select('project_id');

    ok( $first_proj_id > $second_proj_id,
	"Order by clause should cause project rows to come back in descending order of project id" );

    $cursor = $s->join( join     => [ $emp_t, $emp_proj_t, $proj_t ],
			where    => [ $emp_t->column('employee_id'), '=', 1 ],
			order_by => [ $proj_t->column('project_id'), 'desc' ] );

    @rows = $cursor->next;
    $first_proj_id = $rows[2]->select('project_id');
    @rows = $cursor->next;
    $second_proj_id = $rows[2]->select('project_id');

    ok( $first_proj_id > $second_proj_id,
	"Order by clause (alternate form) should cause project rows to come back in descending order of project id" );

    eval_ok( sub { $cursor = $s->join( select => [ $emp_t, $emp_proj_t, $proj_t ],
				       join   => [ [ $emp_t, $emp_proj_t ],
						   [ $emp_proj_t, $proj_t ] ],
				       where  => [ $emp_t->column('employee_id'), '=', 1 ] ) },
	     "Join with join as arrayref of arrayrefs" );

    @rows = $cursor->next;

    is( scalar @rows, 3,
	"3 rows per cursor ->next call" );
    is( $rows[0]->table->name, 'employee',
	"First row is from employee table" );
    is( $rows[1]->table->name, 'employee_project',
	"Second row is from employee_project table" );
    is( $rows[2]->table->name, 'project',
	"Third row is from project table" );

    {
	my $cursor;
	eval_ok( sub { $cursor = $s->join( join  => [ [ $emp_t, $emp_proj_t ],
						      [ $emp_proj_t, $proj_t ] ],
					   where => [ $emp_t->column('employee_id'), '=', 1 ] ) },
	     "Same join with no select parameter" );

	my @rows = $cursor->next;

	@rows = sort { $a->table->name cmp $b->table->name } @rows;

	is( scalar @rows, 3,
	    "3 rows per cursor ->next call" );
	is( ( grep { $_->table->name eq 'employee' } @rows ), 1,
	    "First row is from employee table" );
	is( ( grep { $_->table->name eq 'employee_project' } @rows ), 1,
	    "Second row is from employee_project table" );
	is( ( grep { $_->table->name eq 'project' } @rows ), 1,
	    "Third row is from project table" );
    }

    eval { $s->join( select => [ $emp_t, $emp_proj_t, $proj_t ],
		     join   => [ [ $emp_t, $emp_proj_t ],
				 [ $emp_proj_t, $proj_t ],
				 [ $s->tables( 'outer_1', 'outer_2' ) ] ],
		     where =>  [ $emp_t->column('employee_id'), '=', 1 ] ) };

    $e = $@;
    isa_ok( $e, 'Alzabo::Exception::Logic',
	    "Exception thrown from join with table map that does not connect" );

    eval_ok( sub { @rows = $s->join( join  => $emp_t,
				     where => [ $emp_t->column('employee_id'), '=', 1 ] )->all_rows },
	     "Join with a single table" );
    is( @rows, 1,
	"Only one row should be returned" );
    is( $rows[0]->select('employee_id'), 1,
	"Returned employee should be employee number one" );

    {

	$s->table('outer_2')->insert( values => { outer_2_name => 'will match something',
						  outer_2_pk => 1 },
				    );

	$s->table('outer_2')->insert( values => { outer_2_name => 'will match nothing',
						  outer_2_pk => 99 },
                                    );


	$s->table('outer_1')->insert( values => { outer_1_name => 'test1 (has matching join row)',
						  outer_2_pk => 1 },
                                    );

	$s->table('outer_1')->insert( values => { outer_1_name => 'test2 (has no matching join row)',
						  outer_2_pk => undef },
                                    );

        {
            my $cursor;
            eval_ok( sub { $cursor =
                               $s->join
                                   ( select => [ $s->tables( 'outer_1', 'outer_2' ) ],
                                     join =>
                                     [ left_outer_join =>
                                       $s->tables( 'outer_1', 'outer_2' ) ]
                                   ) },
		 "Do a left outer join" );

            my @sets = $cursor->all_rows;

            is( scalar @sets, 2,
                "Left outer join should return 2 sets of rows" );

            # re-order so that the set with 2 valid rows is always first
            unless ( defined $sets[0]->[1] )
            {
                my $set = shift @sets;
                push @sets, $set;
            }

            is( $sets[0]->[0]->select('outer_1_name'), 'test1 (has matching join row)',
                "The first row in the first set should have the name 'test1 (has matching join row)'" );

            is( $sets[0]->[1]->select('outer_2_name'), 'will match something',
                "The second row in the first set should have the name 'will match something'" );

            is( $sets[1]->[0]->select('outer_1_name'), 'test2 (has no matching join row)',
                "The first row in the second set should have the name 'test12 (has no matching join row)'" );

            ok( ! defined $sets[1]->[1],
                "The second row in the second set should not be defined" );
        }

        {
            my $cursor;
            eval_ok( sub { $cursor =
                               $s->join
                                   ( select => [ $s->tables( 'outer_1', 'outer_2' ) ],
                                     join =>
                                     [ [ left_outer_join =>
                                         $s->tables( 'outer_1', 'outer_2' ),
                                         [ $s->table('outer_2')->column( 'outer_2_pk' ),
                                           '!=', 1 ],
                                       ] ],
                                     order_by =>
                                     $s->table('outer_1')->column('outer_1_name')
                                   ) },
		 "Do a left outer join" );

            my @sets = $cursor->all_rows;

            is( scalar @sets, 2,
                "Left outer join should return 2 sets of rows" );

            is( $sets[0]->[0]->select('outer_1_name'), 'test1 (has matching join row)',
                "The first row in the first set should have the name 'test1 (has matching join row)'" );

            is( $sets[0]->[1], undef,
                "The second row in the first set should be undef" );

            is( $sets[1]->[0]->select('outer_1_name'), 'test2 (has no matching join row)',
                "The first row in the second set should have the name 'test1 (has matching join row)'" );

            is( $sets[1]->[1], undef,
                "The second row in the second set should be undef" );
        }

        {
            my $fk = $s->table('outer_1')->foreign_keys_by_table( $s->table('outer_2') );
            my $cursor;
            eval_ok( sub { $cursor =
                               $s->join
                                   ( select => [ $s->tables( 'outer_1', 'outer_2' ) ],
                                     join =>
                                     [ [ left_outer_join =>
                                         $s->tables( 'outer_1', 'outer_2' ),
                                         $fk,
                                         [ $s->table('outer_2')->column( 'outer_2_pk' ),
                                           '!=', 1 ],
                                       ] ],
                                     order_by =>
                                     $s->table('outer_1')->column('outer_1_name')
                                   ) },
		 "Do a left outer join" );

            my @sets = $cursor->all_rows;

            is( scalar @sets, 2,
                "Left outer join should return 2 sets of rows" );

            is( $sets[0]->[0]->select('outer_1_name'), 'test1 (has matching join row)',
                "The first row in the first set should have the name 'test1 (has matching join row)'" );

            is( $sets[0]->[1], undef,
                "The second row in the first set should be undef" );

            is( $sets[1]->[0]->select('outer_1_name'), 'test2 (has no matching join row)',
                "The first row in the second set should have the name 'test1 (has matching join row)'" );

            is( $sets[1]->[1], undef,
                "The second row in the second set should be undef" );
        }

        {
            my $cursor;
            eval_ok( sub { $cursor =
                               $s->join
                                   ( select => [ $s->tables( 'outer_1', 'outer_2' ) ],
                                     join =>
                                     [ [ right_outer_join =>
                                         $s->tables( 'outer_1', 'outer_2' ) ] ]
                                   ) },
                     "Attempt a right outer join" );

            my @sets = $cursor->all_rows;

            is( scalar @sets, 2,
                "Right outer join should return 2 sets of rows" );

            # re-order so that the set with 2 valid rows is always first
            unless ( defined $sets[0]->[0] )
            {
                my $set = shift @sets;
                push @sets, $set;
            }

            is( $sets[0]->[0]->select('outer_1_name'), 'test1 (has matching join row)',
                "The first row in the first set should have the name 'test1 (has matching join row)'" );

            is( $sets[0]->[1]->select('outer_2_name'), 'will match something',
                "The second row in the first set should have the name 'will match something'" );

            ok( ! defined $sets[1]->[0],
                "The first row in the second set should not be defined" );

            is( $sets[1]->[1]->select('outer_2_name'), 'will match nothing',
                "The second row in the second set should have the name 'test12 (has no matching join row)'" );
        }


        {
            my $cursor;
            # do the same join, but with specified foreign key
            my $fk = $s->table('outer_1')->foreign_keys_by_table( $s->table('outer_2') );
            eval_ok( sub { $cursor =
                               $s->join
                                   ( select => [ $s->tables( 'outer_1', 'outer_2' ) ],
                                     join =>
                                     [ [ right_outer_join =>
                                         $s->tables( 'outer_1', 'outer_2' ), $fk ] ]
                                   ) },
                     "Attempt a right outer join, with explicit foreign key" );

            my @sets = $cursor->all_rows;

            is( scalar @sets, 2,
                "Right outer join should return 2 sets of rows" );

            # re-order so that the set with 2 valid rows is always first
            unless ( defined $sets[0]->[0] )
            {
                my $set = shift @sets;
                push @sets, $set;
            }

            is( $sets[0]->[0]->select('outer_1_name'), 'test1 (has matching join row)',
                "The first row in the first set should have the name 'test1 (has matching join row)'" );

            is( $sets[0]->[1]->select('outer_2_name'), 'will match something',
                "The second row in the first set should have the name 'will match something'" );

            ok( ! defined $sets[1]->[0],
                "The first row in the second set should not be defined" );

            is( $sets[1]->[1]->select('outer_2_name'), 'will match nothing',
                "The second row in the second set should have the name 'test12 (has no matching join row)'" );
        }
    }

    my $id = $emp{bill}->select('employee_id');

    $emp{bill}->delete;

    eval { $emp{bill}->select('name'); };
    $e = $@;

    isa_ok( $e, 'Alzabo::Exception::NoSuchRow',
            "Exception thrown from attempt to select from deleted row object" );

    {
        my $row =
            $emp_proj_t->row_by_pk
                ( pk =>
                  { employee_id => $id,
                    project_id => $proj{extend}->select('project_id') } );

        is( $row, undef,
            "make sure row was deleted by cascading delte" );
    }

    is( $dep{borg}->select('manager_id'), 1,
	"The manager_id for the borg department will be 1 because the object does not the database was changed" );
    $dep{borg}->refresh;

    my $dep_id = $dep{borg}->select('department_id');

    $emp_t->insert( values => { name => 'bob', smell => 'awful', dep_id => $dep_id } );
    $emp_t->insert( values => { name => 'rachel', smell => 'horrid', dep_id => $dep_id } );
    $emp_t->insert( values => { name => 'al', smell => 'bad', dep_id => $dep_id } );

    {
	my @emps;
	eval_ok ( sub { @emps = $emp_t->all_rows( order_by =>
						  [ $emp_t->column('name') ] )->all_rows },
		  "Select all employee rows with arrayref to order_by" );

	is( scalar @emps, 4,
	    "There should be 4 rows in the employee table" );
	is( $emps[0]->select('name'), 'al',
	    "First row name should be al" );
	is( $emps[1]->select('name'), 'bob',
	    "Second row name should be bob" );
	is( $emps[2]->select('name'), 'rachel',
	    "Third row name should be rachel" );
	is( $emps[3]->select('name'), 'unit 2',
	    "Fourth row name should be 'unit 2'" );
    }

    {
	my @emps;
	eval_ok ( sub { @emps = $emp_t->all_rows( order_by =>
						  [ $emp_t->column('name') ],
                                                  quote_identifiers => 1,
                                                )->all_rows },
		  "Select all employee rows with arrayref to order_by with quote_identifiers" );

	is( scalar @emps, 4,
	    "There should be 4 rows in the employee table" );
	is( $emps[0]->select('name'), 'al',
	    "First row name should be al" );
	is( $emps[1]->select('name'), 'bob',
	    "Second row name should be bob" );
	is( $emps[2]->select('name'), 'rachel',
	    "Third row name should be rachel" );
	is( $emps[3]->select('name'), 'unit 2',
	    "Fourth row name should be 'unit 2'" );
    }

    {
	my @emps;
	eval_ok( sub { @emps = $emp_t->all_rows( order_by => $emp_t->column('name') )->all_rows },
		 "Select all employee rows with column obj to order_by" );

	is( scalar @emps, 4,
	    "There should be 4 rows in the employee table" );
	is( $emps[0]->select('name'), 'al',
	    "First row name should be al" );
	is( $emps[1]->select('name'), 'bob',
	    "Second row name should be bob" );
	is( $emps[2]->select('name'), 'rachel',
	    "Third row name should be rachel" );
	is( $emps[3]->select('name'), 'unit 2',
	    "Fourth row name should be 'unit 2'" );
    }

    {
	my @emps;
	eval_ok( sub { @emps = $emp_t->all_rows( order_by => [ $emp_t->column('name') ] )->all_rows },
		 "Select all employee rows with arrayref to order_by" );

	is( scalar @emps, 4,
	    "There should be 4 rows in the employee table" );
	is( $emps[0]->select('name'), 'al',
	    "First row name should be al" );
	is( $emps[1]->select('name'), 'bob',
	    "Second row name should be bob" );
	is( $emps[2]->select('name'), 'rachel',
	    "Third row name should be rachel" );
	is( $emps[3]->select('name'), 'unit 2',
	    "Fourth row name should be 'unit 2'" );
    }

    {
	my @emps;
	eval_ok( sub { @emps = $emp_t->all_rows( order_by =>
						 [ $emp_t->column('smell') ] )->all_rows },
		 "Select all employee rows with arrayref to order_by (by smell)" );

	is( scalar @emps, 4,
	    "There should be 4 rows in the employee table" );
	is( $emps[0]->select('name'), 'bob',
	    "First row name should be bob" );
	is( $emps[1]->select('name'), 'al',
	    "Second row name should be al" );
	is( $emps[2]->select('name'), 'unit 2',
	    "Third row name should be 'unit 2'" );
	is( $emps[3]->select('name'), 'rachel',
	    "Fourth row name should be rachel" );
    }

    {
	my @emps;
	eval_ok( sub { @emps = $emp_t->all_rows( order_by =>
                                                 [ $emp_t->column('smell'), 'desc' ] )->all_rows },
		 "Select all employee rows order by smell (descending)" );

	is( $emps[0]->select('name'), 'rachel',
	    "First row name should be rachel" );
	is( $emps[1]->select('name'), 'unit 2',
	    "Second row name should be 'unit 2'" );
	is( $emps[2]->select('name'), 'al',
	    "Third row name should be al" );
	is( $emps[3]->select('name'), 'bob',
	    "Fourth row name should be bob" );
    }

    eval_ok( sub { $count = $emp_t->row_count },
	     "Call row_count for employee table" );

    is( $count, 4,
	"The count should be 4" );

    eval_ok( sub { $count = $emp_t->function( select => COUNT( $emp_t->column('employee_id') ) ) },
	     "Get row count via ->function method" );

    is( $count, 4,
	"There should still be just 4 rows" );

    {
	my $one;
	eval_ok( sub { $one = $emp_t->function( select => 1 ) },
		 "Get '1' via ->function method" );

	is( $one, 1,
	    "Getting '1' via ->function should return 1" );
    }

    {
	my $statement;
	eval_ok( sub { $statement = $emp_t->select( select => COUNT( $emp_t->column('employee_id') ) ) },
		 "Get row count via even spiffier new ->select method" );

	isa_ok( $statement, 'Alzabo::DriverStatement',
		"Return value from Table->select method" );

	$count = $statement->next;
	is( $count, 4,
	    "There should still be just 4 rows" );
    }

    {
	my $st;
	eval_ok( sub { $st = $emp_t->select( select => 1 ) },
		 "Get '1' via ->select method" );

	is( $st->next, 1,
	    "Getting '1' via ->select should return 1" );
    }

    {
	my @emps;
	eval_ok( sub { @emps = $emp_t->all_rows( order_by =>
                                                 [ $emp_t->column('smell'), 'desc' ],
						 limit => 2 )->all_rows },
		 "Get all employee rows with ORDER BY and LIMIT" );

	is( scalar @emps, 2,
	    "This should only return 2 rows" );

	is( $emps[0]->select('name'), 'rachel',
	    "First row should be rachel" );
	is( $emps[1]->select('name'), 'unit 2',
	    "Second row is 'unit 2'" );
    }

    {
	my @emps;
	eval_ok( sub { @emps = $emp_t->all_rows( order_by =>
                                                 [ $emp_t->column('smell'), 'desc' ],
						 limit => [2, 2] )->all_rows },
		 "Get all employee rows with ORDER BY and LIMIT (with offset)" );

	is( scalar @emps, 2,
	    "This should only return 2 rows" );

	is( $emps[0]->select('name'), 'al',
	    "First row should be al" );
	is( $emps[1]->select('name'), 'bob',
	    "Second row is bob" );
    }

    $emp_t->set_prefetch( $emp_t->columns( qw( name smell ) ) );
    my @p = $emp_t->prefetch;

    is( scalar @p, 2,
        "Prefetch method should return 2 column names" );
    is( scalar ( grep { $_ eq 'name' } @p ), 1,
        "One column should be 'name'" );
    is( scalar ( grep { $_ eq 'smell' } @p ), 1,
        "And the other should be 'smell'" );

    is( $emp_t->row_count, 4,
	"employee table should have 4 rows" );

    {
	my @emps = $emp_t->all_rows( order_by =>
                                     [ $emp_t->column('smell'), 'desc' ],
				     limit => [2, 2] )->all_rows;

	my $smell = $emps[0]->select('smell');
	is( $emp_t->row_count( where => [ $emp_t->column('smell'), '=', $smell ] ), 1,
	    "Call row_count method with where parameter." );

	$emps[0]->delete;
	eval { $emps[0]->update( smell => 'kaboom' ); };
	$e = $@;
	isa_ok( $e, 'Alzabo::Exception::NoSuchRow',
		"Exception thrown from attempt to update a deleted row" );

	my $row_id = $emps[1]->id_as_string;
	my $row;
	eval_ok( sub { $row = $emp_t->row_by_id( row_id => $row_id ) },
		 "Fetch a row via the ->row_by_id method" );
	is( $row->id_as_string, $emps[1]->id_as_string,
	    "Row retrieved via the ->row_by_id method should be the same as the row whose id was used" );
    }

    $emp_t->insert( values => { employee_id => 9000,
				name => 'bob9000',
				smell => 'a',
				dep_id => $dep_id } );
    $emp_t->insert( values => { employee_id => 9001,
				name => 'bob9001',
				smell => 'b',
				dep_id => $dep_id } );
    $emp_t->insert( values => { employee_id => 9002,
				name => 'bob9002',
				smell => 'c',
				dep_id => $dep_id } );

    my $eid_c = $emp_t->column('employee_id');

    {
	my @emps = $emp_t->rows_where( where => [ [ $eid_c, '=', 9000 ],
						  'or',
						  [ $eid_c, '=', 9002 ] ] )->all_rows;

	@emps = sort { $a->select('employee_id') <=> $b->select('employee_id') } @emps;

	is( @emps, 2,
	    "Do a query with 'or' and count the rows" );
	is( $emps[0]->select('employee_id'), 9000,
	    "First row returned should be employee id 9000" );

	is( $emps[1]->select('employee_id'), 9002,
	    "Second row returned should be employee id 9002" );
    }

    {
	my @emps = $emp_t->rows_where( where => [ [ $emp_t->column('smell'), '!=', 'c' ],
						  'and',
						  (
						   '(',
						   [ $eid_c, '=', 9000 ],
						   'or',
						   [ $eid_c, '=', 9002 ],
						   ')',
						  ),
						] )->all_rows;
	is( @emps, 1,
	    "Do another complex query with 'or' and subgroups" );
	is( $emps[0]->select('employee_id'), 9000,
	    "The row returned should be employee id 9000" );
    }

    {
	my @emps = $emp_t->rows_where( where => [ (
						   '(',
						   [ $eid_c, '=', 9000 ],
						   'and',
						   [ $eid_c, '=', 9000 ],
						   ')',
						  ),
						  'or',
						  (
						   '(',
						   [ $eid_c, '=', 9000 ],
						   'and',
						   [ $eid_c, '=', 9000 ],
						   ')',
						  ),
						] )->all_rows;

	is( @emps, 1,
	    "Do another complex query with 'or', 'and' and subgroups" );
	is( $emps[0]->select('employee_id'), 9000,
	    "The row returned should be employee id 9000" );
    }

    {
	my @emps = $emp_t->rows_where( where => [ $eid_c, 'between', 9000, 9002 ] )->all_rows;
	@emps = sort { $a->select('employee_id') <=> $b->select('employee_id') } @emps;

	is( @emps, 3,
	    "Select using between should return 3 rows" );
	is( $emps[0]->select('employee_id'), 9000,
	    "First row returned should be employee id 9000" );
	is( $emps[1]->select('employee_id'), 9001,
	    "Second row returned should be employee id 9001" );
	is( $emps[2]->select('employee_id'), 9002,
	    "Third row returned should be employee id 9002" );
    }

    {
	my @emps;
	eval_ok( sub { @emps = $emp_t->rows_where( where => [ '(', '(',
							      [ $eid_c, '=', 9000 ],
							      ')', ')'
							    ] )->all_rows },
		 "Nested subgroups should be allowed" );

	is( @emps, 1,
	    "Query with nested subgroups should return 1 row" );
	is( $emps[0]->select('employee_id'), 9000,
	    "The row returned should be employee id 9000" );
    }

    $emp_t->insert( values => { name => 'Smelly',
				smell => 'a',
				dep_id => $dep_id,
			      } );

    {
	my @emps = eval { $emp_t->rows_where( where => [ LENGTH( $emp_t->column('smell') ), '=', 1 ] )->all_rows };

	is( @emps, 4,
	    "There should be only 4 employees where the length of the smell column is 1" );
    }

    {
	my @emps;
	eval_ok( sub { @emps = $emp_t->rows_where( where => [ LENGTH( $emp_t->column('smell') ), '=', 1 ],
						   limit => 2 )->all_rows },
		 "Select all employee rows with WHERE and LIMIT" );

	is( scalar @emps, 2,
	    "Limit should cause only two employee rows to be returned" );
    }

    {
	my @emps;
	eval_ok( sub { @emps = $emp_t->rows_where( where => [ LENGTH( $emp_t->column('smell') ), '=', 1 ],
						   order_by => $emp_t->column('smell'),
						   limit => 2 )->all_rows },
		 "Select all employee rows with WHERE, ORDER BY, and LIMIT" );

	is( scalar @emps, 2,
	    "Limit should cause only two employee rows to be returned (again)" );
    }

    {
	my @emps;
	eval_ok( sub { @emps = $emp_t->rows_where( where => [ '(',
							      [ $emp_t->column('employee_id'), '=', 9000 ],
							      ')',
							    ],
						   order_by => $emp_t->column('employee_id') )->all_rows },
		 "Query with subgroup followed by order by" );

	is( @emps, 1,
	    "Query with subgroup followed by order by should return 1 row" );
	is( $emps[0]->select('employee_id'), 9000,
	    "The row returned should be employee id 9000" );
    }

    my @smells = $emp_t->function( select => [ $emp_t->column('smell'), COUNT( $emp_t->column('smell') ) ],
				   group_by => $emp_t->column('smell') );
    # map smell to count
    my %smells = map { $_->[0] => $_->[1] } @smells;
    is( @smells, 6,
	"Query with group by should return 6 values" );
    is( $smells{a}, 2,
	"Check count of smell = 'a'" );
    is( $smells{b}, 1,
	"Check count of smell = 'b'" );
    is( $smells{c}, 1,
	"Check count of smell = 'c'" );
    is( $smells{awful}, 1,
	"Check count of smell = 'awful'" );
    is( $smells{good}, 1,
	"Check count of smell = 'good'" );
    is( $smells{horrid}, 1,
	"Check count of smell = 'horrid'" );

    {
	my $statement = $emp_t->select( select => [ $emp_t->column('smell'), COUNT( $emp_t->column('smell') ) ],
					group_by => $emp_t->column('smell') );

	my @smells = $statement->all_rows;

	# map smell to count
	%smells = map { $_->[0] => $_->[1] } @smells;
	is( @smells, 6,
	    "Query with group by should return 6 values - via ->select" );
	is( $smells{a}, 2,
	    "Check count of smell = 'a' - via ->select" );
	is( $smells{b}, 1,
	    "Check count of smell = 'b' - via ->select" );
	is( $smells{c}, 1,
	    "Check count of smell = 'c' - via ->select" );
	is( $smells{awful}, 1,
	    "Check count of smell = 'awful' - via ->select" );
	is( $smells{good}, 1,
	    "Check count of smell = 'good' - via ->select" );
	is( $smells{horrid}, 1,
	    "Check count of smell = 'horrid' - via ->select" );
    }

    @rows = $emp_t->function( select => $emp_t->column('smell'),
			      where => [ LENGTH( $emp_t->column('smell') ), '=', 1 ],
			      order_by => $emp_t->column('smell') );
    is( @rows, 4,
	"There should only be four rows which have a single character smell" );
    is( $rows[0], 'a',
	"First smell should be 'a'" );
    is( $rows[1], 'a',
	"Second smell should be 'a'" );
    is( $rows[2], 'b',
	"Third smell should be 'b'" );
    is( $rows[3], 'c',
	"Fourth smell should be 'c'" );

    {
	my $statement = $emp_t->select( select => $emp_t->column('smell'),
					where => [ LENGTH( $emp_t->column('smell') ), '=', 1 ],
					order_by => $emp_t->column('smell') );
	my @rows = $statement->all_rows;

	is( @rows, 4,
	    "There should only be four rows which have a single character smell - via ->select" );
	is( $rows[0], 'a',
	    "First smell should be 'a' - via ->select" );
	is( $rows[1], 'a',
	    "Second smell should be 'a' - via ->select" );
	is( $rows[2], 'b',
	    "Third smell should be 'b' - via ->select" );
	is( $rows[3], 'c',
	    "Fourth smell should be 'c' - via ->select" );
    }

    @rows = $emp_t->function( select => $emp_t->column('smell'),
			      where => [ LENGTH( $emp_t->column('smell') ), '=', 1 ],
			      order_by => $emp_t->column('smell'),
			      limit => 2,
			    );
    is( @rows, 2,
	"There should only be two rows which have a single character smell - with limit" );
    is( $rows[0], 'a',
	"First smell should be 'a' - with limit" );
    is( $rows[1], 'a',
	"Second smell should be 'a' - with limit" );

    {
	my $statement = $emp_t->select( select => $emp_t->column('smell'),
					where => [ LENGTH( $emp_t->column('smell') ), '=', 1 ],
					order_by => $emp_t->column('smell'),
					limit => 2,
				      );
	my @rows = $statement->all_rows;

	is( @rows, 2,
	    "There should only be two rows which have a single character smell -  with limit via ->select" );
	is( $rows[0], 'a',
	    "First smell should be 'a' - with limit via ->select" );
	is( $rows[1], 'a',
	    "Second smell should be 'a' - with limit via ->select" );
    }

    my $extend_id = $proj{extend}->select('project_id');
    my $embrace_id = $proj{embrace}->select('project_id');
    foreach ( [ 9000, $extend_id ], [ 9000, $embrace_id ],
              [ 9001, $extend_id ], [ 9002, $extend_id ] )
    {
	$emp_proj_t->insert( values => { employee_id => $_->[0],
					 project_id => $_->[1] } );
    }

    # find staffed projects
    @rows = $s->function( select => [ $proj_t->column('name'),
				      COUNT( $proj_t->column('name') ) ],
			  join   => [ $emp_proj_t, $proj_t ],
			  group_by => $proj_t->column('name') );
    is( @rows, 2,
	"Only two projects should be returned from schema->function" );
    is( $rows[0][0], 'Embrace',
	"First project should be Embrace" );
    is( $rows[1][0], 'Extend',
	"Second project should be Extend" );
    is( $rows[0][1], 1,
	"First project should have 1 employee" );
    is( $rows[1][1], 3,
	"Second project should have 3 employees" );

    {
	my $statement = $s->select( select => [ $proj_t->column('name'),
						COUNT( $proj_t->column('name') ) ],
				    join   => [ $emp_proj_t, $proj_t ],
				    group_by => $proj_t->column('name') );
	my @rows = $statement->all_rows;

	is( @rows, 2,
	    "Only two projects should be returned from schema->select" );
	is( $rows[0][0], 'Embrace',
	    "First project should be Embrace - via ->select" );
	is( $rows[1][0], 'Extend',
	    "Second project should be Extend - via ->select" );
	is( $rows[0][1], 1,
	    "First project should have 1 employee - via ->select" );
	is( $rows[1][1], 3,
	    "Second project should have 3 employees - via ->select" );
    }

    @rows = $s->function( select => [ $proj_t->column('name'),
				      COUNT( $proj_t->column('name') ) ],
			  join   => [ $emp_proj_t, $proj_t ],
			  group_by => $proj_t->column('name'),
			  limit => [1, 1],
			);
    is( @rows, 1,
	"Only one projects should be returned from schema->function - with limit" );
    is( $rows[0][0], 'Extend',
	"First project should be Extend - with limit" );
    is( $rows[0][1], 3,
	"First project should have 3 employees - with limit" );

    {
	my $statement = $s->select( select => [ $proj_t->column('name'),
						COUNT( $proj_t->column('name') ) ],
				    join   => [ $emp_proj_t, $proj_t ],
				    group_by => $proj_t->column('name'),
				    limit => [1, 1],
				  );

	my @rows = $statement->all_rows;

	is( @rows, 1,
	    "Only one projects should be returned from schema->select - with limit via ->select" );
	is( $rows[0][0], 'Extend',
	    "First project should be Extend - with limit via ->select" );
	is( $rows[0][1], 3,
	    "First project should have 3 employees - with limit via ->select" );
    }

    {
	my @rows = $s->function( select => [ $proj_t->column('name'),
					     COUNT( $proj_t->column('name') ) ],
				 join   => [ $emp_proj_t, $proj_t ],
				 group_by => $proj_t->column('name'),
				 order_by => [ COUNT( $proj_t->column('name') ), 'DESC' ] );

	is( @rows, 2,
	    "Only two projects should be returned from schema->function ordered by COUNT(*)" );
	is( $rows[0][0], 'Extend',
	    "First project should be Extend" );
	is( $rows[1][0], 'Embrace',
	    "Second project should be Embrace" );
	is( $rows[0][1], 3,
	    "First project should have 3 employee" );
	is( $rows[1][1], 1,
	    "Second project should have 1 employees" );
    }

    {
	my @rows = $s->function( select => [ $proj_t->column('name'),
					     COUNT( $proj_t->column('name') ) ],
				 join   => [ $emp_proj_t, $proj_t ],
				 group_by => $proj_t->column('name'),
				 order_by => [ COUNT( $proj_t->column('name') ), 'DESC' ],
                                 having => [ COUNT( $proj_t->column('name') ), '>', 2 ],
                               );

	is( @rows, 1,
	    "Only one project should be returned from schema->function ordered by COUNT(*) HAVING COUNT(*) > 2" );
	is( $rows[0][0], 'Extend',
	    "First project should be Extend" );
	is( $rows[0][1], 3,
	    "First project should have 3 employee" );
    }

    {
	my @rows;
	eval_ok( sub { @rows = $s->function( select => 1,
					     join   => [ $emp_proj_t, $proj_t ],
					   ) },
		 "Call schema->function with scalar select" );

	is( @rows, 4,
	    "Should return four rows" );
    }

    {
	my $st;
	eval_ok( sub { $st = $s->select( select => 1,
					 join   => [ $emp_proj_t, $proj_t ],
				       ) },
		 "Call schema->select with scalar select" );

	my @rows = $st->all_rows;
	is( @rows, 4,
	    "Should return four rows" );
    }

    my $p1 = $proj_t->insert( values => { name => 'P1',
					  department_id => $dep_id,
					} );
    my $p2 = $proj_t->insert( values => { name => 'P2',
					  department_id => $dep_id,
					} );
    eval_ok( sub { $cursor = $s->join( distinct => $dep_t,
				       join     => [ $dep_t, $proj_t ],
				       where    => [ $proj_t->column('project_id'), 'in',
						     map { $_->select('project_id') } $p1, $p2 ],
				     ) },
	     "Do a join with distinct parameter set" );

    @rows = $cursor->all_rows;

    is( scalar @rows, 1,
	"Setting distinct should cause only a single row to be returned" );

    is( $rows[0]->select('department_id'), $dep_id,
	"Returned row's department_id should be $dep_id" );

    {
	eval_ok( sub { $cursor =
			   $s->join( distinct => $emp_proj_t,
				     join     => [ $emp_t, $emp_proj_t ],
				     where    => [ $emp_t->column('employee_id'), 'in', 9001 ],
				   ) },
	     "Do a join with distinct parameter set to a table with a multi-col PK" );

	@rows = $cursor->all_rows;

	is( scalar @rows, 1,
	    "Setting distinct should cause only a single row to be returned" );

	is( $rows[0]->select('employee_id'), 9001,
	    "Returned row's employee_id should be 9001" );
    }

    {
	eval_ok( sub { $cursor =
			   $s->join
                               ( distinct => [ $emp_t, $emp_proj_t ],
                                 join     => [ $emp_t, $emp_proj_t ],
                                 where    =>
                                 [ $emp_t->column('employee_id'), 'in', 9000, 9001 ],
                               ) },
	     "Do a join with distinct parameter set to a table with a multi-col PK" );

	@rows = $cursor->all_rows;

	is( scalar @rows, 3,
	    "Setting distinct should cause only three rows to be returned" );

	ok( ( grep { $_->[0]->select('employee_id') == 9000 } @rows ),
	    "Returned rows should include employee_id 9000" );

	ok( ( grep { $_->[0]->select('employee_id') == 9001 } @rows ),
	    "Returned rows should include employee_id 9001" );
    }

    {
        $proj_t->insert( values => { name => 'P99',
                                     department_id => $dep{lying}->select('department_id'),
                                   } );

        eval_ok( sub { $cursor = $s->join( distinct => $dep_t,
                                           join     => [ $dep_t, $proj_t ],
                                           order_by => $proj_t->column('name'),
                                         ) },
                 "Do a join with distinct and order_by not in select" );

        @rows = $cursor->all_rows;

        if ( $rdbms eq 'pg' )
        {
            is( scalar @rows, 5, "distinct should cause only five rows to be returned" );
        }
        else
        {
            is( scalar @rows, 2, "distinct should cause only two rows to be returned" );
        }

        is( $rows[0]->select('department_id'), $dep{borg}->select('department_id'),
            'first row is borg department' );

        is( $rows[-1]->select('department_id'), $dep{lying}->select('department_id'),
            'last row is lying department' );

        # Prevents a warning later about destroying a DBI handle with
        # active statement handles.
        undef $cursor;
    }

    # insert rows used to test order by with multiple columns
    my $start_id = 999_990;
    foreach ( [ qw( OB1 bad ) ],
	      [ qw( OB1 worse ) ],
	      [ qw( OB2 bad ) ],
	      [ qw( OB2 worse ) ],
	      [ qw( OB3 awful ) ],
	      [ qw( OB3 bad ) ],
	    )
    {
	$emp_t->insert( values => { employee_id => $start_id++,
				    name => $_->[0],
				    smell => $_->[1],
				    dep_id => $dep_id } );
    }

    @rows = $emp_t->rows_where( where => [ $emp_t->column('employee_id'), 'BETWEEN',
					   999_990, 999_996 ],
				order_by => [ $emp_t->columns( 'name', 'smell' ) ] )->all_rows;
    is( $rows[0]->select('name'), 'OB1',
	"First row name should be OB1" );
    is( $rows[0]->select('smell'), 'bad',
	"First row smell should be bad" );
    is( $rows[1]->select('name'), 'OB1',
	"Second row name should be OB1" );
    is( $rows[1]->select('smell'), 'worse',
	"Second row smell should be bad" );
    is( $rows[2]->select('name'), 'OB2',
	"Third row name should be OB2" );
    is( $rows[2]->select('smell'), 'bad',
	"Third row smell should be bad" );
    is( $rows[3]->select('name'), 'OB2',
	"Fourth row name should be OB2" );
    is( $rows[3]->select('smell'), 'worse',
	"Fourth row smell should be worse" );
    is( $rows[4]->select('name'), 'OB3',
	"Fifth row name should be OB3" );
    is( $rows[4]->select('smell'), 'awful',
	"Fifth row smell should be awful" );
    is( $rows[5]->select('name'), 'OB3',
	"Sixth row name should be OB3" );
    is( $rows[5]->select('smell'), 'bad',
	"Sixth row smell should be bad" );

    @rows = $emp_t->rows_where( where => [ $emp_t->column('employee_id'), 'BETWEEN',
					   999_990, 999_996 ],
				order_by => [ $emp_t->column('name'), 'desc', $emp_t->column('smell'), 'asc' ] )->all_rows;
    is( $rows[0]->select('name'), 'OB3',
	"First row name should be OB3" );
    is( $rows[0]->select('smell'), 'awful',
	"First row smell should be awful" );
    is( $rows[1]->select('name'), 'OB3',
	"Second row name should be OB3" );
    is( $rows[1]->select('smell'), 'bad',
	"Second row smell should be bad" );
    is( $rows[2]->select('name'), 'OB2',
	"Third row name should be OB2" );
    is( $rows[2]->select('smell'), 'bad',
	"Third row smell should be bad" );
    is( $rows[3]->select('name'), 'OB2',
	"Fourth row name should be OB2" );
    is( $rows[3]->select('smell'), 'worse',
	"Fourth row smell should be worse" );
    is( $rows[4]->select('name'), 'OB1',
	"Fifth row name should be OB1" );
    is( $rows[4]->select('smell'), 'bad',
	"Fifth row smell should be bad" );
    is( $rows[5]->select('name'), 'OB1',
	"Sixth row name should be OB1" );
    is( $rows[5]->select('smell'), 'worse',
	"Sixth row smell should be worse" );

    if ( $rdbms eq 'mysql' )
    {
	my $emp;
	eval_ok( sub { $emp = $emp_t->insert( values => { name => UNIX_TIMESTAMP(),
							  dep_id => $dep_id } ) },
		 "Insert using SQL function UNIX_TIMESTAMP()" );

	like( $emp->select('name'), qr/\d+/,
	      "Name should be all digits (unix timestamp)" );

	eval_ok( sub { $emp->update( name => LOWER('FOO') ) },
		 "Do update using SQL function LOWER()" );

	is( $emp->select('name'), 'foo',
	    "Name should be 'foo'" );

	eval_ok( sub { $emp->update( name => REPEAT('Foo', 3) ) },
		 "Do update using SQL function REPEAT()" );

	is( $emp->select('name'), 'FooFooFoo',
	    "Name should be 'FooFooFoo'" );

	eval_ok( sub { $emp->update( name => UPPER( REPEAT('Foo', 3) ) ) },
		 "Do update using nested SQL functions UPPER(REPEAT())" );

	is( $emp->select('name'), 'FOOFOOFOO',
	    "Name should be 'FOOFOOFOO'" );

	$emp_t->insert( values => { name => 'Timestamp',
				    dep_id => $dep_id,
				    tstamp => time - 100_000 } );

	my $cursor;
	eval_ok( sub { $cursor =
			   $emp_t->rows_where( where =>
					       [ [ $emp_t->column('tstamp'), '!=', undef ],
						 [ $emp_t->column('tstamp'), '<', UNIX_TIMESTAMP() ] ] ) },
		 "Do select with where condition that uses SQL function UNIX_TIMESTAMP()" );

	my @rows = $cursor->all_rows;
	is( scalar @rows, 1,
	    "Only one row should have a timestamp value that is not null and that is less than the current time" );
	is( $rows[0]->select('name'), 'Timestamp',
	    "That row should be named Timestamp" );

	# Fulltext support tests
	my $snuffle_id = $emp_t->insert( values => { name => 'snuffleupagus',
						     smell => 'invisible',
						     dep_id => $dep_id } )->select('employee_id');

	@rows = $emp_t->rows_where( where => [ MATCH( $emp_t->column('name') ), AGAINST('abathraspus') ] )->all_rows;
	is( @rows, 0,
	    "Make sure that fulltext search doesn't give a false positive" );

	@rows = $emp_t->rows_where( where => [ MATCH( $emp_t->column('name') ), AGAINST('snuffleupagus') ] )->all_rows;
	is( @rows, 1,
	    "Make sure that fulltext search for snuffleupagus returns 1 row" );
	is( $rows[0]->select('employee_id'), $snuffle_id,
	    "Make sure that the returned row is snuffleupagus" );

	my $rows = $emp_t->function( select => [ $emp_t->column('employee_id'), MATCH( $emp_t->column('name') ), AGAINST('snuffleupagus') ],
				     where => [ MATCH( $emp_t->column('name') ), AGAINST('snuffleupagus') ] );
	my ($id, $score) = @$rows;
	is( $id, $snuffle_id,
	    "Returned row should still be snuffleupagus" );
	like( $score, qr/\d+(?:\.\d+)?/,
	      "Returned score should be some sort of number (integer or floating point)" );
	ok( $score > 0,
	    "The score should be greater than 0 because the match was successful" );

	eval_ok( sub { @rows = $emp_t->all_rows( order_by => [ IF( 'employee_id < 100',
								   $emp_t->column('employee_id'),
								   $emp_t->column('smell') ),
                                                               $emp_t->column('employee_id'),
                                                             ],
					       )->all_rows },
		 "Order by IF() function" );
	is( @rows, 16,
	    "Seventeen rows should have been returned" );
	is( $rows[0]->select('employee_id'), 3,
	    "First row should be id 3" );
	is( $rows[-1]->select('employee_id'), 999993,
	    "Last row should be id 999993" );

	eval_ok( sub { @rows = $emp_t->all_rows( order_by => RAND() )->all_rows },
		 "order by RAND()" );
	is ( @rows, 16,
	     "This should return 16 rows" );
    }
    elsif ( $rdbms eq 'pg' )
    {
	my $emp;
	eval_ok( sub { $emp = $emp_t->insert( values => { name => NOW(),
							  dep_id => $dep_id } ) },
		 "Do insert using SQL function NOW()" );

	like( $emp->select('name'), qr/\d+/,
	      "Name should be all digits (Postgres timestamp)" );

	eval_ok( sub { $emp->update( name => LOWER('FOO') ) },
		 "Do update using SQL function LOWER()" );

	is( $emp->select('name'), 'foo',
	    "Name should be 'foo'" );

	eval_ok( sub { $emp->update( name => REPEAT('Foo', 3) ) },
		 "Do update using SQL function REPEAT()" );

	is( $emp->select('name'), 'FooFooFoo',
	    "Name should be 'FooFooFoo'" );

	eval_ok( sub { $emp->update( name => UPPER( REPEAT('Foo', 3) ) ) },
		 "Do update using nested SQL functions UPPER(REPEAT())" );

	is( $emp->select('name'), 'FOOFOOFOO',
	    "Name should be 'FOOFOOFOO'" );

	$emp_t->insert( values => { name => 'Timestamp',
				    dep_id => $dep_id,
				    tstamp => time - 100_000 } );

	my $cursor;
	eval_ok( sub { $cursor =
			   $emp_t->rows_where( where =>
					       [ [ $emp_t->column('tstamp'), '!=', undef ],
						 [ $emp_t->column('tstamp'), '<', NOW() ] ] ) },
		 "Do select with where condition that uses SQL function NOW()" );

	my @rows = $cursor->all_rows;
	is( scalar @rows, 1,
	    "Only one row should have a timestamp value that is not null and that is less than the current time" );
	is( $rows[0]->select('name'), 'Timestamp',
	    "That row should be named Timestamp" );
    }

    # Potential rows
    my $p_emp;
    eval_ok( sub { $p_emp = $emp_t->potential_row },
	     "Create potential row object");

    is( $p_emp->is_live, 0,
        "potential_row should ! ->is_live" );

    is( $p_emp->select('smell'), 'grotesque',
	"Potential Employee should have default smell, 'grotesque'" );

    {
        my $updated = $p_emp->update( cash => undef, smell => 'hello!' );

        ok( $updated, 'update() did change values' );
        ok( ! defined $p_emp->select('cash'),
            "Potential Employee cash column is not defined" );
    }

    {
        my $updated = $p_emp->update( cash => undef, smell => 'hello!' );

        ok( ! $updated, 'update() did not change values' );
    }

    is( $p_emp->select('smell'), 'hello!',
	"smell for employee should be 'hello!' after update" );

    $p_emp->update( name => 'Ilya' );
    is( $p_emp->select('name'), 'Ilya',
        "New employee got a name" );

    $p_emp->update( dep_id => $dep_id );
    is( $p_emp->select('dep_id'), $dep_id,
        "New employee got a department" );

    eval { $p_emp->update( wrong => 'column' ) };
    $e = $@;
    isa_ok( $e, 'Alzabo::Exception::Params',
	    "Exception thrown from attempt to update a column which doesn't exist" );

    eval { $p_emp->update( name => undef ) };
    $e = $@;
    isa_ok( $e, 'Alzabo::Exception::NotNullable',
	    "Exception thrown from attempt to update a non-NULLable column in a potential row to null" );

    eval_ok( sub { $p_emp->make_live( values => { smell => 'cottony' } ) },
	     "Make potential row live");

    is( $p_emp->select('name'), 'Ilya',
        "Formerly potential employee row object should have same name as before" );

    is( $p_emp->select('smell'), 'cottony',
        "Formerly potential employee row object should have new smell of 'cottony'" );

    eval_ok ( sub { $p_emp->delete },
	      "Delete new employee" );

    eval_ok( sub { $p_emp = $emp_t->potential_row( values => { cash => 100 } ) },
	     "Create potential row object and set some fields ");

    is( $p_emp->select('cash'), 100,
	"Employee cash should be 100" );

    eval { $emp_t->rows_where( where => [ $eid_c, '=', 9000,
					  $eid_c, '=', 9002 ] ) };
    $e = $@;
    isa_ok( $e, 'Alzabo::Exception::Params',
	    "Exception from where clause as single arrayref with <>3 elements" );

    {
	# test that DriverStatement objects going out of scope leave
	# $@ alone!
	eval
	{
	    my $cursor = $emp_t->all_rows;

	    die "ok\n";
	};

	is( $@, "ok\n",
	    "\$\@ should be 'ok'" );
    }

    {
	my $row;
	eval_ok( sub { $row =
			   $emp_t->one_row
			       ( where => [ $emp_t->column('name'), '=', 'nonexistent' ] ) },
		 "Call ->one_row with a query guaranteed to fail" );

	ok( ! defined $row,
	    "Make sure that the query really returned nothing" );
    }

    {
        is( scalar $proj_t->prefetch,
            ( scalar $proj_t->columns -
              $proj_t->primary_key_size -
              scalar ( grep { $_->is_blob } $proj_t->columns ) ),
            "Check that schema->prefetch_all_but_blobs is on by default" );
    }

    {
        $proj_t->set_prefetch();
        $s->prefetch_all;

        is( scalar $proj_t->prefetch,
            ( scalar $proj_t->columns -
              scalar $proj_t->primary_key_size ),
            "Check that schema->prefetch_all works" );
    }

    {
        $proj_t->set_prefetch();
        $s->prefetch_all_but_blobs;

        is( scalar $proj_t->prefetch,
            ( scalar $proj_t->columns -
              $proj_t->primary_key_size -
              scalar ( grep { $_->is_blob } $proj_t->columns ) ),
            "Check that schema->prefetch_all_but_blobs works" );
    }

    {
        $s->prefetch_none;

        is( scalar $proj_t->prefetch, 0,
            "Check that schema->prefetch_none works" );
    }

    {
        $s->prefetch_all;

        my $cursor;

        eval_ok( sub { $cursor =
                           $s->join( join  => [ $emp_t, $emp_proj_t, $proj_t ],
                                     where => [ $emp_t->column('employee_id'), '=', 9001 ] ) },
                 "Join with join as arrayref of arrayrefs" );

        my @rows = $cursor->next;

        is( scalar @rows, 3,
            "3 rows per cursor ->next call" );
        is( ( grep { defined } @rows ), 3,
            "Make sure all rows are defined" );
        is( $rows[0]->select('employee_id'), 9001,
            "First rows should have employee_id == 9001" );
        is( $rows[0]->select('name'), 'bob9001',
            "First rows should have employee with name eq 'bob9001'" );
        is( $rows[2]->select('name'), 'Extend',
            "First rows should have project with name eq 'Extend'");
    }

    {
        my $foo = $emp_t->column('employee_id')->alias( as => 'foo' );

        my $st = $emp_t->select( select => $foo );

        my %h = $st->next_as_hash;
        is( exists $h{foo}, 1,
            "next_as_hash should return a hash with a 'foo' key" );
    }

    $s->disconnect;
}
