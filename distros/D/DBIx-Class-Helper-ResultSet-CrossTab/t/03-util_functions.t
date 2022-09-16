use strict;
use warnings;

use Test::More;

use DBIx::Class::Helper::ResultSet::CrossTab;

use lib './t/lib';

use Test::DBIx::Class {
    schema_class => 'Test::Schema',
	connect_info => ['dbi:SQLite:dbname=:memory:','',''],
	connect_opts => { name_sep => '.', quote_char => '`', },
        fixture_class => '::Populate',
    }, 'Sales';

open STDIN, 't/test_data.txt' || die "no test data";
my @lines = map { [ split /\t/ ] } split /\n/, do { local $/; <STDIN> };


my $dbh = Schema->storage->dbh;

fixtures_ok [ 
	     Sales => [
		       [qw/fruit country channel units price discount/],
		       @lines
		      ],
    ], 'Installed some custom fixtures via the Populate fixture class';

my $tests = [
	       "avg( CASE WHEN channel='wholesale' then (units) ELSE NULL END)",
	       "round(avg( CASE WHEN channel='wholesale' then (units) ELSE NULL END), 0)",
	       "round(avg( CASE WHEN channel='wholesale' then (units + 10) ELSE NULL END), 0)",
	       "round(avg( CASE WHEN channel='wholesale' then (units + (10 - 2)) ELSE NULL END), 0)",
	       "round(avg( CASE WHEN channel='wholesale' then (units * price) ELSE NULL END), 0)",
	       "round(avg( CASE WHEN channel='wholesale' then (units * (price * (1 - discount))) ELSE NULL END), 0)",
	       "round(count(distinct CASE WHEN channel='wholesale' then (channel) ELSE NULL END))",
	       "round(count(all CASE WHEN channel='wholesale' then (channel) ELSE NULL END))",
	       "floor(avg( CASE WHEN channel='wholesale' then (units * (price * (1 - discount))) ELSE NULL END))",

	       "sum( CASE WHEN channel='wholesale' then units ELSE NULL END)",
	      ];

$\ ="\n";

use Data::Dump qw/dump/;

my @results = (522.88, 523, 533, 531, 19375, 16996, 1, 175, 16995, 91504);

for (@$tests) {
    my $sth = $dbh->prepare(sprintf 'select %s from sales;', $_);
    $sth->execute;
    ok ($sth->fetchall_arrayref->[0]->[0] eq shift @results);
}

# dump @results;

done_testing()

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
