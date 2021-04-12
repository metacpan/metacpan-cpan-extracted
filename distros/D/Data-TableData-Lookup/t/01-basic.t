#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::TableData::Lookup qw(table_vlookup);

my $table = [
    {a=> 1, b=> 100},
    {a=> 5, b=> 500},
    {a=>10, b=>1000},
];

is_deeply(table_vlookup(table=>$table, lookup_value=> 0, lookup_field=>"a", result_field=>"b"), undef);
is_deeply(table_vlookup(table=>$table, lookup_value=> 1, lookup_field=>"a", result_field=>"b"),  100);
is_deeply(table_vlookup(table=>$table, lookup_value=> 5, lookup_field=>"a", result_field=>"b"),  500);
is_deeply(table_vlookup(table=>$table, lookup_value=>10, lookup_field=>"a", result_field=>"b"), 1000);

# approx=1
is_deeply(table_vlookup(table=>$table, lookup_value=> 0, lookup_field=>"a", result_field=>"b", approx=>1), undef);
is_deeply(table_vlookup(table=>$table, lookup_value=> 1, lookup_field=>"a", result_field=>"b", approx=>1),  100); # exact
is_deeply(table_vlookup(table=>$table, lookup_value=> 3, lookup_field=>"a", result_field=>"b", approx=>1),  100);
is_deeply(table_vlookup(table=>$table, lookup_value=> 6, lookup_field=>"a", result_field=>"b", approx=>1),  500);
is_deeply(table_vlookup(table=>$table, lookup_value=>11, lookup_field=>"a", result_field=>"b", approx=>1), 1000);

# approx=1 interpolate=1
is_deeply(table_vlookup(table=>$table, lookup_value=> 0, lookup_field=>"a", result_field=>"b", approx=>1, interpolate=>1), undef);
is_deeply(table_vlookup(table=>$table, lookup_value=> 1, lookup_field=>"a", result_field=>"b", approx=>1, interpolate=>1),  100); # exact
is_deeply(table_vlookup(table=>$table, lookup_value=> 3, lookup_field=>"a", result_field=>"b", approx=>1, interpolate=>1),  300);
is_deeply(table_vlookup(table=>$table, lookup_value=>11, lookup_field=>"a", result_field=>"b", approx=>1, interpolate=>1), 1000); # can't interpolate

DONE_TESTING:
done_testing;
