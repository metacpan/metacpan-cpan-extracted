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

plan tests => 106;


Alzabo::Test::Utils->remove_all_schemas;


use Alzabo::Create::Schema;
use Alzabo::Runtime::Schema;
require Alzabo::MethodMaker;


# doesn't matter which RDBMS is used
my $rdbms = $rdbms_names[0];

my $config = Alzabo::Test::Utils->test_config_for($rdbms);


# these tests use a different schema than the other live DB tests
make_methodmaker_schema(%$config);


Alzabo::MethodMaker->import( schema => $config->{schema_name},
			     all => 1,
			     class_root => 'Alzabo::MM::Test',
			     name_maker => \&namer,
			   );

my $s = Alzabo::Runtime::Schema->load_from_file( name => $config->{schema_name} );


eval { $s->docs_as_pod };
ok( ! $@, 'docs_as_pod should not cause an exception' );


foreach my $t ($s->tables)
{
    my $t_meth = $t->name . '_t';
    ok( $s->can($t_meth),
	"Schema object should have $t_meth method" );

    is( $s->$t_meth(), $t,
	"Results of \$s->$t_meth() should be same as existing table object" );

    foreach my $c ($t->columns)
    {
	my $c_meth = $c->name . '_c';
	ok( $t->can($c_meth),
	    "Table object should have  $t_meth method" );

	is( $t->$c_meth(), $c,
	    "Results of \$t->$c_meth() should be same as existing column object" );
    }
}

ok( Alzabo::MM::Test::Row::Toilet->can('NotLinkings'),
    "Toilet should method to fetch NotLinking rows" );

ok( Alzabo::MM::Test::Row::Location->can('NotLinkings'),
    "Location should method to fetch NotLinking rows" );

isa_ok( $s->Toilet_t, 'Alzabo::MM::Test::Table' );

{
    $s->connect( Alzabo::Test::Utils->connect_params_for($rdbms) );

    $s->set_referential_integrity(1);

    # needed for Pg!
    $s->set_quote_identifiers(1);

    my $char = 'a';
    my $loc1 = $s->Location_t->insert( values => { location_id => 1,
						   location => $a++ } );

    isa_ok( $loc1, 'Alzabo::MM::Test::Row' );

    $s->Location_t->insert( values => { location_id => 2,
					location => $a++,
					parent_location_id => 1 } );
    $s->Location_t->insert( values => { location_id => 3,
					location => $a++,
					parent_location_id => 1 } );
    $s->Location_t->insert( values => { location_id => 4,
					location => $a++,
					parent_location_id => 2 } );
    my $loc5 = $s->Location_t->insert( values => { location_id => 5,
						   location => $a++,
						   parent_location_id => 4 } );

    ok( ! defined $loc1->parent,
	"First location should not have a parent" );

    my @c = $loc1->children( order_by => $s->Location_t->location_id_c ) ->all_rows;
    is( scalar @c, 2,
	"First location should have 2 children" );

    is( $c[0]->location_id, 2,
	"First child location id should be 2" );

    is( $c[1]->location_id, 3,
	"Second child location id should be 3" );

    is( $loc5->parent->location_id, 4,
	"Location 5's parent should be 4" );

    $loc1->location('Set method');
    is( $loc1->location, 'Set method',
	"Update location column via ->location method" );
}

{
    eval { $s->Location_t->insert( values => { location_id => 666,
					       location => 'pre_die' } ) };
    my $e = $@;
    isa_ok( $e, 'Alzabo::Exception',
	    "Exception thrown from pre_insert" );
    is( $e->error, 'PRE INSERT TEST',
	"pre_insert error message should be PRE INSERT TEST" );

    eval { $s->Location_t->insert( values => { location_id => 666,
					       location => 'post_die' } ) };
    $e = $@;
    isa_ok( $e, 'Alzabo::Exception',
	    "Exception thrown by post_insert" );
    is( $e->error, 'POST INSERT TEST',
	"pre_insert error message should be POST INSERT TEST" );

    my $tweaked = $s->Location_t->insert( values => { location_id => 54321,
						      location => 'insert tweak me' } );
    is ( $tweaked->select('location'), 'insert tweaked',
	 "pre_insert should change the value of location to 'insert tweaked'" );

    eval { $tweaked->update( location => 'pre_die' ) };
    $e = $@;
    isa_ok( $e, 'Alzabo::Exception',
	    "Exception thrown from pre_update" );
    is( $e->error, 'PRE UPDATE TEST',
	"pre_update error message should be PRE UPDATE TEST" );

    eval { $tweaked->update( location => 'post_die' ) };
    $e = $@;
    isa_ok( $e, 'Alzabo::Exception',
	    "Exception thrown by post_update" );
    is( $e->error, 'POST UPDATE TEST',
	"post_update error message should be POST UPDATE TEST" );

    $tweaked->update( location => 'update tweak me' );
    is ( $tweaked->select('location'), 'update tweaked',
	 "pre_update should change the value of location to 'update tweaked'" );

    eval { $tweaked->select('pre_sel_die') };
    $e = $@;
    isa_ok( $e, 'Alzabo::Exception',
	    "Exception thrown by pre_select" );
    is( $e->error, 'PRE SELECT TEST',
	"pre_select error message should be PRE SELECT TEST" );

    $tweaked->update( location => 'post_sel_die' );

    eval { $tweaked->select('location') };
    $e = $@;
    isa_ok( $e, 'Alzabo::Exception',
	    "Exception thrown by post_select" );
    is( $e->error, 'POST SELECT TEST',
	"post_select error message should be POST SELECT TEST" );

    eval { $tweaked->select_hash('location') };
    $e = $@;
    isa_ok( $e, 'Alzabo::Exception',
	    "Exception thrown by post_select" );
    is( $e->error, 'POST SELECT TEST',
	"post_select error message should be POST SELECT TEST" );

    $tweaked->update( location => 'select tweak me' );
    is( $tweaked->select('location'), 'select tweaked',
	 "post_select should change the value of location to 'select tweaked'" );

    my %d = $tweaked->select_hash('location');
    is( $d{location}, 'select tweaked',
	 "post_select_hash should change the value of location to 'select tweaked'" );

    $s->ToiletType_t->insert( values => { toilet_type_id => 1,
					  material => 'porcelain',
					  quality => 5 } );
    my $t = $s->Toilet_t->insert( values => { toilet_id => 1,
					      toilet_type_id => 1 } );

    is( $t->material, 'porcelain',
	"New toilet's material method should return 'porcelain'" );
    is( $t->quality, 5,
	"New toilet's quality method should return 5" );

    $s->Location_t->insert( values => { location_id => 100,
					location => '# 100!' } );
    $s->ToiletLocation_t->insert( values => { toilet_id => 1,
					      location_id => 100 } );

    $s->ToiletLocation_t->insert( values => { toilet_id => 1,
					      location_id => 1 } );

    my @l = $t->Locations( order_by => $s->Location_t->location_id_c )->all_rows;

    is( scalar @l, 2,
	"The toilet should have two locations" );

    is( $l[0]->location_id, 1,
	"The first location id should be 1" );

    is( $l[1]->location_id, 100,
	"The second location id should be 2" );

    my @t = $l[0]->Toilets->all_rows;
    is( scalar @t, 1,
	"The location should have one toilet" );

    is( $t[0]->toilet_id, 1,
	"Location's toilet id should be 1" );

    my @tl = $t->ToiletLocations( order_by => $s->ToiletLocation_t->location_id_c )->all_rows;

    is( scalar @tl, 2,
	"The toilet should have two ToiletLocation rows" );

    is( $tl[0]->location_id, 1,
	"First row's location id should be 1" );
    is( $tl[0]->toilet_id, 1,
	"First row's toilet id should 1" );
    is( $tl[1]->location_id, 100,
 	"Second row's location id should be 100" );
    is( $tl[1]->toilet_id, 1,
	"Second row's toilet id should 1" );

    my $row = $s->Toilet_t->row_by_pk( pk => 1 );
    isa_ok( $row, 'Alzabo::MM::Test::Row::Toilet',
	    "The Toilet object" );

    my $p_row = $s->Location_t->potential_row;
    isa_ok( $p_row, 'Alzabo::MM::Test::Row::Location',
	    "Potential row object" );

    $p_row->location( 'zzz' );
    $p_row->location_id( 999 );
    is( $p_row->location_id, 999,
 	"location_id of potential object should be 99" );
    is( $p_row->location, 'zzz',
 	"Location name of potential object should be 'zzz'" );

    eval { $p_row->update( location => 'pre_die' ); };
    $e = $@;
    isa_ok( $e, 'Alzabo::Exception',
	    "Exception thrown by pre_update" );

    eval { $p_row->update( location => 'post_die' ); };
    $e = $@;
    isa_ok( $e, 'Alzabo::Exception',
	    "Exception thrown by post_update" );

    $p_row->update( location => 'update tweak me' );
    is ( $p_row->select('location'), 'update tweaked',
	 "pre_update should change the value of location to 'update tweaked'" );

    eval { $p_row->select('pre_sel_die') };
    $e = $@;
    isa_ok( $e, 'Alzabo::Exception',
	    "Exception thrown by pre_select" );

    $p_row->update( location => 'select tweak me' );
    is( $p_row->select('location'), 'select tweaked',
	 "post_select should change the value of location to 'select tweaked'" );

    %d = $p_row->select_hash('location');
    is( $d{location}, 'select tweaked',
	 "post_select_hash should change the value of location to 'select tweaked'" );

    $p_row->make_live;
    is( $p_row->location_id, 999,
	"Check that live row has same location id" );

    my $alias = $s->Toilet_t->alias;

    can_ok( $alias, 'toilet_id_c' );
    is( $alias->toilet_id_c->name, $s->Toilet_t->toilet_id_c->name,
	"Alias column has the same name as real table's column" );
    is( $alias->toilet_id_c->table, $alias,
	"The alias column's table should be the alias" );

    # self-linking
    {
        $s->Toilet_t->insert( values =>
                              { toilet_id => $_,
                                toilet_type_id => 1,
                              } ) for ( 100 .. 110 );

        $s->ToiletToilet_t->insert( values =>
                                    { toilet_id => 100,
                                      toilet_id_2 => 106,
                                    } );

        $s->ToiletToilet_t->insert( values =>
                                    { toilet_id => 100,
                                      toilet_id_2 => 107,
                                    } );

        $s->ToiletToilet_t->insert( values =>
                                    { toilet_id => 101,
                                      toilet_id_2 => 106,
                                    } );

        $s->ToiletToilet_t->insert( values =>
                                    { toilet_id => 102,
                                      toilet_id_2 => 107,
                                    } );

        {
            my $t100 = $s->Toilet_t->row_by_pk( pk => 100 );

            my @child_ids = sort map { $_->toilet_id } $t100->child_toilets->all_rows;

            is( @child_ids, 2, 'there should be two children' );
            is( $child_ids[0], 106, 'first child is 106' );
            is( $child_ids[1], 107, 'second child is 107' );
        }

        {
            my $t106 = $s->Toilet_t->row_by_pk( pk => 106 );

            my @parent_ids = sort map { $_->toilet_id } $t106->parent_toilets->all_rows;

            is( @parent_ids, 2, 'there should be two parents' );
            is( $parent_ids[0], 100, 'first parent is 100' );
            is( $parent_ids[1], 101, 'second parent is 101' );
        }

        {
            my $t107 = $s->Toilet_t->row_by_pk( pk => 107 );

            my @parent_ids = sort map { $_->toilet_id } $t107->parent_toilets->all_rows;

            is( @parent_ids, 2, 'there should be two parents' );
            is( $parent_ids[0], 100, 'first parent is 100' );
            is( $parent_ids[1], 102, 'second parent is 102' );
        }
    }
}

sub make_methodmaker_schema
{
    my %p = @_;

    my %r = ( mysql => 'MySQL',
	      pg => 'PostgreSQL',
	    );

    my $s = Alzabo::Create::Schema->new( name => $p{schema_name},
					 rdbms => $r{ delete $p{rdbms} },
				       );
    my $loc = $s->make_table( name => 'Location' );

    $loc->make_column( name => 'location_id',
		       type => 'int',
		       primary_key => 1 );
    $loc->make_column( name => 'parent_location_id',
		       type => 'int',
		       nullable => 1 );
    $loc->make_column( name => 'location',
		       type => 'varchar',
		       length => 50 );

    # self relation
    $s->add_relationship( columns_from => $loc->column('parent_location_id'),
                          columns_to => $loc->column('location_id'),
                          cardinality => [ 'n', 1 ],
                          from_is_dependent => 0,
                          to_is_dependent => 0,
                        );

    my $toi = $s->make_table( name => 'Toilet' );

    $toi->make_column( name => 'toilet_id',
		       type => 'int',
		       primary_key => 1 );

    # linking table
    $s->add_relationship( table_from => $toi,
                          table_to => $loc,
                          cardinality => [ 'n', 'n' ],
                          from_is_dependent => 0,
                          to_is_dependent => 0,
                        );

    # not a linking table (for MethodMaker), because it will have an
    # extra column
    $s->add_relationship( table_from => $loc,
                          table_to => $toi,
                          cardinality => [ 'n', 'n' ],
                          from_is_dependent => 0,
                          to_is_dependent => 0,
                        );

    $s->table('LocationToilet')->set_name('NotLinking');
    $s->table('NotLinking')->make_column( name => 'extra_column',
                                          type => 'int' );


    my $toi_toi = $s->make_table( name => 'ToiletToilet' );

    $toi_toi->make_column( name => 'toilet_id',
                           type => 'int',
                           primary_key => 1 );
    $toi_toi->make_column( name => 'toilet_id_2',
                           type => 'int',
                           primary_key => 1 );

    # linking table between Toilet & Toilet (self-linking)
    $s->add_relationship( columns_from => $toi->column('toilet_id'),
                          columns_to   => $toi_toi->column('toilet_id'),
                          cardinality  => [ '1', 'n' ],
                          from_is_dependent => 0,
                          to_is_dependent => 0,
                        );
    $s->add_relationship( columns_from => $toi->column('toilet_id'),
                          columns_to   => $toi_toi->column('toilet_id_2'),
                          cardinality  => [ '1', 'n' ],
                          from_is_dependent => 0,
                          to_is_dependent => 0,
                        );

    my $tt = $s->make_table( name => 'ToiletType' );

    $tt->make_column( name => 'toilet_type_id',
		      type => 'int',
		      primary_key => 1 );
    $tt->make_column( name => 'material',
		      type => 'varchar',
		      length => 50 );
    $tt->make_column( name => 'quality',
		      type => 'int',
		      nullable => 1 );
    # lookup table
    $s->add_relationship( table_from => $toi,
                          table_to => $tt,
                          cardinality => [ 'n', 1 ],
                          from_is_dependent => 0,
                          to_is_dependent => 0,
                        );

    $s->save_to_file;

    delete @p{ 'schema_name', 'rdbms' };
    $s->create(%p);
}

sub namer
{
    my %p = @_;

    return $p{table}->name . '_t' if $p{type} eq 'table';

    return $p{column}->name . '_c' if $p{type} eq 'table_column';

    return $p{column}->name if $p{type} eq 'row_column';

    if ( $p{type} eq 'foreign_key' )
    {
	my $name = $p{foreign_key}->table_to->name;
	if ($p{plural})
	{
            my $name = my_PL( $name );

	    return if $name eq 'ToiletToilets';

            return $name;
	}
	else
	{
            return
                if $name eq 'Toilet' && $p{foreign_key}->table_from->name eq 'ToiletToilet';

	    return $name;
	}
    }

    if ( $p{type} eq 'linking_table' )
    {
        if ( $p{foreign_key}->table_from eq $p{foreign_key_2}->table_to )
        {
            if ( ($p{foreign_key}->columns_to)[0]->name eq 'toilet_id' )
            {
                return 'child_toilets';
            }
            else
            {
                return 'parent_toilets';
            }
        }

	my $method = $p{foreign_key}->table_to->name;
	my $tname = $p{foreign_key}->table_from->name;
	$method =~ s/^$tname\_?//;
	$method =~ s/_?$tname$//;

	return my_PL($method);
    }

    if ( $p{type} eq 'lookup_columns' )
    {
        return if $p{column}->table->name eq 'Toilet' && $p{column}->name eq 'toilet_type_id';

        return $p{column}->name;
    }

    return $p{column}->name if $p{type} eq 'lookup_columns';

    return $p{parent} ? 'parent' : 'children'
	if $p{type} eq 'self_relation';

    die "unknown type in call to naming sub: $p{type}\n";
}

sub my_PL
{
    return shift() . 's';
}

{
    package Alzabo::MM::Test::Table::Location;
    sub pre_insert
    {
	my $self = shift;
	my $p = shift;
	Alzabo::Exception->throw( error => "PRE INSERT TEST" ) if $p->{values}->{location} eq 'pre_die';

	$p->{values}->{location} = 'insert tweaked' if $p->{values}->{location} eq 'insert tweak me';
    }

    sub post_insert
    {
	my $self = shift;
	my $p = shift;
	Alzabo::Exception->throw( error => "POST INSERT TEST" ) if $p->{row}->select('location') eq 'post_die';
    }
}

{
    package Alzabo::MM::Test::Row::Location;
    sub pre_update
    {
	my $self = shift;
	my $p = shift;
	Alzabo::Exception->throw( error => "PRE UPDATE TEST" ) if $p->{location} && $p->{location} eq 'pre_die';

	$p->{location} = 'update tweaked' if $p->{location} && $p->{location} eq 'update tweak me';
    }

    sub post_update
    {
	my $self = shift;
	my $p = shift;
	Alzabo::Exception->throw( error => "POST UPDATE TEST" ) if $p->{location} && $p->{location} eq 'post_die';
    }

    sub pre_select
    {
	my $self = shift;
	my $cols = shift;

	Alzabo::Exception->throw( error => "PRE SELECT TEST" ) if grep { $_ eq 'pre_sel_die' } @$cols;
    }

    sub post_select
    {
	my $self = shift;
	my $data = shift;

	Alzabo::Exception->throw( error => "POST SELECT TEST" ) if exists $data->{location} && $data->{location} eq 'post_sel_die';

	$data->{location} = 'select tweaked' if exists $data->{location} && $data->{location} eq 'select tweak me';
    }

    sub pre_delete
    {
	my $self = shift;
	Alzabo::Exception->throw( error => "PRE DELETE TEST" ) if $self->select('location') eq 'pre_del_die';
    }

    sub post_delete
    {
	my $self = shift;
#	Alzabo::Exception->throw( error => "POST DELETE TEST" );
    }
}

1;
