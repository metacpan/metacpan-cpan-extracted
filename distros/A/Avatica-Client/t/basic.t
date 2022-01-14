use strict;
use warnings;
use Test::More;

use lib 't/lib';

use Avatica::Client;
use Mock 'mock_method';

my $url = $ENV{TEST_ONLINE} || 'http://127.0.0.1:12345';

# mock HTTP::Tiny if offline test
mock_client() unless $ENV{TEST_ONLINE};

my $client = Avatica::Client->new(url => $url);

my $connection_id = int(rand(1000)) . $$;
my ($res, $c) = $client->open_connection($connection_id);
BAIL_OUT($c->{message}) unless $res;

($res, my $statement) = $client->create_statement($connection_id);
is $res, 1, 'create statement for drop table';

($res, my $execute) = $client->prepare_and_execute($connection_id, $statement->get_statement_id, 'DROP TABLE IF EXISTS test');
is $res, 1, 'drop table';

($res, my $r) = $client->close_statement($connection_id, $statement->get_statement_id);
is $res, 1, 'close statement for drop table';

($res, $statement) = $client->create_statement($connection_id);
is $res, 1, 'create statement for create table';

($res, $execute) = $client->prepare_and_execute($connection_id, $statement->get_statement_id, 'CREATE TABLE test (id INTEGER PRIMARY KEY, text VARCHAR)');
is $res, 1, 'create table';

($res, $r) = $client->close_statement($connection_id, $statement->get_statement_id);
is $res, 1, 'close statement for create table';

($res, $statement) = $client->create_statement($connection_id);
is $res, 1, 'create statement for prepare_and_execute_batch';

($res, my $batch) = $client->prepare_and_execute_batch($connection_id, $statement->get_statement_id, [
    q{UPSERT INTO test (id, text) VALUES (1, 'text1')},
    q{UPSERT INTO test (id, text) VALUES (2, 'text2')}
]);
is $res, 1, 'prepare_and_execute_batch';
is scalar(@{$batch->get_update_counts_list}), 2, 'check number of upsert';
is $batch->get_update_counts(0), 1, 'check number of updates in first upsert';

($res, $r) = $client->close_statement($connection_id, $statement->get_statement_id);
is $res, 1, 'close statement for prepare_and_execute_batch';

($res, my $prepare) = $client->prepare($connection_id, 'UPSERT INTO test (id, text) VALUES (?, ?)');
is $res, 1, 'prepare for upsert';

my $val12 = Avatica::Client::Protocol::TypedValue->new;
$val12->set_string_value('text3');
$val12->set_type(Avatica::Client::Protocol::Rep::STRING());
my $val11 = Avatica::Client::Protocol::TypedValue->new;
$val11->set_number_value(3);
$val11->set_type(Avatica::Client::Protocol::Rep::INTEGER());

my $val22 = Avatica::Client::Protocol::TypedValue->new;
$val22->set_string_value('text4');
$val22->set_type(Avatica::Client::Protocol::Rep::STRING());
my $val21 = Avatica::Client::Protocol::TypedValue->new;
$val21->set_number_value(4);
$val21->set_type(Avatica::Client::Protocol::Rep::INTEGER());

($res, my $exec_batch) = $client->execute_batch($connection_id, $prepare->get_statement->get_id, [[$val11, $val12], [$val21, $val22]]);
is $res, 1, 'execute_batch';
is scalar(@{$exec_batch->get_update_counts_list}), 2, 'check number of upsert';
is $exec_batch->get_update_counts(0), 1, 'check number of updates in first upsert';

($res, $r) = $client->close_statement($connection_id, $prepare->get_statement->get_id);
is $res, 1, 'close statement for execute_batch';

($res, $c) = $client->commit($connection_id);
is $res, 1, 'commit';

($res, my $prop) = $client->connection_sync($connection_id, {AutoCommit => 1});
is $res, 1, 'connection_sync';
is $prop->get_conn_props->get_auto_commit, 1, 'autocommit';

($res, $prepare) = $client->prepare($connection_id, 'SELECT * FROM test WHERE id > ?');
is $res, 1, 'prepare for select';

my $val = Avatica::Client::Protocol::TypedValue->new;
$val->set_number_value(0);
$val->set_type(Avatica::Client::Protocol::Rep::INTEGER());

($res, $execute) = $client->execute(
    $connection_id,
    $prepare->get_statement->get_id,
    $prepare->get_statement->get_signature,
    [$val],
    2
);
is $res, 1, 'execute';

my $frame = $execute->get_results(0)->get_first_frame;
is scalar(@{$frame->get_rows_list}), 2, 'check number of rows';
is $frame->get_rows(0)->get_value(1)->get_scalar_value->get_string_value, 'text1', 'check text of first row';

($res, my $fetch) = $client->fetch($connection_id, $prepare->get_statement->get_id, undef, 3);
is $res, 1, 'fetch';
$frame = $fetch->get_frame;
is $frame->get_done, 1, 'frame done';
is scalar(@{$frame->get_rows_list}), 2, 'check number of rows';
is $frame->get_rows(0)->get_value(1)->get_scalar_value->get_string_value, 'text3', 'check text of first row';

($res, $r) = $client->close_statement($connection_id, $prepare->get_statement->get_id);
is $res, 1, 'close statement for execute';

($res, $r) = $client->close_connection($connection_id);
is $res, 1, 'close connection';

done_testing;

sub mock_client {
    my $mock_index = 0;
    mock_method 'HTTP::Tiny::post', sub {
        ++$mock_index;

        my $create_statment_response;
        my $close_statment_response;
        my $execute_batch_response;
        my $prepare_response;

        my $results = +{
            1 => +{
                success => 1,
                status => 200,
                content => do {
                    my $res = Avatica::Client::Protocol::OpenConnectionResponse->new;
                    my $msg = Avatica::Client::Protocol::OpenConnectionResponse->encode($res);
                    my $wrapped = Avatica::Client::Protocol::WireMessage->new;
                    $wrapped->set_name('org.apache.calcite.avatica.proto.Response$OpenConnectionResponse');
                    $wrapped->set_wrapped_message($msg);
                    Avatica::Client::Protocol::WireMessage->encode($wrapped);
                }
            },
            2 => +{
                success => 1,
                status => 200,
                content => ($create_statment_response = do {
                    my $res = Avatica::Client::Protocol::CreateStatementResponse->new;
                    $res->set_statement_id(123);
                    my $msg = Avatica::Client::Protocol::CreateStatementResponse->encode($res);
                    my $wrapped = Avatica::Client::Protocol::WireMessage->new;
                    $wrapped->set_name('org.apache.calcite.avatica.proto.Response$CreateStatementResponse');
                    $wrapped->set_wrapped_message($msg);
                    Avatica::Client::Protocol::WireMessage->encode($wrapped);
                })
            },
            3 => +{
                success => 1,
                status => 200,
                content => do {
                    my $res = Avatica::Client::Protocol::ExecuteResponse->new;
                    $res->set_missing_statement(0);
                    my $msg = Avatica::Client::Protocol::ExecuteResponse->encode($res);
                    my $wrapped = Avatica::Client::Protocol::WireMessage->new;
                    $wrapped->set_name('org.apache.calcite.avatica.proto.Response$ExecuteResponse');
                    $wrapped->set_wrapped_message($msg);
                    Avatica::Client::Protocol::WireMessage->encode($wrapped);
                }
            },
            4 => +{
                success => 1,
                status => 200,
                content => ($close_statment_response = do {
                    my $res = Avatica::Client::Protocol::CloseStatementResponse->new;
                    my $msg = Avatica::Client::Protocol::CloseStatementResponse->encode($res);
                    my $wrapped = Avatica::Client::Protocol::WireMessage->new;
                    $wrapped->set_name('org.apache.calcite.avatica.proto.Response$CloseStatementResponse');
                    $wrapped->set_wrapped_message($msg);
                    Avatica::Client::Protocol::WireMessage->encode($wrapped);
                })
            },
            5 => +{
                success => 1,
                status => 200,
                content => $create_statment_response
            },
            6 => +{
                success => 1,
                status => 200,
                content => do {
                    my $res = Avatica::Client::Protocol::ExecuteResponse->new;
                    $res->set_missing_statement(0);
                    my $msg = Avatica::Client::Protocol::ExecuteResponse->encode($res);
                    my $wrapped = Avatica::Client::Protocol::WireMessage->new;
                    $wrapped->set_name('org.apache.calcite.avatica.proto.Response$ExecuteResponse');
                    $wrapped->set_wrapped_message($msg);
                    Avatica::Client::Protocol::WireMessage->encode($wrapped);
                }
            },
            7 => +{
                success => 1,
                status => 200,
                content => $close_statment_response
            },
            8 => +{
                success => 1,
                status => 200,
                content => $create_statment_response
            },
            9 => +{
                success => 1,
                status => 200,
                content => ($execute_batch_response = do {
                    my $res = Avatica::Client::Protocol::ExecuteBatchResponse->new;
                    $res->set_missing_statement(0);
                    $res->set_update_counts_list([1, 1]);
                    my $msg = Avatica::Client::Protocol::ExecuteBatchResponse->encode($res);
                    my $wrapped = Avatica::Client::Protocol::WireMessage->new;
                    $wrapped->set_name('org.apache.calcite.avatica.proto.Response$ExecuteBatchResponse');
                    $wrapped->set_wrapped_message($msg);
                    Avatica::Client::Protocol::WireMessage->encode($wrapped);
                })
            },
            10 => +{
                success => 1,
                status => 200,
                content => $close_statment_response
            },
            11 => +{
                success => 1,
                status => 200,
                content => ($prepare_response = do {
                    my $signature = Avatica::Client::Protocol::Signature->new;
                    my $st = Avatica::Client::Protocol::StatementHandle->new;
                    $st->set_id(54321);
                    $st->set_signature($signature);
                    my $res = Avatica::Client::Protocol::PrepareResponse->new;
                    $res->set_statement($st);
                    my $msg = Avatica::Client::Protocol::PrepareResponse->encode($res);
                    my $wrapped = Avatica::Client::Protocol::WireMessage->new;
                    $wrapped->set_name('org.apache.calcite.avatica.proto.Response$PrepareResponse');
                    $wrapped->set_wrapped_message($msg);
                    Avatica::Client::Protocol::WireMessage->encode($wrapped);
                })
            },
            12 => +{
                success => 1,
                status => 200,
                content => $execute_batch_response
            },
            13 => +{
                success => 1,
                status => 200,
                content => $close_statment_response
            },
            14 => +{
                success => 1,
                status => 200,
                content => do {
                    my $res = Avatica::Client::Protocol::CommitResponse->new;
                    my $msg = Avatica::Client::Protocol::CommitResponse->encode($res);
                    my $wrapped = Avatica::Client::Protocol::WireMessage->new;
                    $wrapped->set_name('org.apache.calcite.avatica.proto.Response$CommitResponse');
                    $wrapped->set_wrapped_message($msg);
                    Avatica::Client::Protocol::WireMessage->encode($wrapped);
                }
            },
            15 => +{
                success => 1,
                status => 200,
                content => do {
                    my $prop = Avatica::Client::Protocol::ConnectionProperties->new;
                    $prop->set_auto_commit(1);
                    $prop->set_has_auto_commit(1);
                    my $res = Avatica::Client::Protocol::ConnectionSyncResponse->new;
                    $res->set_conn_props($prop);
                    my $msg = Avatica::Client::Protocol::ConnectionSyncResponse->encode($res);
                    my $wrapped = Avatica::Client::Protocol::WireMessage->new;
                    $wrapped->set_name('org.apache.calcite.avatica.proto.Response$ConnectionSyncResponse');
                    $wrapped->set_wrapped_message($msg);
                    Avatica::Client::Protocol::WireMessage->encode($wrapped);
                }
            },
            16 => +{
                success => 1,
                status => 200,
                content => $prepare_response
            },
            17 => +{
                success => 1,
                status => 200,
                content => do {
                    my $tval11 = Avatica::Client::Protocol::TypedValue->new;
                    $tval11->set_number_value(1);
                    my $tval12 = Avatica::Client::Protocol::TypedValue->new;
                    $tval12->set_string_value('text1');
                    my $tval21 = Avatica::Client::Protocol::TypedValue->new;
                    $tval11->set_number_value(2);
                    my $tval22 = Avatica::Client::Protocol::TypedValue->new;
                    $tval22->set_string_value('text2');
                    my $col11 = Avatica::Client::Protocol::ColumnValue->new;
                    $col11->set_scalar_value($tval11);
                    my $col12 = Avatica::Client::Protocol::ColumnValue->new;
                    $col12->set_scalar_value($tval12);
                    my $col21 = Avatica::Client::Protocol::ColumnValue->new;
                    $col21->set_scalar_value($tval21);
                    my $col22 = Avatica::Client::Protocol::ColumnValue->new;
                    $col22->set_scalar_value($tval22);
                    my $row1 = Avatica::Client::Protocol::Row->new;
                    $row1->set_value_list([$col11, $col12]);
                    my $row2 = Avatica::Client::Protocol::Row->new;
                    $row2->set_value_list([$col21, $col22]);
                    my $frame = Avatica::Client::Protocol::Frame->new;
                    $frame->set_offset(2);
                    $frame->set_rows_list([$row1, $row2]);
                    my $res_set = Avatica::Client::Protocol::ResultSetResponse->new;
                    $res_set->set_first_frame($frame);
                    my $res = Avatica::Client::Protocol::ExecuteResponse->new;
                    $res->set_missing_statement(0);
                    $res->set_results_list([$res_set]);
                    my $msg = Avatica::Client::Protocol::ExecuteResponse->encode($res);
                    my $wrapped = Avatica::Client::Protocol::WireMessage->new;
                    $wrapped->set_name('org.apache.calcite.avatica.proto.Response$ExecuteResponse');
                    $wrapped->set_wrapped_message($msg);
                    Avatica::Client::Protocol::WireMessage->encode($wrapped);
                }
            },
            18 => +{
                success => 1,
                status => 200,
                content => do {
                    my $tval11 = Avatica::Client::Protocol::TypedValue->new;
                    $tval11->set_number_value(3);
                    my $tval12 = Avatica::Client::Protocol::TypedValue->new;
                    $tval12->set_string_value('text3');
                    my $tval21 = Avatica::Client::Protocol::TypedValue->new;
                    $tval11->set_number_value(4);
                    my $tval22 = Avatica::Client::Protocol::TypedValue->new;
                    $tval22->set_string_value('text4');
                    my $col11 = Avatica::Client::Protocol::ColumnValue->new;
                    $col11->set_scalar_value($tval11);
                    my $col12 = Avatica::Client::Protocol::ColumnValue->new;
                    $col12->set_scalar_value($tval12);
                    my $col21 = Avatica::Client::Protocol::ColumnValue->new;
                    $col21->set_scalar_value($tval21);
                    my $col22 = Avatica::Client::Protocol::ColumnValue->new;
                    $col22->set_scalar_value($tval22);
                    my $row1 = Avatica::Client::Protocol::Row->new;
                    $row1->set_value_list([$col11, $col12]);
                    my $row2 = Avatica::Client::Protocol::Row->new;
                    $row2->set_value_list([$col21, $col22]);
                    my $frame = Avatica::Client::Protocol::Frame->new;
                    $frame->set_offset(2);
                    $frame->set_rows_list([$row1, $row2]);
                    $frame->set_done(1);
                    my $res = Avatica::Client::Protocol::FetchResponse->new;
                    $res->set_missing_statement(0);
                    $res->set_missing_results(0);
                    $res->set_frame($frame);
                    my $msg = Avatica::Client::Protocol::FetchResponse->encode($res);
                    my $wrapped = Avatica::Client::Protocol::WireMessage->new;
                    $wrapped->set_name('org.apache.calcite.avatica.proto.Response$FetchResponse');
                    $wrapped->set_wrapped_message($msg);
                    Avatica::Client::Protocol::WireMessage->encode($wrapped);
                }
            },
            19 => +{
                success => 1,
                status => 200,
                content => $close_statment_response
            },
            20 => +{
                success => 1,
                status => 200,
                content => do {
                    my $res = Avatica::Client::Protocol::CloseConnectionResponse->new;
                    my $msg = Avatica::Client::Protocol::CloseConnectionResponse->encode($res);
                    my $wrapped = Avatica::Client::Protocol::WireMessage->new;
                    $wrapped->set_name('org.apache.calcite.avatica.proto.Response$CloseConnectionResponse');
                    $wrapped->set_wrapped_message($msg);
                    Avatica::Client::Protocol::WireMessage->encode($wrapped);
                }
            }
        };
        return $results->{$mock_index};
    };
}
