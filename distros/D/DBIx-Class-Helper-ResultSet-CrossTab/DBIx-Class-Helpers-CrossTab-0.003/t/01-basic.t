use strict;
use warnings;

use Test::More tests => 4;

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

fixtures_ok [ 
	     Sales => [
		       [qw/fruit country channel units/],
		       @lines
		      ],
    ], 'Installed some custom fixtures via the Populate fixture class';

ok Sales->search({ fruit =>'Currant'}) => 'Found currants!';


is(Sales->search({ fruit =>'Currant'})->count,  100);
is(Sales->search({ fruit =>'Orange'})->get_column('units')->sum,  54547);




# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
