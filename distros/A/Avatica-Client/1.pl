#!/usr/bin/perl

use strict;
use warnings;
use Avatica::Client;
use Data::Dumper;

my $connection_id = int(rand(111)) . $$;

print $connection_id, $/;

my $client = Avatica::Client->new(url => 'http://hpqs:8765');
my ($res, $connection) = $client->open_connection($connection_id);

# print $res, $/;
# print Dumper $connection;

# ($res, my $prepare) = $client->prepare($connection_id, 'select * from Y where C = ? limit 10');

# print $res, $/;
# print Dumper $prepare;

# my $statement = $prepare->get_statement;
# my $statement_id = $statement->get_id;
# my $signature = $statement->get_signature;

# my $tv1 = Avatica::Client::Protocol::TypedValue->new;
# $tv1->set_number_value(1);
# $tv1->set_type(Avatica::Client::Protocol::Rep::LONG());

# BATCH

# ($res, my $execute_batch) = $client->execute_batch($connection_id, $statement_id, [[$tv1]]);
# print $res, $/;
# print Dumper $execute_batch;

# SINGLE

# ($res, my $execute) = $client->execute($connection_id, $statement_id, $signature, [$tv1], 2);

# # print $res;
# print Dumper $execute;
# my $result = $execute->get_results(0);
# if ($result->get_own_statement) {
#     if ($statement_id != $result->get_statement_id) {
#         $client->close_statement($connection_id, $statement_id);
#     }
#     $statement_id = $result->get_statement_id;
# }

# $signature = $result->get_signature || undef;
# my $update_count = ($result->get_update_count // -1) == '18446744073709551615' ? -1 : $result->get_update_count;
# my $frame = $result->get_first_frame || undef;
# my $pos = undef;
# $pos = 0 if defined $frame && $frame->rows_size;

# print "frame offset: " . $frame->rows_size, $/;
# print "frame offset: " . $frame->get_offset, $/;
# print "frame is done: " . $frame->get_done, $/;

# ($res, my $fetch) = $client->fetch($connection_id, $statement_id, undef, 4);
# print Dumper $fetch;

# my $state = Avatica::Client::Protocol::QueryState->new;
# $state->set_type(0);
# $state->set_sql('select * from Y where C = ? limit 10');
# $state->set_has_sql(1);
# ($res, my $sync) = $client->sync_results($connection_id, $statement_id, $state);
# print Dumper $sync;
# ($res, $fetch) = $client->fetch($connection_id, $statement_id, undef, 2);
# print Dumper $fetch;

# Another PrepareAndExcute

# ($res, my $schemas) = $client->table_types($connection_id);
# print $res, $/;
# print Dumper $schemas;

# ($res, my $schemas) = $client->type_info($connection_id);
# print $res, $/;
# print Dumper $schemas;

# ($res, my $schemas) = $client->tables($connection_id, undef, undef);
# print $res, $/;
# print Dumper $schemas;

($res, my $schemas) = $client->schemas($connection_id);
print $res, $/;
print Dumper $schemas;

# ($res, my $props) = $client->database_property($connection_id);
# print $res, $/;
# print Dumper $props;

# ($res, my $columns) = $client->columns($connection_id);
# print $res, $/;
# print Dumper $columns;

# ($res, my $catalog) = $client->catalog($connection_id);
# print $res, $/;
# print Dumper $catalog;

# ($res, my $props) = $client->connection_sync($connection_id, {
#     AutoCommit => 0,
#     ReadOnly => 0,
#     TransactionIsolation => 2,
#     Catalog => '',
#     Schema => ''
# });
# print Dumper $props;

# ($res, my $statement) = $client->create_statement($connection_id);
# print "statement: " . $statement->get_statement_id, $/;
# ($res, my $execute) = $client->prepare_and_execute($connection_id, $statement->get_statement_id, 'select * from Y limit 4', undef, 4);
# print Dumper $execute;
# ($res, my $r) = $client->close_statement($connection_id, $statement->get_statement_id);
# print Dumper $r;
# ($res, $r) = $client->close_connection($connection_id);
# print Dumper $r;

# ($res, my $statement) = $client->create_statement($connection_id);
# ($res, my $execute_batch) = $client->prepare_and_execute_batch($connection_id, $statement->get_statement_id, ['select * from Y limit 4']);
# print Dumper $execute_batch;

# COMMIT/ROLLBACK

# ($res, my $props) = $client->connection_sync($connection_id, {
#     AutoCommit => 0,
#     ReadOnly => 0,
#     TransactionIsolation => 2,
#     Catalog => '',
#     Schema => ''
# });
# print Dumper $props;
# ($res, my $statement) = $client->create_statement($connection_id);
# ($res, my $execute) = $client->prepare_and_execute(
#     $connection_id,
#     $statement->get_statement_id,
#     q{upsert into MY_TABLE(K, V) values (1, 'A')}
# );
# print Dumper $execute;
# ($res, $execute) = $client->prepare_and_execute(
#     $connection_id,
#     $statement->get_statement_id,
#     q{upsert into MY_TABLE(K, V) values (2, 'B')}
# );
# print Dumper $execute;
# ($res, $execute) = $client->prepare_and_execute(
#     $connection_id,
#     $statement->get_statement_id,
#     q{select * from MY_TABLE},
#     undef,
#     100
# );
# print Dumper $execute;
# <>;
# ($res, my $commit) = $client->commit($connection_id);
# print Dumper $commit;
# ($res, my $r) = $client->close_statement($connection_id, $statement->get_statement_id);
# print Dumper $r;
# ($res, $r) = $client->close_connection($connection_id);
# print Dumper $r;
