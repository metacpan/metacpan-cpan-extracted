use Test::More;
use strict;

use lib 't/lib';

use FakeResultSet;
use FakeRow;

use DBIx::Class::ResultSet::Faceter;

my $date1 = DateTime->now;
my $date2 = DateTime->now->add(days => 1);

my $resultset = FakeResultSet->new(
    rows => [
        FakeRow->new(
            name_last => 'Watson',
            date_created => $date1,
        ),
        FakeRow->new(
            name_last => 'Smith',
            date_created => $date1,
        ),
        FakeRow->new(
            name_last => 'Watson',
            date_created => $date1,
        ),
        FakeRow->new(
            name_last => 'Watson',
            date_created => $date1,
        ),
		FakeRow->new (
			name_last => 'Brown',
            date_created => $date2,
		),
		FakeRow->new (
			name_last => 'Brown',
            date_created => $date2,
		)
    ]
);

{
    my $faceter = DBIx::Class::ResultSet::Faceter->new;
    $faceter->add_facet('Column', { name => 'Last Name', column => 'name_last' });
    my $results = $faceter->facet($resultset);

	is_deeply([ { Watson => 3 }, { Brown => 2 }, { Smith => 1 } ], $results->get('Last Name'), 'last name default');
}

$resultset->reset;

{
    my $faceter = DBIx::Class::ResultSet::Faceter->new;
    $faceter->add_facet('Column', { name => 'Date Created', column => 'date_created.ymd' });
    my $results = $faceter->facet($resultset);

	is_deeply([ { $date1->ymd => 4 }, { $date2->ymd => 2 } ], $results->get('Date Created'), 'date created method');
}

done_testing;