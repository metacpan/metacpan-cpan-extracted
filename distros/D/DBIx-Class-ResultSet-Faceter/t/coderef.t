use Test::More;
use strict;

use lib 't/lib';

use FakeResultSet;
use FakeRow;

use DBIx::Class::ResultSet::Faceter;

my $resultset = FakeResultSet->new(
    rows => [
        FakeRow->new(
            name_last => 'Watson',
        ),
        FakeRow->new(
            name_last => 'Smith',
        ),
        FakeRow->new(
            name_last => 'Watson',
        ),
        FakeRow->new(
            name_last => 'Watson',
        ),
        FakeRow->new (
            name_last => 'Brown',
        ),
        FakeRow->new (
            name_last => 'Brown',
        )
    ]
);

{
    my $faceter = DBIx::Class::ResultSet::Faceter->new;
    $faceter->add_facet('CodeRef', {
        name => 'Last Name',
        code => sub { substr(shift->name_last, 1, 1) }
    });
    my $results = $faceter->facet($resultset);

	is_deeply([ { a => 3 }, { r => 2 }, { m => 1 } ], $results->get('Last Name'), 'last name substr');
}

done_testing;