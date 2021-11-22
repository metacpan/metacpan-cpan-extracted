#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::TableData::Rank qw(add_rank_column_to_table);

my $table = [
    {team=>'E', gold=> 2, silver=> 5, bronze=> 7},
    {team=>'A', gold=>10, silver=>20, bronze=>15},
    {team=>'H', gold=> 0, silver=> 0, bronze=> 1},
    {team=>'B', gold=> 8, silver=>23, bronze=>17},
    {team=>'G', gold=> 0, silver=> 0, bronze=> 1},
    {team=>'J', gold=> 0, silver=> 0, bronze=> 0},
    {team=>'C', gold=> 4, silver=>10, bronze=> 8},
    {team=>'D', gold=> 4, silver=> 9, bronze=>13},
    {team=>'I', gold=> 0, silver=> 0, bronze=> 1},
    {team=>'F', gold=> 2, silver=> 5, bronze=> 1},
];

add_rank_column_to_table(
    table=>$table,
    data_columns=>[qw/gold silver bronze/],
);

#use DD; dd $table;

is_deeply($table, [
    {team=>'E', gold=> 2, silver=> 5, bronze=> 7, rank=> 5},
    {team=>'A', gold=>10, silver=>20, bronze=>15, rank=> 1},
    {team=>'H', gold=> 0, silver=> 0, bronze=> 1, rank=>"=7"},
    {team=>'B', gold=> 8, silver=>23, bronze=>17, rank=> 2},
    {team=>'G', gold=> 0, silver=> 0, bronze=> 1, rank=>"=7"},
    {team=>'J', gold=> 0, silver=> 0, bronze=> 0, rank=>10},
    {team=>'C', gold=> 4, silver=>10, bronze=> 8, rank=> 3},
    {team=>'D', gold=> 4, silver=> 9, bronze=>13, rank=> 4},
    {team=>'I', gold=> 0, silver=> 0, bronze=> 1, rank=>"=7"},
    {team=>'F', gold=> 2, silver=> 5, bronze=> 1, rank=> 6},
]);

# XXX test opt:add_equal_prefix
# XXX test opt:rank_column_name
# XXX test opt:smaller_wins
# XXX test opt:rank_column_idx

done_testing;
