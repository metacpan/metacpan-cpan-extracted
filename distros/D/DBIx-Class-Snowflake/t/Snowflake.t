use strict;
use warnings;

use lib('t/lib');
use Test::More 'tests' => 56;
use Test::Exception;
use DBICTest;

my $schema       = DBICTest->init_schema();
my $rs           = $schema->resultset('FactA');
my $gen_new_fact = sub { $rs->find( { 'fact_id' => 1 } ) };
my $give_rs      = sub { $rs };

foreach my $give_test_subject (($gen_new_fact, $give_rs))
{
    DBICTest::rst();
    test_can_ignore_column( &$give_test_subject() );
    DBICTest::rst();
    test_can_make_ignore_hash( &$give_test_subject() );
    DBICTest::rst();
    test_ignore_column_with_string( &$give_test_subject() );
    DBICTest::rst();
    test_ignore_column_with_array( &$give_test_subject() );
    DBICTest::rst();
    test_ignore_column_with_hash( &$give_test_subject() );
    DBICTest::rst();
    test_ignore_column_with_scalar_ref( &$give_test_subject() );
    DBICTest::rst();
    test_ignore_column_with_sub_ref( &$give_test_subject() );
    DBICTest::rst();
    test_ignore_column_with_bad_ref( &$give_test_subject() );
    DBICTest::rst();

    test_resolve_metrics( &$give_test_subject() );
    DBICTest::rst();
    test_resolve_metrics_with_ignore( &$give_test_subject() );
    DBICTest::rst();

    test_resolve_dimension_to_attribute( &$give_test_subject() );
    DBICTest::rst();
    test_resolve_dimension_to_attribute_with_ignore( &$give_test_subject() );
    DBICTest::rst();

    test_dims_or_attrs( &$give_test_subject() );
    DBICTest::rst();

    test_columns_as_hash( &$give_test_subject() );
    DBICTest::rst();
}

sub test_can_ignore_column
{
    my $fact = shift;
    can_ok($fact, 'ignore_columns');
}

sub test_can_make_ignore_hash
{
    my $fact = shift;
    can_ok($fact, '_make_ignore_hash');
}

sub test_ignore_column_with_bad_ref
{
    my $fact = shift;
    throws_ok(
        sub 
        {
            my $guard = $schema->txn_scope_guard;
            $fact->_make_ignore_hash($fact);
        },
        qr/Unable to determine what columns to ignore, I don't know what to do with a/);
}

sub test_ignore_column_with_string
{
    my $to_ignore = 'fact_id';
    my $fact = shift;
    is_deeply($fact->_make_ignore_hash($to_ignore), { $to_ignore => 1 });
}

sub test_ignore_column_with_array
{
    my @to_ignore = (qw/fact_id date_id/);
    my $fact = shift;
    my %ignored_hash = map { $_ => 1 } @to_ignore;
    is_deeply($fact->_make_ignore_hash(\@to_ignore), \%ignored_hash);
}

sub test_ignore_column_with_hash
{
    my $fact = shift;
    my %to_ignore = ('fact_id' => 1, 'date_id' => 1);
    is_deeply($fact->_make_ignore_hash(\%to_ignore), \%to_ignore);
}

sub test_ignore_column_with_scalar_ref
{
    my $fact = shift;
    my $to_ignore = 'fact_id';
    is_deeply($fact->_make_ignore_hash(\$to_ignore), { $to_ignore => 1 });
}

sub test_ignore_column_with_sub_ref
{
    my $fact = shift;
    my $to_ignore = 'fact_id';
    my $ignore_func = sub { return ( $to_ignore => 1 ); };
    is_deeply($fact->_make_ignore_hash($ignore_func), { $to_ignore => 1 });
}

sub test_resolve_metrics
{
    my $fact = shift;
    $fact->ignore_columns(undef);

    my $results = $fact->_resolve_metrics('fact_id');
    is_deeply($results, [ 'fact_id' ]);

    $results = $fact->_resolve_metrics('DimDate.day_of_week');
    is_deeply($results, [ 'date_id', 'date_id.day_of_week' ]);

    $results = $fact->_resolve_metrics('day_of_cheese');
    is_deeply($results, undef);
}

sub test_resolve_metrics_with_ignore
{
    my $fact = shift;
    my $results;

    $fact->ignore_columns('fact_id');
    $results = $fact->_resolve_metrics('fact_id');
    is_deeply( $results, undef);

    # make sure it can still resolve other metrics
    $fact->ignore_columns(undef);
    $results = $fact->_resolve_metrics('DimDate.day_of_week');
    is_deeply($results, [ 'date_id', 'date_id.day_of_week' ]);

    $fact->ignore_columns('date_id');
    $results = $fact->_resolve_metrics('DimDate.day_of_week');
    is_deeply( $results, undef );

    # make sure setting to undef worked
    $fact->ignore_columns(undef);
    $results = $fact->_resolve_metrics('DimDate.day_of_week');
    is_deeply($results, [ 'date_id', 'date_id.day_of_week' ]);

    DBICTest::DimDate->ignore_columns('day_of_week');
    $results = $fact->_resolve_metrics('DimDate.day_of_week');
    is_deeply( $results, undef );
}

sub test_resolve_dimension_to_attribute
{
    my $fact = shift;
    my $results;

    $results = $fact->_resolve_dimension_to_attribute('fact_id', 1);
    is_deeply( $results, { 'me.fact_id' => [1]} );

    $results = $fact->_resolve_dimension_to_attribute('DimTime.hour', 14);
    is_deeply( $results, { 'me.time_id' => [1]} );

    $results = $fact->_resolve_dimension_to_attribute('DimTime.hour', 7);
    is_deeply( $results, {'me.time_id' => [3]} );

    $results = $fact->_resolve_dimension_to_attribute('DimTime.hour', 2);
    is_deeply( $results, { 'me.time_id' => [2, 4] } );
}

sub test_resolve_dimension_to_attribute_with_ignore
{
    my $fact = shift;
    my $results;

    $fact->ignore_columns('fact_id');
    $results = $fact->_resolve_dimension_to_attribute('fact_id', 1);
    is_deeply( $results, undef );

    $fact->ignore_columns('time_id');
    $results = $fact->_resolve_dimension_to_attribute('DimTime.hour', 14);
    is_deeply( $results, undef );

    DBICTest::DimTime->ignore_columns('hour');
    $results = $fact->_resolve_dimension_to_attribute('DimTime.hour', 7);
    is_deeply( $results, undef );

    # test to make sure that ignoring an unrelated column doesn't
    # affect the search
    $results = $fact->_resolve_dimension_to_attribute('fact_id', 1);
    is_deeply( $results, { 'me.fact_id' => [1]} );
}

sub test_dims_or_attrs
{
    my $fact = shift;
    my $results;

    $results = $fact->attributes();
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
            { 'name' => 'FactA.fact',           'type' => 'text' },
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

sub test_columns_as_hash
{
    my $fact = shift;
    my %results;

    %results = $fact->_columns_as_hash();
    is_deeply( \%results, { 'fact_id' => 1, 'date_id' => 1, 'time_id' => 1, 'fact' => 1});
}
