use Test::More;

use DBIx::Class::Helper::ResultSet::CrossTab::Util;

# use Data::Dump qw/dump/;

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

my $results = [
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

for (@{$tests}) {
    ok(summary_function_to_pivot_field_func(@$_) eq $results->[$i++], ref $_->[0] ? join ': ' %{$_->[0]} : $_->[0]);
}

# for (@{$tests}) {
#     print summary_function_to_pivot_field_def(@$_);
# }

done_testing()
