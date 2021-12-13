#!/usr/bin/perl

use strict;
use warnings;
use Avatica::Client;
use Avatica::Types;
use Data::Dumper;

my $connection_id = int(rand(111)) . $$;

print $connection_id, $/;

my $client = Avatica::Client->new(url => 'http://hpqs:8765');
my ($res, $connection) = $client->open_connection($connection_id);

# TEST SELECT AND CONVERT ROWS

($res, my $statement) = $client->create_statement($connection_id);
($res, my $execute) = $client->prepare_and_execute($connection_id, $statement->get_statement_id, 'select * from z', undef, 1);
my $signature = $execute->get_results(0)->get_signature;
my $columns = $signature->get_columns_list;
print Dumper $execute;

my $frame = $execute->get_results(0)->get_first_frame;

my $rows = [map {
    Avatica::Types->row_from_jdbc($_->get_value_list, $columns)
} @{$frame->get_rows_list}];

print Dumper $rows;

# ($res, my $fetch) = $client->fetch($connection_id, $statement->get_statement_id, undef, 4);
# print Dumper $fetch;


# TEST PREPARE

# ($res, my $prepare) = $client->prepare($connection_id, 'select * from z where Y = ? limit 10');
# print Dumper $prepare;

## TEST INSERT WIDE ROW

# ($res, my $prepare) = $client->prepare($connection_id, q{
#     UPSERT INTO Z VALUES (
#         ?, ?, ?, ?, ?,
#         ?, ?, ?, ?, ?,
#         ?, ?, ?, ?, ?,
#         ?, ?, ?, ?, ?,
#         ?, ?, ?, ?, ?
#     )
# });
# print Dumper $prepare;

# my $params = [
#     11,
#     22,
#     33,
#     44,
#     55,
#     66,
#     77,
#     88,
#     11.123,
#     22.234,
#     33.345,
#     44.456,
#     654321.01,
#     0,
#     '2021-01-01 11:12:13.1234',
#     '2021-01-01 11:12:13.1234',
#     '2021-01-01 11:12:13.1234',
#     '12:13:14.100',
#     '2021-02-03',
#     '2021-02-03 12:13:14.1',
#     'qwerty', 'asdfg', 'zxcvb', 'zzzz',
#     [1, 0, -1, 2147483647]
# ];

# my $params_type = $prepare->get_statement->get_signature->get_parameters_list;
# my $jdbc_params = [
#     map {
#         Avatica::Types->to_jdbc($params->[$_], $params_type->[$_])
#     } 0 .. $#{$params_type}
# ];

# ($res, my $execute) = $client->execute(
#     $connection_id,
#     $prepare->get_statement->get_id,
#     $prepare->get_statement->get_signature,
#     $jdbc_params,
#     2
# );

# print Dumper $execute;

# ($res, my $commit) = $client->commit($connection_id);
# print Dumper $commit;
