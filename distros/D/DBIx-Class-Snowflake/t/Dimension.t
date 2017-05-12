use strict;
use warnings;

use lib('t/lib');

use Test::More 'tests' => 10;
use DBICTest;

my $schema      = DBICTest->init_schema();
my $rs          = $schema->resultset('DimDate');
my $gen_new_dim = sub { $rs->find( { 'date_id' => 1 } ); };
my $give_rs     = sub { $rs; };

foreach my $give_test_subject (($gen_new_dim, $give_rs))
{
	DBICTest::rst();
	test_can_ignore_columns(&$gen_new_dim());
	DBICTest::rst();
	test_attributes(&$gen_new_dim());
	DBICTest::rst();
	test_attrs(&$gen_new_dim());
}

sub test_can_ignore_columns
{
    my $dim = shift;
    can_ok($dim, 'ignore_columns');
}

sub test_attributes
{
    my $dim = shift;
    
    my $results = $dim->attributes();
    is_deeply(
        $results,
        [
            { 'name' => 'DimDate.date_id',      'type' => 'integer' },
            { 'name' => 'DimDate.day_of_week',  'type' => 'integer' },
            { 'name' => 'DimDate.day_of_month', 'type' => 'integer' },
            { 'name' => 'DimDate.day_of_year',  'type' => 'integer' },
        ]
       );

    $dim->ignore_columns('date_id');
    $results = $dim->attributes();
    is_deeply(
        $results,
        [
            { 'name' => 'DimDate.day_of_week',  'type' => 'integer' },
            { 'name' => 'DimDate.day_of_month', 'type' => 'integer' },
            { 'name' => 'DimDate.day_of_year',  'type' => 'integer' },
        ]
       );
}

sub test_attrs
{
    my $dim = shift;
    is_deeply( $dim->attrs, $dim->attributes);
    $dim->ignore_columns('date_id');
    is_deeply( $dim->attrs, $dim->attributes);
}
