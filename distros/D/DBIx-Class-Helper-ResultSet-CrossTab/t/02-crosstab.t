use strict;
use warnings;

use Test::More tests => 5;

use lib './t/lib';
# use Data::Dump qw/dump/;

use Test::Schema;
use DBIx::Class::Helper::ResultSet::CrossTab;

use Test::DBIx::Class {
    schema_class => 'Test::Schema',
	connect_info => ['dbi:SQLite:dbname=test.db','',''],
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


my $f = Test::Schema->connect('dbi:SQLite:test.db') || die;
my $s = $f->resultset('Sales');

my $r = $s->search({}, { columns => [qw/fruit channel/], } )
    ->crosstab({}, { select  => [qw/fruit/], on => [qw/channel/], pivot => [ { sum => 'units' } ], group_by => [qw/fruit/] });
$r->result_class('DBIx::Class::ResultClass::HashRefInflator');

is_deeply([ $r->all ],
	  [
	   {
	    fruit => "Cherry",
	    sum_units_broker => 11974,
	    sum_units_e_commerce => 12258,
	    sum_units_own_retail => 15475,
	    sum_units_wholesale => 11674,
	   },
	   {
	    fruit => "Currant",
	    sum_units_broker => 13720,
	    sum_units_e_commerce => 13324,
	    sum_units_own_retail => 13082,
	    sum_units_wholesale => 14498,
	   },
	   {
	    fruit => "Custard apple",
	    sum_units_broker => 9222,
	    sum_units_e_commerce => 13745,
	    sum_units_own_retail => 12888,
	    sum_units_wholesale => 12862,
	   },
	   {
	    fruit => "Jackfruit",
	    sum_units_broker => 13733,
	    sum_units_e_commerce => 12704,
	    sum_units_own_retail => 12861,
	    sum_units_wholesale => 12796,
	   },
	   {
	    fruit => "Orange",
	    sum_units_broker => 12737,
	    sum_units_e_commerce => 14390,
	    sum_units_own_retail => 14006,
	    sum_units_wholesale => 13414,
	   },
	   {
	    fruit => "Peach",
	    sum_units_broker => 13142,
	    sum_units_e_commerce => 15331,
	    sum_units_own_retail => 11781,
	    sum_units_wholesale => 13827,
	   },
	   {
	    fruit => "Tomato",
	    sum_units_broker => 10385,
	    sum_units_e_commerce => 12721,
	    sum_units_own_retail => 11132,
	    sum_units_wholesale => 12433,
	   },
	  ],
	  'simple crosstab');

$r = $s->search({}, { columns => [qw/fruit channel/], } )->crosstab({ fruit => { -like => 'C%'} },
								    { select  => [qw/fruit/], on => [qw/channel/],
								      pivot => [ { sum => 'units' } ], group_by => [qw/fruit/] }
								      );
$r->result_class('DBIx::Class::ResultClass::HashRefInflator');
is_deeply([ $r->all ],
	  [
	   {
	    fruit => "Cherry",
	    sum_units_broker => 11974,
	    sum_units_e_commerce => 12258,
	    sum_units_own_retail => 15475,
	    sum_units_wholesale => 11674,
	   },
	   {
	    fruit => "Currant",
	    sum_units_broker => 13720,
	    sum_units_e_commerce => 13324,
	    sum_units_own_retail => 13082,
	    sum_units_wholesale => 14498,
	   },
	   {
	    fruit => "Custard apple",
	    sum_units_broker => 9222,
	    sum_units_e_commerce => 13745,
	    sum_units_own_retail => 12888,
	    sum_units_wholesale => 12862,
	   },
	  ],
	  'filtered crosstab'
	 );

$r = $s->search({}, { columns => [qw/fruit channel/], } )
    ->crosstab({ channel => { -like => '%w%'} },
	       { select  => [qw/fruit/], on => [qw/channel/], pivot => [ { sum => 'units' } ], group_by => [qw/fruit/] }
	      );
$r->result_class('DBIx::Class::ResultClass::HashRefInflator');
is_deeply([ $r->all ],
	  [
	   {
	    fruit => "Cherry",
	    sum_units_own_retail => 15475,
	    sum_units_wholesale => 11674,
	   },
	   {
	    fruit => "Currant",
	    sum_units_own_retail => 13082,
	    sum_units_wholesale => 14498,
	   },
	   {
	    fruit => "Custard apple",
	    sum_units_own_retail => 12888,
	    sum_units_wholesale => 12862,
	   },
	   {
	    fruit => "Jackfruit",
	    sum_units_own_retail => 12861,
	    sum_units_wholesale => 12796,
	   },
	   {
	    fruit => "Orange",
	    sum_units_own_retail => 14006,
	    sum_units_wholesale => 13414,
	   },
	   {
	    fruit => "Peach",
	    sum_units_own_retail => 11781,
	    sum_units_wholesale => 13827,
	   },
	   {
	    fruit => "Tomato",
	    sum_units_own_retail => 11132,
	    sum_units_wholesale => 12433,
	   },
	  ],
	  'filtered \'on\' field'
);

$r = $s->search({}, { columns => [qw/fruit channel/], } )->crosstab({ fruit => { -like => 'C%'} },
								    { select  => [qw/fruit/], on => [qw/channel/], pivot => [ \"sum(units)" ], group_by => [qw/fruit/] }
								   );
$r->result_class('DBIx::Class::ResultClass::HashRefInflator');


is_deeply([ $r->all ],
	  [
	   {
	    fruit => "Cherry",
	    sum_all_units_broker => 11974,
	    sum_all_units_e_commerce => 12258,
	    sum_all_units_own_retail => 15475,
	    sum_all_units_wholesale => 11674,
	   },
	   {
	    fruit => "Currant",
	    sum_all_units_broker => 13720,
	    sum_all_units_e_commerce => 13324,
	    sum_all_units_own_retail => 13082,
	    sum_all_units_wholesale => 14498,
	   },
	   {
	    fruit => "Custard apple",
	    sum_all_units_broker => 9222,
	    sum_all_units_e_commerce => 13745,
	    sum_all_units_own_retail => 12888,
	    sum_all_units_wholesale => 12862,
	   },
	  ],
	  'filtered crosstab'
	 );

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
