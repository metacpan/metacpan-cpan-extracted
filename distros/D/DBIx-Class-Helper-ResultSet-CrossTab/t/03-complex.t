use strict;
use warnings;

use Test::More;

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


my $expected = 	  [
	   {
	    fruit                    => "Cherry",
	    avg_units_channel_broker     => 478.96,
	    avg_units_channel_e_commerce => 490.32,
	    avg_units_channel_own_retail => 619,
	    avg_units_channel_wholesale  => 466.96,
	    sum_units_channel_broker         => 11974,
	    sum_units_channel_e_commerce     => 12258,
	    sum_units_channel_own_retail     => 15475,
	    sum_units_channel_wholesale      => 11674,
	   },
	   {
	    fruit                    => "Currant",
	    avg_units_channel_broker     => 548.8,
	    avg_units_channel_e_commerce => 532.96,
	    avg_units_channel_own_retail => 523.28,
	    avg_units_channel_wholesale  => 579.92,
	    sum_units_channel_broker         => 13720,
	    sum_units_channel_e_commerce     => 13324,
	    sum_units_channel_own_retail     => 13082,
	    sum_units_channel_wholesale      => 14498,
	   },
	   {
	    fruit                    => "Custard apple",
	    avg_units_channel_broker     => 368.88,
	    avg_units_channel_e_commerce => 549.8,
	    avg_units_channel_own_retail => 515.52,
	    avg_units_channel_wholesale  => 514.48,
	    sum_units_channel_broker         => 9222,
	    sum_units_channel_e_commerce     => 13745,
	    sum_units_channel_own_retail     => 12888,
	    sum_units_channel_wholesale      => 12862,
	   },
	  ];


my $f = Test::Schema->connect('dbi:SQLite:test.db') || die;
my $s = $f->resultset('Sales');
my $r = $s->search({}, { columns => [qw/fruit channel/], } )->crosstab({ fruit => { -like => 'C%'} },
								       {
									select  => [qw/fruit/],
									on => [qw/channel/],
									pivot => [ { sum => 'units' }, \'avg(units)' ], group_by => [qw/fruit/]
								       }
								      );
$r->result_class('DBIx::Class::ResultClass::HashRefInflator');

is_deeply([ $r->all ], $expected, 'multiple pivot fields');

$r = $s->search({ fruit => { -like => 'C%'} }, { columns => [qw/fruit channel/], } )->crosstab({},
								       {
									select  => [qw/fruit/],
									on => [qw/channel/],
									pivot => [ { sum => 'units' }, \'avg(units)' ], group_by => [qw/fruit/]
								       }
								      );
$r->result_class('DBIx::Class::ResultClass::HashRefInflator');

is_deeply([ $r->all ], $expected, 'upstream filter');


$r = $s->search({ channel => { -like => '%w%'} }, { columns => [qw/fruit channel/], } )->crosstab( { fruit => { -like => 'C%'} },
								       {
									select  => [qw/fruit/],
									on => [qw/channel/],
									pivot => [ { sum => 'units' }, \'avg(units)' ], group_by => [qw/fruit/]
								       }
								      );
$r->result_class('DBIx::Class::ResultClass::HashRefInflator');

$expected = [
  {
    avg_units_channel_own_retail => 619,
    avg_units_channel_wholesale => 466.96,
    fruit => "Cherry",
    sum_units_channel_own_retail => 15475,
    sum_units_channel_wholesale => 11674,
  },
  {
    avg_units_channel_own_retail => 523.28,
    avg_units_channel_wholesale => 579.92,
    fruit => "Currant",
    sum_units_channel_own_retail => 13082,
    sum_units_channel_wholesale => 14498,
  },
  {
    avg_units_channel_own_retail => 515.52,
    avg_units_channel_wholesale => 514.48,
    fruit => "Custard apple",
    sum_units_channel_own_retail => 12888,
    sum_units_channel_wholesale => 12862,
  },
];

is_deeply([ $r->all ], $expected, 'combined upstream and downstream  filter');


done_testing();

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
