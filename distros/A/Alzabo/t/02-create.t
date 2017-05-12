#!/usr/bin/perl -w

use strict;

use File::Spec;

use lib '.', File::Spec->catdir( File::Spec->curdir, 't', 'lib' );

use Alzabo::Test::Utils;

use Test::More;


use Alzabo::Create;
use Alzabo::Config;


my @db;
my $tests = 0;

my $shared_tests = 150;
my $mysql_only_tests = 7;
my $pg_only_tests = 8;

if ( eval { require DBD::mysql } && ! $@ )
{
    push @db, 'MySQL';
    $tests += $shared_tests;
    $tests += $mysql_only_tests;
}

if ( eval { require DBD::Pg } && ! $@ )
{
    push @db, 'PostgreSQL';
    $tests += $shared_tests;
    $tests += $pg_only_tests;
}

unless ($tests)
{
    plan skip_all => 'no database drivers available';
    exit;
}

plan tests => $tests;

foreach my $db (@db)
{
    my $s = Alzabo::Create::Schema->new( name => "foo_$db",
					 rdbms => $db,
				       );

    ok( $s && ref $s,
	"Create a schema object" );

    ok( $s->name eq "foo_$db",
	"Make sure schema name is " . $s->name );

    isa_ok( $s->rules,"Alzabo::RDBMSRules::$db",
	    "Schema's rules object" );

    isa_ok( $s->driver,"Alzabo::Driver::$db",
	    "Schema's driver object" );

    my $dir = Alzabo::Config->schema_dir;
    {
	eval_ok( sub { $s->save_to_file },
		 "Call schema's save_to_file method" );

	my $base = File::Spec->catdir( $dir, $s->name );
	my $name = $s->name;
	ok( -d $base,
	    "'$base' should exist" );

	ok( -e "$base/$name.create.alz",
	    "'$base/$name.create.alz' file should exist" );
	ok( -e "$base/$name.runtime.alz",
	    "'$base/$name.runtime.alz' file should exist" );
	ok( -e "$base/$name.rdbms",
	    "'$base/$name.rdbms' file should exist" );
    }

    eval_ok( sub { $s->make_table( name => 'footab' ) } , "Make table 'footab'" );

    my $t1;
    eval_ok( sub { $t1 = $s->table('footab') }, "Retrieve 'footab' table from schema" );
    isa_ok( $t1, 'Alzabo::Create::Table',
	    "Object returned from \$s->table" );

    my $att = $db eq 'MySQL' ? 'unsigned' : 'check > 5';

    eval_ok( sub { $t1->make_column( name => 'foo_pk',
				     type => 'int',
				     attributes => [ $att ],
				     sequenced => 1,
				     nullable => 0,
				   ) },
	     "Make column 'foo_pk' in 'footab'" );


    eval { $s->tables( 'footab', 'does not exist' ) };
    like( $@, qr/Table does not exist doesn't exist/,
          "Make sure tables method catches missing tables" );

    eval { $s->table( 'does not exist' ) };
    isa_ok( $@, 'Alzabo::Exception::Params',
          "Make sure table() method catches missing tables" );

    eval { $t1->columns( 'foo_pk', 'does not exist' ) };
    like( $@, qr/Column does not exist doesn't exist/,
          "Make sure columns method catches missing columns" );

    my $t1_c1;
    eval_ok( sub { $t1_c1 = $t1->column('foo_pk') },
	     "Retrieve 'foo_pk' from 'footab'" );
    isa_ok( $t1_c1, 'Alzabo::Create::Column',
	    "Object returned from \$table->column" );

    is( $t1_c1->type, 'INTEGER',
	"foo_pk type should be 'INTEGER'" );
    is( scalar @{[$t1_c1->attributes]}, 1,
	"foo_pk should have one attribute" );
    is( ($t1_c1->attributes)[0], $att,
	"foo_pk's attribute should be $att" );
    ok( $t1_c1->has_attribute( attribute => uc $att ),
	"foo_pk should have attribute '\U$att\E' (case-insensitive check)" );
    ok( ! $t1_c1->has_attribute( attribute => uc $att, case_sensitive => 1 ),
	"foo_pk should _not_ have attribute '\U$att\E' (case-sensitive check)" );
    ok( ! $t1_c1->nullable,
	"foo_pk should not be nullable" );

    eval_ok( sub { $t1->add_primary_key($t1_c1) },
	     "Make 'foo_pk' a primary key for 'footab'" );

    ok( $t1_c1->is_primary_key,
	"'foo_pk' should be a primary key" );

    eval_ok( sub { $s->make_table( name => 'bartab' ) },
	     "Make table 'bartab'" );

    my $t2;
    eval_ok( sub { $t2 = $s->table('bartab') },
	     "Retrieve table 'bartab'" );
    isa_ok( $t2, 'Alzabo::Create::Table',
	    "'bartab'" );

    eval_ok( sub { $t2->make_column( name => 'bar_pk',
				     type => 'int',
				     default => 10,
				     sequenced => 1,
				     nullable => 0,
				   ) },
	     "Add 'bar_pk' to 'bartab'" );

    my $t2_c1;
    eval_ok( sub { $t2_c1 = $t2->column('bar_pk') },
	     "Retrieve 'bar_pk' from 'bartab'" );
    isa_ok( $t2_c1, 'Alzabo::Create::Column',
	    "'bar_pk'" );

    is( $t2_c1->default, '10',
	"bar_pk default should be '10'" );

    eval_ok( sub { $t2->add_primary_key($t2_c1) },
	     "Make 'bar_pk' a primary key for 'bartab'" );

    eval_ok( sub { $s->add_relationship( table_from => $t1,
					 table_to   => $t2,
					 cardinality => ['n', 'n'],
					 from_is_dependent => 0,
					 to_is_dependent => 0,
				       ) },
	     "Add many to many relationship from 'footab' to 'bartab'" );

    my $link;
    eval_ok( sub { $link = $s->table('footab_bartab') },
	     "Retrieve linking table 'footab_bartab'" );
    isa_ok( $link, 'Alzabo::Create::Table',
	    "'footab_bartab'" );

    my @t1_fk;
    eval_ok( sub { @t1_fk = $t1->foreign_keys( table => $link,
					       column => $t1_c1 ) },
	     "Retrieve foreign keys to linking table from 'footab'" );

    is( scalar @t1_fk, 1,
	"One and only one foreign key returned from 'footab'" );

    my $t1_fk = $t1_fk[0];

    isa_ok( $t1_fk, 'Alzabo::Create::ForeignKey',
	    "Return value from footab->foreign_keys" );

    is( $t1_fk->columns_from->name, 'foo_pk',
	"The foreign key from footab to the footab_bartab table's columns_from value should be 'foo_pk'" );
    is( $t1_fk->columns_from->table->name, 'footab',
	"The foreign key columns_from for the footab table should belong to the footab table" );
    is( $t1_fk->columns_to->name, 'foo_pk',
	"The foreign key from footab to the footab_bartab table's columns_to value should be 'foo_pk'" );
    is( $t1_fk->columns_to->table->name, 'footab_bartab',
	"The foreign key columns_to for the footab table should belong to the footab_bartab table" );
    is( $t1_fk->table_from->name, 'footab',
	"The table_from for the foreign key should be footab" );
    is( $t1_fk->table_to->name, 'footab_bartab',
	"The table_to for the foreign key should be footab_bartab" );

    my @t2_fk;
    eval_ok( sub { @t2_fk = $t2->foreign_keys( table => $link,
					       column => $t2_c1 ) },
	     "Retrieve foreign keys from 'bartab' to linking table" );

    is( scalar @t2_fk, 1,
	"Only one foreign key should be returned from 'bartab'" );

    my $t2_fk = $t2_fk[0];

    isa_ok( $t2_fk, 'Alzabo::Create::ForeignKey',
	    "Return value from bartab->foreign_keys" );

    is( $t2_fk->columns_from->name, 'bar_pk',
	"The foreign key from bartab to the table's columns_from value should be 'bar_pk'" );
    is( $t2_fk->columns_from->table->name, 'bartab',
	"The foreign key columns_from for the bartab table should belong to the bartab table" );
    is( $t2_fk->columns_to->name, 'bar_pk',
	"The foreign key from bartab to the linking table's columns_to value should be 'bar_pk'" );
    is( $t2_fk->columns_to->table->name, 'footab_bartab',
	"The foreign key columns_to for the bartab table should belong to the footab_bartab table" );
    is( $t2_fk->table_from->name, 'bartab',
	"The table_from for the foreign key should be bartab" );
    is( $t2_fk->table_to->name, 'footab_bartab',
	"The table_to for the foreign key should be footab_bartab" );

    my @link_fk;
    eval_ok( sub { @link_fk = $link->foreign_keys( table => $t1,
						   column => $link->column('foo_pk') ) },
	     "Retrieve foreign keys from 'footab_bartab' to 'footab'" );

    is( scalar @link_fk, 1,
	"Only one foreign key should be returned from 'footab_bartab'" );

    my $link_fk = $link_fk[0];

    is( $link_fk->columns_from->name, 'foo_pk',
	"The foreign key from footab_bartab to the table's columns_from value should be 'foo_pk'" );
    is( $link_fk->columns_from->table->name, 'footab_bartab',
	"The foreign key columns_from for the footab_bartab table should belong to the footab_bartab table" );
    is( $link_fk->columns_to->name, 'foo_pk',
	"The foreign key from footab_bartab to the linking table's columns_to value should be 'foo_pk'" );
    is( $link_fk->columns_to->table->name, 'footab',
	"The foreign key columns_to for the footab_bartab table should belong to the footab table" );
    is( $link_fk->table_from->name, 'footab_bartab',
	"The table_from for the foreign key should be footab_bartab" );
    is( $link_fk->table_to->name, 'footab',
	"The table_to for the foreign key should be footab" );

    eval_ok( sub { @link_fk = $link->foreign_keys( table => $t2,
						   column => $link->column('bar_pk') ) },
	     "Retrieve foreign keys from 'footab_bartab' to 'bartab'" );

    $link_fk = $link_fk[0];

    is( $link_fk[0]->columns_from->name, 'bar_pk',
	"The foreign key from footab_bartab to the table's columns_from value should be 'bar_pk'" );
    is( $link_fk[0]->columns_from->table->name, 'footab_bartab',
	"The foreign key columns_from for the footab_bartab table should belong to the footab_bartab table" );
    is( $link_fk[0]->columns_to->name, 'bar_pk',
	"The foreign key from footab_bartab to the linking table's columns_to value should be 'bar_pk'" );
    is( $link_fk[0]->columns_to->table->name, 'bartab',
	"The foreign key columns_to for the footab_bartab table should belong to the bartab table" );
    is( $link_fk[0]->table_from->name, 'footab_bartab',
	"The table_from for the foreign key should be footab_bartab" );
    is( $link_fk[0]->table_to->name, 'bartab',
	"The table_to for the foreign key should be bartab" );

    eval_ok( sub { $s->add_relationship( table_from => $t1,
					 table_to => $t2,
					 cardinality => [ 'n', 1 ],
					 from_is_dependent => 0,
					 to_is_dependent => 0,
				       ) },
	     "Create a many to one relation from 'footab' to 'bartab'" );

    my $new_col;
    eval_ok( sub { $new_col = $t1->column('bar_pk') },
	     "Retrieve the newly create 'bar_pk' column from 'footab'" );

    is( $new_col->definition, $t2->column('bar_pk')->definition,
	"bar_pk columns in footab and bartab should share the same definition object" );

    my @fk;
    eval { @fk = $t1->foreign_keys( table => $t2,
				    column => $new_col ); };
    ok( @fk,
	"footab should have a foreign key to bartab from bar_pk" );

    ok( @fk,
	"footab should only have one foreign key to bartab from bar_pk" );

    eval { @fk = $t2->foreign_keys( table => $t1,
				    column => $t2->column('bar_pk') ); };
    ok( @fk,
	"bartab should have a foreign key to footab from bar_pk" );

    ok( @fk,
	"bartab should only have one foreign key to footab from bar_pk" );

    eval_ok( sub { $s->add_relationship( table_from => $t1,
					 table_to => $t2,
					 cardinality => [ 1, 'n' ],
					 from_is_dependent => 0,
					 to_is_dependent => 0,
				       ) },
	     "Create a second relation (this time one to many) from footab to bartab" );

    eval_ok( sub { $new_col = $t2->column('foo_pk') },
	     "Retrieve the newly created foo_pk column from bartab" );

    is( $new_col->definition, $t1->column('foo_pk')->definition,
	"foo_pk columns in footab and bartab should share the same definition object" );

    eval { @fk = $t2->foreign_keys( table => $t1,
				    column => $new_col ); };

    ok( @fk,
	"bartab should have a foreign key to bartab from foo_pk" );

    ok( @fk,
	"bartab should only have one foreign key to bartab from foo_pk" );

    eval { @fk = $t1->foreign_keys( table => $t2,
				    column => $t1->column('foo_pk') ); };

    ok( @fk,
	"footab should have a foreign key to bartab from foo_pk" );

    ok( @fk,
	"footab should only have one foreign key to bartab from foo_pk" );

    $s->make_table( name => 'baztab' );
    my $t3 = $s->table('baztab');

    eval_ok( sub { $s->add_relationship( table_from => $t1,
					 table_to => $t3,
					 cardinality => [ 1, 'n' ],
					 from_is_dependent => 0,
					 to_is_dependent => 0,
				       ) },
	     "Add one to many relation from footab to baztab" );

    eval_ok( sub { $new_col = $t3->column('foo_pk') },
	     "Retrieve the foo_pk column from baztab" );

    is( $new_col->definition, $t1->column('foo_pk')->definition,
	"foo_pk columns in footab and baztab should share the same definition object" );

    eval { @fk = $t3->foreign_keys( table => $t1,
				    column => $new_col ); };
    ok( @fk,
	"baztab should have a foreign key to footab from foo_pk" );

    is( scalar @fk, 1,
	"baztab should only have one foreign key to footab from foo_ok" );

    eval { @fk = $t1->foreign_keys( table => $t3,
				    column => $t1->column('foo_pk') ); };
    ok( @fk,
	"footab should have foreign key to baztab from foo_pk" );

    is( scalar @fk, 1,
	"footab should only have one foreign key to baztab from foo_ok" );

    eval_ok( sub { $s->delete_table($link) },
	     "Delete foo_tab from schema" );

    @fk = $t1->all_foreign_keys;
    is( scalar @fk, 3,
	"footab table should have 3 foreign key after deleting footab_bartab table" );

    @fk = $t2->all_foreign_keys;
    is( scalar @fk, 2,
	"bartab table should have 2 foreign keys after deleting footab_bartab" );

    $s->delete_table($t1);

    @fk = $t3->all_foreign_keys;
    is( scalar @fk, 0,
	"baztab table should have 0 foreign keys after deleting footab table" );

    ok( ! exists $t2->{fk}{footab},
	"The \$t2 object's internal {fk} hash should not have a {footab} entry" );

    my $tc = $s->make_table( name => 'two_col_pk' );
    $tc->make_column( name => 'pk1',
		      type => 'int',
		      primary_key => 1 );

    eval_ok( sub { $tc->make_column( name => 'pk2',
				     type => 'int',
				     primary_key => 1 ) },
	     "Add a second primary column to two_col_pk" );

    my @pk = $tc->primary_key;
    is( scalar @pk, 2,
	"two_col_pk has two primary keys" );

    is( $pk[0]->name, 'pk1',
	"First primary column should be pk1" );

    is( $pk[1]->name, 'pk2',
	"Second primary column should be pk2" );


    $tc->make_column( name => 'non_pk',
		      type => 'varchar',
		      length => 2 );

    my $other = $s->make_table( name => 'other' );
    $other->make_column( name => 'other_pk',
			 type => 'int',
			 primary_key => 1 );
    $other->make_column( name => 'somethin',
			 type => 'text' );

    eval_ok( sub { $s->add_relationship( table_from => $tc,
					 table_to   => $other,
					 cardinality => [ 1, 'n' ],
					 from_is_dependent => 0,
					 to_is_dependent => 0,
				       ) },
	     "Add a one to many relationship from two_col_pk to other" );

    my @cols;
    eval_ok( sub { @cols = $other->columns( 'pk1', 'pk2' ) },
	     "Retrieve pk1 and pk2 column objects from other" );

    my $fk;
    eval_ok( sub { $fk = $other->foreign_keys( table => $tc,
					       column => $tc->column('pk1') ) },
	     "Retrieve the foreign from other to two_col_pk" );

    @cols = $fk->columns_from;

    is( scalar @cols, 2,
	"Foreign key object columns_from should return two objects" );

    is( $cols[0]->name, 'pk1',
	"The first column object should be pk1" );

    is( $cols[1]->name, 'pk2',
	"The second column object should be pk2" );

    is( $cols[0]->table->name, 'other',
	"The first column should belong to the other table" );

    is( $cols[1]->table->name, 'other',
	"The second column should belong to the other table" );

    @cols = $fk->columns_to;

    is( scalar @cols, 2,
	"Foreign key object columns_to should return two objects" );

    is( $cols[0]->name, 'pk1',
	"The first column object should be pk1" );

    is( $cols[1]->name, 'pk2',
	"The second column object should be pk2" );

    is( $cols[0]->table->name, 'two_col_pk',
	"The first column should belong to the two_col_pk table" );

    is( $cols[1]->table->name, 'two_col_pk',
	"The second column should belong to the two_col_pk table" );

    my @pairs = $fk->column_pairs;

    is( scalar @pairs, 2,
	"column_pairs method should return a two value array" );

    is( $pairs[0]->[0]->table->name, 'other',
	"\$pairs[0]->[0] should belong to other" );

    is( $pairs[0]->[0]->name, 'pk1',
	"\$pairs[0]->[0] should be pk1" );

    is( $pairs[0]->[1]->table->name, 'two_col_pk',
	"\$pairs[0]->[1] should belong to two_col_pk" );

    is( $pairs[0]->[1]->name, 'pk1',
	"\$pairs[0]->[1] should be pk1" );

    is( $pairs[1]->[0]->table->name, 'other',
	"\$pairs[1]->[0] should belong to other" );

    is( $pairs[1]->[0]->name, 'pk2',
	"\$pairs[1]->[0] should be pk2" );

    is( $pairs[1]->[1]->table->name, 'two_col_pk',
	"\$pairs[1]->[1] should belong to two_col_pk" );

    is( $pairs[1]->[1]->name, 'pk2',
	"\$pairs[1]->[1] should be pk2" );

    my $tbi = $t1->make_column( name => 'tbi',
				type => 'int',
				nullable => 0 );

    my $index;
    eval_ok( sub { $index = $t1->make_index( columns => [ { column => $tbi } ] ) },
	     "Make an index on tbi column in footab" );

    eval_ok( sub { $t1->set_name('newt1') },
	     "Change footab's name to newt1" );

    eval{ $t1->set_name('bartab') };
    like( $@, qr/Table bartab already exists/,
          "Make sure two tables cannot have the same name" );

    my $index2;
    eval_ok( sub { $index2 = $t1->index($index->id) },
	     "Retrieve index object from table based on \$index->id" );

    is( $index, $index2,
	"The index retrieved from newt1 should be the same as the one made earlier");

    $t1->column('foo_pk')->alter( type => 'varchar',
				  length => 20 );
    if ($db eq 'MySQL')
    {
	ok( ! $t1->column('foo_pk')->attributes,
	    "The unsigned attribute should not have survived the change from 'int' to 'varchar'" );
    }

    if ($db eq 'MySQL')
    {
	eval { $t1->column('foo_pk')->set_type('text') };
	my $e = $@;
	isa_ok( $e, 'Alzabo::Exception::RDBMSRules',
		"Exception thrown from attempt to set a primary key column to the 'text' type" );
    }

    if ($db eq 'PostgreSQL')
    {
	eval { $t1->column('tbi')->set_attributes('unique') };
	ok( ! $@,
	    "Postgres should allow a column to have a UNIQUE attribute" );
    }

    $tbi->alter( type => 'varchar',
		 length => 20 );
    $tbi->set_type('text');

    ok( ! defined $tbi->length,
	"Length should be undef after switching column type from 'varchar' to 'text'" );

    $tbi->alter( type => 'varchar',
		 length => 20 );
    $tbi->set_type('char');
    ok( $tbi->length,
	"Length should remain defined after switching column type from 'varchar' to 'char'" );

    is( $tbi->length, 20,
	"Length should remain set to 20 after switching column type from 'varchar' to 'char'" );

    eval_ok( sub { my @t = $s->tables( qw( bartab baztab ) ) },
	     "Retrieving two tables via the schema's tables method" );

    eval_ok( sub { $s->move_table( table => $other,
				   before => $s->table('bartab') ) },
	     "Move other table before bartab" );

    my @t = $s->tables;
    my $order_ok = 0;
    for (my $x = 0; $x < @t; $x++)
    {
	if ($t[$x]->name eq 'other')
	{
	    $order_ok = 1 if $t[$x+1] && $t[$x+1]->name eq 'bartab';
	    last;
	}
    }
    ok( $order_ok,
	"The move_table method should actually move the tables" );

    eval_ok( sub { $other->move_column( column => $other->column('somethin'),
					before => $other->column('other_pk') ) },
	     "Move a column in the other table" );

    my @c = $other->columns;
    $order_ok = 0;
    for (my $x = 0; $x < @c; $x++)
    {
	if ($c[$x]->name eq 'somethin')
	{
	    $order_ok = 1 if $c[$x+1] && $c[$x+1]->name eq 'other_pk';
	    last;
	}
    }
    ok( $order_ok,
	"The move_column method should actually move the columns" );

    eval_ok( sub { $tbi->set_name('newname') },
	     "Set tbi column name to newname" );

    eval{ $tbi->set_name('foo_pk') };
    like( $@, qr/Column foo_pk already exists/,
          "Make sure two column cannot have the same name" );

    eval_ok( sub { $s->make_table( name => 'YAtable',
				   before => scalar $s->table('other') ) },
	     "Call the make_table method on the schema with a before parameter" );

    eval_ok( sub { $other->make_column( name => 'othertest',
					type => 'int',
					before => scalar $other->column('other_pk') ) },
	     "Call the make_column method with a before parameter" );

    eval { $other->make_column( name => 'bad name',
				type => 'int' ) };
    my $e = $@;
    isa_ok( $e, 'Alzabo::Exception::RDBMSRules',
	    "Exception thrown making a column with a bad name" );

    ok( $other->column('othertest')->is_numeric,
        "Should return true from is_numeric" );
    ok( $other->column('othertest')->is_integer,
        "Should return true from is_integer" );
    is( $other->column('othertest')->generic_type, 'integer',
        "Should return 'integer' from generic_type" );


    eval_ok( sub { $s->add_relationship( columns_from => [ $tc->primary_key ],
					 columns_to   => [ $other->primary_key ],
					 cardinality => [ 'n', 'n' ],
					 from_is_dependent => 0,
					 to_is_dependent => 0,
				       ) },
	     "Add a many to many relationship without specifying tables" );

    {
        my $s2 = Alzabo::Create::Schema->new( name => "foo_$db",
                                              rdbms => $db,
                                            );

        my $t1 = $s2->make_table( name => 't1' );
        my $t2 = $s2->make_table( name => 't2' );
        my $t3 = $s2->make_table( name => 't3' );

        $t1->make_column( name => 't1_pk',
                          type => 'integer',
                          primary_key => 1 );
        $t2->make_column( name => 't2_pk',
                          type => 'integer',
                          primary_key => 1 );
        $t3->make_column( name => 't3_pk',
                          type => 'integer',
                          primary_key => 1 );

        $s2->add_relationship( table_from => $t1,
                               table_to   => $t2,
                               cardinality => [ 'n', '1' ],
                               from_is_dependent => 0,
                               to_is_dependent => 0,
                             );

        $s2->add_relationship( table_from => $t3,
                               table_to   => $t2,
                               cardinality => [ 'n', '1' ],
                               from_is_dependent => 0,
                               to_is_dependent => 0,
                             );

        $t1->delete_column( $t1->column('t2_pk') );

        my @fk = $t2->all_foreign_keys;
        is( scalar @fk, 1,
            "t2 should still have one foreign key" );
    }

    # test for bug when creating a relationship between two tables,
    # where one table has a VARCHAR/CHAR PK.  bug caused length of
    # created column to be undef.
    {
        my $s2 = Alzabo::Create::Schema->new( name => "foo_$db",
                                              rdbms => $db,
                                            );

        my $t1 = $s2->make_table( name => 't1' );
        my $t2 = $s2->make_table( name => 't2' );
        my $t3 = $s2->make_table( name => 't3' );

        $t1->make_column( name   => 't1_pk',
                          type   => 'varchar',
                          length => 50,
                          primary_key => 1 );

        $t2->make_column( name => 't2_pk',
                          type => 'integer',
                          primary_key => 1 );


        eval_ok( sub { $s2->add_relationship( table_from  => $t1,
                                              table_to    => $t2,
                                              cardinality => [ '1', 'n' ],
                                              from_is_dependent => 0,
                                              to_is_dependent   => 0,
                                            ) },
                 'Add a relationship between two columns where one has a VARCHAR pk',
               );

        ok( $t2->column('t1_pk'), 't2 now has a column called t1_pk' );
    }

    {
        my $t = $s->make_table( name => 'no_pk_table' );

        $t->make_column( name => 'not_a_pk',
                         type => 'integer',
                       );

        eval_ok( sub { my $pk = $t->primary_key },
                 "Calling primary_key on a table without a primary key should not fail" );

        my @pk = $t->primary_key;
        is( scalar @pk, 0,
            "Return val from primary_key on a table without a primary key should be an empty list" );
    }

    {
        my $t1 = $s->make_table( name => 'fk_table1' );
        my $t2 = $s->make_table( name => 'fk_table2' );

        $t1->make_column( name => 'fk_table1_pk',
                          type => 'int',
                          primary_key => 1,
                        );

        $t2->make_column( name => 'fk_table2_pk',
                          type => 'int',
                          primary_key => 1,
                        );

        $t2->make_column( name => 'fk_table1_pk',
                          type => 'int',
                        );

        eval { $s->add_relationship( table_from => $t1,
                                     table_to   => $t2,
                                     cardinality => [ '1', 'n' ],
                                     from_is_dependent => 0,
                                     to_is_dependent => 1,
                                   ) };
        ok( ! $@,
            "call add_relationship where column in table_to already exists" );
    }

    if ( $db eq 'MySQL' )
    {
        $t1->set_attributes( 'TYPE = INNODB' );

        my @att = $t1->attributes;

        is( @att, 1, 't1 has 1 attribute' );
        is( $att[0], 'TYPE = INNODB', 'attribute is "TYPE = INNODB"' );

        my $att_t = $s->make_table( name => 'has_attributes',
                                    attributes =>
                                    [ 'TYPE = INNODB',
                                      'PACK_KEYS = 1 ' ],
                                  );

        @att = $att_t->attributes;

        is( @att, 2, 't1 has 2 attributes' );
        is( $att[0], 'TYPE = INNODB', 'first attribute is "TYPE = INNODB"' );
        is( $att[1], 'PACK_KEYS = 1', 'second attribute is "PACK_KEYS = 1"' );
    }
    else
    {
        $t1->set_attributes( 'WITH OIDS' );

        my @att = $t1->attributes;

        is( @att, 1, 't1 has 1 attribute' );
        is( $att[0], 'WITH OIDS', 'attribute is "WITH OIDS"' );

        my $att_t = $s->make_table( name => 'has_attributes',
                                    attributes =>
                                    [ 'WITH OIDS',
                                      'INHERITS footab' ],
                                  );

        @att = $att_t->attributes;

        is( @att, 2, 't1 has 2 attributes' );
        is( $att[0], 'WITH OIDS', 'first attribute is "WITH OIDS"' );
        is( $att[1], 'INHERITS footab', 'second attribute is "INHERITS footab"' );

        my $i;

        eval_ok( sub { $i = $tc->make_index( columns  => [ $tc->column('non_pk') ],
                                             function => 'LOWER(non_pk)',
                                           ) },
                 "make a function index" );

        is( $i->function, 'LOWER(non_pk)', "index function is LOWER(non_pk)" );
    }
}
