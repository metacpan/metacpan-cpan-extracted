use Test::More;

use DBIx::Class::Helper::ResultSet::CrossTab::Util;

use Data::Dump qw/dump/;

$\ = "\n"; $, = "\t"; binmode(STDOUT, ":utf8");

my $tests = [
	     ['avg(units)',           'channel', 'wholesale'],
	     ['round(avg(units), 0)', 'channel', 'wholesale'],
	     ['round(avg(units + 10), 0)', 'channel', 'wholesale'],
	     ['round(avg(units + (10 - 2)), 0)', 'channel', 'wholesale'],
	     ['round(avg(units * price), 0)', 'channel', 'wholesale'],
	     ['round(avg(units * (price * (1 - discount))), 0)', 'channel', 'wholesale'],
	     ['round(count( distinct channel))', 'channel', 'wholesale'],
	     ['round(count( all channel))', 'channel', 'wholesale'],
	     ['floor(avg(units * (price * (1 - discount))))', 'channel', 'wholesale'],
	     [ { sum => 'units' }, 'channel', 'wholesale' ]
	    ];

my $results = [qw/avg_units_channel_wholesale
		  round_avg_units_channel_wholesale
		  round_avg_units_plus_10_channel_wholesale
		  round_avg_units_plus_10_minus_2_channel_wholesale
		  round_avg_units_times_price_channel_wholesale
		  round_avg_units_times_price_times_1_minus_discount_channel_wholesale
		  round_count_channel_channel_wholesale
		  round_count_channel_channel_wholesale
		  floor_avg_units_times_price_times_1_minus_discount_channel_wholesale
		  sum_units_channel_wholesale/
	      ];

for (@{$tests}) {
    ok(summary_function_to_pivot_field_name(@$_) eq $results->[$i++], ref $_->[0] ? join ': '  %{$_->[0]} : $_->[0]);
}



done_testing()
