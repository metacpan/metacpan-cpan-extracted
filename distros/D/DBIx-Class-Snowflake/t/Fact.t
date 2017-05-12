use strict;
use warnings;

use Test::More tests => 48;
use Test::Exception;

use lib('t/lib');
use DBICTest;

my $schema      = DBICTest->init_schema();
my $rs          = $schema->resultset('FactA');
my $rs_b        = $schema->resultset('FactB');
my $gen_new_fact = sub { $rs->find( { 'fact_id' => 1 } ); };
my $gen_new_fact_b = sub { $rs_b->find( { 'fact_id' => 1 } ); };
my $give_rs     = sub { $rs; };
my $give_rs_b   = sub { $rs_b; };
my $factb = $rs_b->find( {'fact_id' => 1});

foreach my $give_test_subject (($gen_new_fact, $give_rs ))
{
	DBICTest::rst();
	test_generate_report_throws(&$give_test_subject());

	DBICTest::rst();
	test_can_ignore_columns(&$give_test_subject());

	DBICTest::rst();
	test_attributes(&$give_test_subject());

	DBICTest::rst();
	test_attrs(&$give_test_subject());

	DBICTest::rst();
	test_resolve_types(&$give_test_subject());

	DBICTest::rst();
	test_convert_joins(&$give_test_subject());

	DBICTest::rst();
	test_generate_report(&$give_test_subject());
}

foreach my $give_test_subject (($give_rs_b, $gen_new_fact_b))
{
	DBICTest::rst();
	test_generate_report_deeply(&$give_test_subject());

	DBICTest::rst();
	test_round_trip_report(&$give_test_subject());
}

sub test_can_ignore_columns
{
    my $dim = shift;
    can_ok($dim, 'ignore_columns');
}

sub test_attributes
{
    my $fact = shift;
    
    my $results = $fact->attributes();
    is_deeply(
        $results,
        [
            { 'name' => 'FactA.fact_id',        'type' => 'integer' },
            { 'name' => 'DimDate.date_id',      'type' => 'integer' },
            { 'name' => 'DimDate.day_of_week',  'type' => 'integer' },
            { 'name' => 'DimDate.day_of_month', 'type' => 'integer' },
            { 'name' => 'DimDate.day_of_year',  'type' => 'integer' },
            { 'name' => 'DimTime.time_id',      'type' => 'integer' },
            { 'name' => 'DimTime.hour',         'type' => 'integer' },
            { 'name' => 'DimTime.minute',       'type' => 'integer' },
            { 'name' => 'FactA.fact',           'type' => 'text' }
        ]
    );

    $fact->ignore_columns('fact_id');
    $results = $fact->attributes();
    is_deeply(
        $results,
        [
            { 'name' => 'DimDate.date_id',      'type' => 'integer' },
            { 'name' => 'DimDate.day_of_week',  'type' => 'integer' },
            { 'name' => 'DimDate.day_of_month', 'type' => 'integer' },
            { 'name' => 'DimDate.day_of_year',  'type' => 'integer' },
            { 'name' => 'DimTime.time_id',      'type' => 'integer' },
            { 'name' => 'DimTime.hour',         'type' => 'integer' },
            { 'name' => 'DimTime.minute',       'type' => 'integer' },
            { 'name' => 'FactA.fact',           'type' => 'text' },
        ]
    );

    $fact->ignore_columns('date_id');
    $results = $fact->attributes();
    is_deeply(
        $results,
        [
            { 'name' => 'FactA.fact_id',   'type' => 'integer' },
            { 'name' => 'DimTime.time_id', 'type' => 'integer' },
            { 'name' => 'DimTime.hour',    'type' => 'integer' },
            { 'name' => 'DimTime.minute',  'type' => 'integer' },
            { 'name' => 'FactA.fact',      'type' => 'text' },
        ]
    );
}

sub test_attrs
{
    my $fact = shift;
    is_deeply( $fact->attrs, $fact->attributes);
    $fact->ignore_columns('fact_id');
    is_deeply( $fact->attrs, $fact->attributes);
}

sub test_resolve_types
{
    my $fact = shift;

    my $check = { 'fact_id' => 1, 'fact' => 1, 'day_of_week' => 1 };
    my $results = $fact->_resolve_types( $check );
    is_deeply(
        $results,
        {
            'attributes' => { 'fact_id'     => 1, 'fact' => 1 },
            'dimensions' => { 'day_of_week' => 1 }
        }
    );
}

sub test_generate_report
{
    my $fact = shift;

    my $data = {
        'filters' => { 'DimTime.hour' => 2 },
        'metric'  => { 'DimTime.hour' => 1, 'DimDate.day_of_week' => 1, 'fact' => 1 }
    };
    my $results  = $fact->generate_report($data);
    my $expected = $fact->result_source->resultset->search(
        { 'me.time_id' => { 'in' => [ 2, 4 ] } },
        {
            'join'    => [ ['time_id'],    ['date_id'] ],
            '+select' => [ 'time_id.hour', 'date_id.day_of_week'  ],
            '+as'     => [ 'hour',         'day_of_week' ]
        }
    );
    my @e1 = $expected->get_column('day_of_week')->all();
    my @e2 = $expected->get_column('hour')->all();
    my @e3 = $expected->get_column('fact')->all();
    my @g1 = $expected->get_column('day_of_week')->all();
    my @g2 = $expected->get_column('hour')->all();
    my @g3 = $expected->get_column('fact')->all();
    is_deeply( \@g1, \@e1 );
    is_deeply( \@g2, \@e2 );
    is_deeply( \@g3, \@e3 );
}

sub test_round_trip
{
    my $fact = shift;
    my $attrs = $fact->attributes();

}

sub test_generate_report_deeply
{
    my $fact = shift;

    my $data = {
        'filters' => { 'DimCountry.country' => 'USA'  },
        'metric' => {
            'DimCity.city'        => 1,
            'DimRegion.region'    => 1,
            'DimCountry.country'  => 1,
            'DimDate.day_of_week' => 1
           }
    };
    my $results  = $fact->generate_report($data);
    my $expected = $fact->result_source->resultset->search(
        { 'me.city_id' =>  [ 1,2,3,4,5,6,7,8 ] },
        {
            'join' => [
                ['city_id'],
                { 'city_id' => [ 'region_id' ]},
                { 'city_id' => {'region_id' => [ 'country_id' ]}},
                ['date_id']
            ],
            '+select' => [
                'city_id.city',
                'region_id.region',
                'country_id.country',
                'date_id.day_of_week'
            ],
        }
    );
    my @e1 = $expected->get_column('date_id.day_of_week')->all();
    my @e2 = $expected->get_column('city_id.city')->all();
    my @e3 = $expected->get_column('region_id.region')->all();
    my @e4 = $expected->get_column('country_id.country')->all();

    my @g1 = $results->get_column('date_id.day_of_week')->all();
    my @g2 = $results->get_column('city_id.city')->all();
    my @g3 = $results->get_column('region_id.region')->all();
    my @g4 = $results->get_column('country_id.country')->all();

    is_deeply( \@g1, \@e1 );
    is_deeply( \@g2, \@e2 );
    is_deeply( \@g3, \@e3 );
    is_deeply( \@g4, \@e4 );
}

sub test_convert_joins
{
    my $fact = shift;

    is_deeply( $fact->_convert_joins([['a']]), [['a']]);
    is_deeply( $fact->_convert_joins([['a', 'b']]), [{'a' => ['b']}]);
    is_deeply( $fact->_convert_joins([['a', 'b', 'c']]), [{'a' => {'b' => ['c']}}]);
    is_deeply( $fact->_convert_joins([['a'], ['b']]), [['a'], ['b']]);
    is_deeply( $fact->_convert_joins([['a', 'b'], ['b']]), [{'a' => ['b']}, ['b']]);
}

sub test_round_trip_report
{
    my $fact = shift;

    my $attrs = $fact->attributes();

    my $data = {
        'filters' => { $attrs->[8]->{'name'} => 'USA'  },
        'metric' => {
            $attrs->[10]->{'name'} => 1,
            $attrs->[9]->{'name'}  => 1,
            $attrs->[7]->{'name'}  => 1,
            $attrs->[2]->{'name'}  => 1
           }
    };

    my $results  = $fact->generate_report($data);
    my $expected = $fact->result_source->resultset->search(
        { 'me.city_id' => { 'in' => [ 1,2,3,4,5,6,7,8 ] } },
        {
            'join' => [
                ['city_id'],
                { 'city_id' => [ 'region_id' ]},
                { 'city_id' => {'region_id' => [ 'country_id' ]}},
                ['date_id']
            ],
            '+select' => [
                'city_id.city',
                'region_id.region',
                'country_id.country',
                'date_id.day_of_week'
            ],
            '+as' => [ 'city', 'region', 'country', 'day_of_week' ]
        }
    );
    my @e1 = $expected->get_column('day_of_week')->all();
    my @e2 = $expected->get_column('city_id.city')->all();
    my @e3 = $expected->get_column('region_id.region')->all();
    my @e4 = $expected->get_column('country_id.country')->all();
    my @g1 = $results->get_column('day_of_week')->all();
    my @g2 = $results->get_column('city_id.city')->all();
    my @g3 = $results->get_column('region_id.region')->all();
    my @g4 = $results->get_column('country_id.country')->all();
    is_deeply( \@g1, \@e1 );
    is_deeply( \@g2, \@e2 );
    is_deeply( \@g4, \@e4 );
}

sub test_generate_report_throws
{
    my $fact = shift;
    my $attr = 'this_doesn\'t_exist';

    my $data = {  $attr => 1  } ;

    throws_ok(
        sub {
            my $guard = $schema->txn_scope_guard;
            $fact->generate_report({ 'filters' => $data});
        },
        qr/Unable to resolve dimension '$attr', does not exist in snowflake./,
        'Unknown filter propogated ok.'
    );

    throws_ok(
        sub {
            my $guard = $schema->txn_scope_guard;
            $fact->generate_report({ 'metric' => $data});
        },
        qr/Unable to resolve dimension '$attr', does not exist in snowflake./,
        'Unknown metric propogated ok.'
    );
}

1;
