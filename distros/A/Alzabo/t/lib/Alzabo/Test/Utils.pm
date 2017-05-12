package Alzabo::Test::Utils;

use strict;

use Alzabo::Config;
use Cwd ();
use File::Path ();
use File::Spec;

use Module::Build;


# This should always happen whenever the module is loaded

__PACKAGE__->create_test_schema_dir;


# Used in a number of test files

sub main::eval_ok (&$)
{
    my ( $code, $name ) = @_;

    eval { $code->() };
    if ( my $e = $@ )
    {
	Test::More::ok( 0, $name );
	Test::More::diag("     got error: $e\n" );
    }
    else
    {
	Test::More::ok( 1, $name );
    }
}

sub create_test_schema_dir
{
    my $class = shift;

    my $schema_dir = $class->_schema_dir;

    unless ( -d $schema_dir )
    {
        mkdir $schema_dir, 0755
            or die "Can't make dir $schema_dir for testing: $!\n";
    }
}

sub _schema_dir
{
    my $class = shift;

    return File::Spec->catdir( $class->_root_dir, 'schemas' );
}

sub _root_dir
{
    my $cwd = Cwd::cwd();

    my $root_dir = File::Spec->catdir( $cwd, 't' );

    Alzabo::Config::root_dir($root_dir);

    return $root_dir;
}

sub rdbms_names
{
    my $class = shift;

    my %c = $class->test_config;

    return sort keys %c;
}

sub rdbms_count
{
    my $class = shift;

    return scalar $class->rdbms_names;
}

sub test_config
{
    my $build = Module::Build->current;

    my $tests = $build->notes('test_config');

    return map { $_->{rdbms} => $_ } @$tests;
}

sub mysql_test_config
{
    my $class = shift;

    my %t = $class->test_config;

    return $t{mysql};
}

sub pg_test_config
{
    my $class = shift;

    my %t = $class->test_config;

    return $t{pg};
}

sub test_config_for
{
    my $class = shift;
    my $rdbms = shift;

    my $meth = "${rdbms}_test_config";

    return $class->$meth();
}

sub connect_params_for
{
    my $class = shift;

    my $config = $class->test_config_for( shift );

    return ( map { defined $config->{$_}
                   ? ( $_ => $config->{$_} )
                   : () }
             qw( user password host port )
           );
}

sub cleanup
{
    my $class = shift;

    $class->remove_schema_dir;

    $class->remove_all_schemas;
}

sub remove_schema_dir
{
    my $class = shift;

    my $dir = $class->_schema_dir;

    Test::More::diag( "Removing test schema directory: $dir" );

    File::Path::rmtree( $dir, $Test::Harness::verbose, 0 );
}

sub remove_all_schemas
{
    my $class = shift;

    $class->remove_schema($_) foreach 'mysql', 'pg';
}

sub remove_schema
{
    my $class = shift;
    my $rdbms = shift;

    my $meth = "remove_${rdbms}_schema";

    $class->$meth();
}

sub remove_mysql_schema
{
    my $class = shift;

    my $config = $class->mysql_test_config();

    return unless keys %$config;

    Test::More::diag( "Removing MySQL database $config->{schema_name}" );

    my $s = $class->_load_or_create( name => $config->{schema_name},
                                     rdbms => 'MySQL' );

    delete @{ $config }{ 'schema_name', 'rdbms' };

    eval { $s->drop( %$config ) };
    eval { $s->drop( %$config, schema_name => $s->name . '_2' ) };

    $s->delete if $s->is_saved;
}

sub remove_pg_schema
{
    my $class = shift;

    my $config = $class->pg_test_config();

    return unless keys %$config;

    Test::More::diag( "Removing PostgreSQL database $config->{schema_name}" );

    my $s = $class->_load_or_create( name => $config->{schema_name},
                                     rdbms => 'PostgreSQL' );

    delete @{ $config }{ 'schema_name', 'rdbms' };

    eval { $s->drop(%$config) };
    eval { $s->drop( %$config, schema_name => $s->name . '_2' ) };

    $s->delete if $s->is_saved;
}

sub _load_or_create
{
    my $class = shift;
    my %p = @_;

    require Alzabo::Create::Schema;

    my $s;

    $s = eval { Alzabo::Create::Schema->load_from_file( name => $p{name} ) };

    return $s if $s;

    return Alzabo::Create::Schema->new(%p);
}

sub any_connected_runtime_schema
{
    my $class = shift;

    my $rdbms = ( $class->rdbms_names )[0];

    return unless $rdbms;

    my $s = $class->make_schema($rdbms);

    my $r = Alzabo::Runtime::Schema->load_from_file( name => $s->name );

    $r->connect( $class->connect_params_for($rdbms) );

    return $r;
}

sub any_schema_name
{
    my $class = shift;

    my $rdbms = ( $class->rdbms_names )[0];
    my $s = $class->make_schema($rdbms);

    return $s->name;
}

sub make_schema
{
    my $class = shift;
    my $rdbms = shift;
    my $skip_create = shift;

    my $meth = "make_${rdbms}_schema";

    return $class->$meth($skip_create);
}

sub make_mysql_schema
{
    my $class = shift;
    my $skip_create = shift;

    my $config = $class->mysql_test_config;

    my $s = Alzabo::Create::Schema->new( name => $config->{schema_name},
					 rdbms => 'MySQL',
				       );

    $s->make_table( name => 'employee',
		    attributes => [ 'TYPE=MYISAM' ],
		  );
    my $emp_t = $s->table('employee');

    $emp_t->make_column( name => 'employee_id',
			 type => 'int',
			 sequenced => 1,
			 primary_key => 1,
		       );
    $emp_t->make_column( name => 'name',
			 type => 'varchar',
			 length => 200,
		       );
    $emp_t->make_column( name => 'smell',
			 type => 'varchar',
			 length => 200,
			 nullable => 0,
			 default => 'grotesque',
		       );
    $emp_t->make_column( name => 'cash',
			 type => 'float',
			 length => 6,
			 precision => 2,
			 nullable => 1,
		       );
    $emp_t->make_column( name => 'tstamp',
			 type => 'integer',
			 nullable => 1,
		       );
    # only here to test that making an enum works - not used in tests
    $emp_t->make_column( name => 'test_enum',
			 type => "enum('foo','bar')",
			 nullable => 1 );

    $emp_t->make_index( columns => [ { column => $emp_t->column('name'),
				       prefix => 10 },
				     { column => $emp_t->column('smell') },
				   ] );

    # Having a fulltext index tests handling of mysql fulltext index
    # sub_part bug when reverse engineering
    $emp_t->make_index( columns => [ { column => $emp_t->column('name') } ],
			fulltext => 1 );

    $s->make_table( name => 'department',
		    attributes => [ 'TYPE=MYISAM' ],
		  );
    my $dep_t = $s->table('department');
    $dep_t->make_column( name => 'department_id',
			 type => 'int',
			 sequenced => 1,
			 primary_key => 1,
		       );
    $dep_t->make_column( name => 'name',
			 type => 'varchar',
			 length => 200,
		       );
    $dep_t->make_column( name => 'manager_id',
			 type => 'int',
			 length => 200,
			 nullable => 1,
		       );

    $s->add_relationship( table_from => $dep_t,
			  table_to => $emp_t,
			  columns_from => $dep_t->column('manager_id'),
			  columns_to => $emp_t->column('employee_id'),
			  cardinality => [1, 1],
			  from_is_dependent => 0,
			  to_is_dependent => 0,
			);
    $s->add_relationship( table_from => $emp_t,
			  table_to => $dep_t,
			  cardinality => ['n', 1],
			  from_is_dependent => 1,
			  to_is_dependent => 0,
			);

    $s->make_table( name => 'project',
		    attributes => [ 'TYPE=MYISAM' ],
		  );
    my $proj_t = $s->table('project');
    $proj_t->make_column( name => 'project_id',
			  type => 'int',
			  sequenced => 1,
			  primary_key => 1,
			);
    $proj_t->make_column( name => 'name',
			  type => 'varchar',
			  length => 200,
			);
    $proj_t->make_index( columns => [ { column => $proj_t->column('name'),
					prefix => 20 } ] );
    $proj_t->make_column( name => 'blobby',
			  type => 'text',
                          nullable => 1,
			);

    $s->add_relationship( table_from => $proj_t,
			  table_to   => $dep_t,
			  cardinality => ['n', 1],
			  from_is_dependent => 1,
			  to_is_dependent => 0,
			);

    $emp_t->column('department_id')->set_name('dep_id');

    $s->add_relationship( table_from => $emp_t,
			  table_to   => $proj_t,
			  cardinality => ['n', 'n'],
			  from_is_dependent => 0,
			  to_is_dependent => 0,
			);

    $s->table('employee_project')->set_attributes( 'TYPE=MYISAM' );

    my $char_pk_t = $s->make_table( name => 'char_pk',
				    attributes => [ 'TYPE=MYISAM' ],
				  );
    $char_pk_t->make_column( name => 'char_col',
			     type => 'varchar',
			     length => 40,
			     primary_key => 1 );


    my $outer_1_t = $s->make_table( name => 'outer_1',
				    attributes => [ 'TYPE=MYISAM' ],
				  );
    $outer_1_t->make_column( name => 'outer_1_pk',
			     type => 'int',
			     sequenced => 1,
			     primary_key => 1,
			   );
    $outer_1_t->make_column( name => 'outer_1_name',
			     type => 'varchar',
			     length => 40,
			   );
    $outer_1_t->make_column( name => 'outer_2_pk',
			     type => 'int',
                             nullable => 1,
			   );

    my $outer_2_t = $s->make_table( name => 'outer_2',
				    attributes => [ 'TYPE=MYISAM' ],
				  );
    $outer_2_t->make_column( name => 'outer_2_pk',
			     type => 'int',
			     sequenced => 1,
			     primary_key => 1,
			   );
    $outer_2_t->make_column( name => 'outer_2_name',
			     type => 'varchar',
			     length => 20,
			   );

    $s->add_relationship( table_from => $outer_1_t,
			  table_to   => $outer_2_t,
			  columns_from => $outer_1_t->column('outer_2_pk'),
			  columns_to   => $outer_2_t->column('outer_2_pk'),
			  cardinality => [1, 1],
			  from_is_dependent => 0,
			  to_is_dependent => 0,
			);

    my $u = $s->make_table( name => 'user',
			    attributes => [ 'TYPE=MYISAM' ],
			  );
    $u->make_column( name => 'user_id', type => 'integer', primary_key => 1 );

    unless ($skip_create)
    {
        delete @{ $config }{'rdbms', 'schema_name'};

        $s->create(%$config);

        $s->driver->disconnect;
    }

    $s->save_to_file;

    return $s;
}

# make sure to use native types or Postgres converts them and then the
# reverse engineering tests fail.
sub make_pg_schema
{
    my $class = shift;
    my $skip_create = shift;

    my $config = $class->pg_test_config;

    my $s = Alzabo::Create::Schema->new( name => $config->{schema_name},
					 rdbms => 'PostgreSQL',
				       );

    $s->make_table( name => 'employee' );
    my $emp_t = $s->table('employee');

    $emp_t->make_column( name => 'employee_id',
			 type => 'serial',
			 sequenced => 1,
			 primary_key => 1,
		       );

    $emp_t->make_column( name => 'name',
			 type => 'varchar',
			 length => 200,
		       );

    $emp_t->make_column( name => 'smell',
			 type => 'varchar',
			 length => 200,
			 nullable => 1,
			 default => 'grotesque',
		       );

    $emp_t->make_column( name => 'cash',
			 type => 'numeric',
			 length => 6,
			 precision => 2,
			 nullable => 1,
		       );

    $emp_t->make_column( name => 'tstamp',
			 type => 'integer',
			 nullable => 1,
		       );

    $emp_t->make_index( columns => [ { column => $emp_t->column('name') } ] );
    $emp_t->make_index( columns => [ { column => $emp_t->column('smell') } ],
                        function => 'lower(smell)',
                      );

    $s->make_table( name => 'department');
    my $dep_t = $s->table('department');

    $dep_t->make_column( name => 'department_id',
			 type => 'int4',
			 sequenced => 1,
			 primary_key => 1,
		       );

    $dep_t->make_column( name => 'name',
			 type => 'varchar',
			 length => 200,
		       );

    $dep_t->make_column( name => 'manager_id',
			 type => 'int4',
			 nullable => 1,
		       );

    $s->add_relationship( table_from => $dep_t,
			  table_to => $emp_t,
			  columns_from => $dep_t->column('manager_id'),
			  columns_to => $emp_t->column('employee_id'),
			  cardinality => [ 1, 1 ],
			  from_is_dependent => 0,
			  to_is_dependent => 0,
			);

    $s->add_relationship( table_from => $emp_t,
			  table_to => $dep_t,
			  cardinality => ['n', 1],
			  from_is_dependent => 1,
			  to_is_dependent => 0,
			);

    $s->make_table( name => 'project' );

    my $proj_t = $s->table('project');
    $proj_t->make_column( name => 'project_id',
			  type => 'int4',
			  sequenced => 1,
			  primary_key => 1,
			);

    $proj_t->make_column( name => 'name',
			  type => 'varchar',
			  length => 200,
			);

    $proj_t->make_column( name => 'blobby',
			  type => 'text',
                          nullable => 1,
			);

    $s->add_relationship( table_from => $emp_t,
			  table_to   => $proj_t,
			  cardinality => ['n', 'n'],
			  from_is_dependent => 0,
			  to_is_dependent => 0,
			);

    $proj_t->make_index( columns => [ { column => $proj_t->column('name') } ] );

    $emp_t->column('department_id')->set_name('dep_id');

    $s->add_relationship( table_from => $proj_t,
			  table_to   => $dep_t,
			  cardinality => ['n', 1],
			  from_is_dependent => 1,
			  to_is_dependent => 0,
			);

    my $char_pk_t = $s->make_table( name => 'char_pk' );
    $char_pk_t->make_column( name => 'char_col',
			     type => 'varchar',
			     length => 20,
			     primary_key => 1 );

    $char_pk_t->make_column( name => 'fixed_char',
			     type => 'char',
			     nullable => 1,
			     length => 5 );

    my $outer_1_t = $s->make_table( name => 'outer_1' );
    $outer_1_t->make_column( name => 'outer_1_pk',
			     type => 'int',
			     sequenced => 1,
			     primary_key => 1,
			   );

    $outer_1_t->make_column( name => 'outer_1_name',
			     type => 'varchar',
			     length => 40,
			   );

    $outer_1_t->make_column( name => 'outer_2_pk',
			     type => 'int',
			     nullable => 1,
			   );

    my $outer_2_t = $s->make_table( name => 'outer_2' );
    $outer_2_t->make_column( name => 'outer_2_pk',
			     type => 'int',
			     sequenced => 1,
			     primary_key => 1,
			   );

    $outer_2_t->make_column( name => 'outer_2_name',
			     type => 'varchar',
			     length => 40,
			   );

    $s->add_relationship( table_from => $outer_1_t,
			  table_to   => $outer_2_t,
			  columns_from => $outer_1_t->column('outer_2_pk'),
			  columns_to   => $outer_2_t->column('outer_2_pk'),
			  cardinality => [1, 1],
			  from_is_dependent => 0,
			  to_is_dependent => 0,
			);

    my $mixed = $s->make_table( name => 'MixEDCasE' );
    $mixed->make_column( name => 'mixed_CASE_Pk',
			 type => 'integer',
			 primary_key => 1 );

    my $name = $config->{schema_name};

    unless ($skip_create)
    {
        delete @{ $config }{'rdbms', 'schema_name'};

        $s->create(%$config);

        $s->driver->disconnect;
    }

    $s->save_to_file;

    return $s;
}


1;

__END__

=head1 DESCRIPTION

Alzabo::Test::Utils - Utility module for Alzabo test suite

=head1 SYNOPSIS

  use Alzabo::Test::Utils;

  Alzabo::Test::Utils->

=cut
