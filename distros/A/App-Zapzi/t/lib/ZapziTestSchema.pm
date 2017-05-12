package ZapziTestSchema;

use Test::Most;
use Test::DBIx::Class::Schema;

sub test
{
    my ($self, $schema, $table, $columns, $relations) = @_;

    # Create a new test object
    my $schematest = Test::DBIx::Class::Schema->new(
        {
            schema    => $schema,
            namespace => 'App::Zapzi::Database::Schema',
            moniker   => $table,
            test_missing => 1,
        }
        );

    # Tell it what to test
    $schematest->methods(
        {
            columns => $columns,
            relations => $relations,
            custom => [],
            resultsets => []
        }
        );

    # Run the tests
    $schematest->run_tests();
}

1;
