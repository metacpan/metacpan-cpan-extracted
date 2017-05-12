use Test::More;
use strict;

use lib 't/lib';

use FakeResultSet;
use FakeRow;

use DBIx::Class::ResultSet::Faceter;

my $resultset = FakeResultSet->new(
    rows => [
		{
            name_last => 'Watson'
        }, {
            name_last => 'Smith'
        }, {
            name_last => 'Watson'
        }, {
            name_last => 'Watson'
        }, {
			name_last => 'Brown'
		}, {
			name_last => 'Brown'
		}
    ]
);

{
    my $faceter = DBIx::Class::ResultSet::Faceter->new;
    $faceter->add_facet('HashRef', { name => 'Last Name', key => 'name_last' });
    my $results = $faceter->facet($resultset);

	is_deeply([ { Watson => 3 }, { Brown => 2 }, { Smith => 1 } ], $results->get('Last Name'), 'last name default');
}

done_testing;