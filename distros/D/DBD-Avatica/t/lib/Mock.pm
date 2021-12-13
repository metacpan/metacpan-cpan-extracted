package Mock;

use strict;
use warnings;

use parent 'Exporter';
our @EXPORT_OK = qw(mock_method mock_common mock_prepare_seq mock_execute_seq mock_fetch_seq);

sub mock_method {
    my ($method, $sub) = @_;

    no warnings 'redefine';
    no strict 'refs';

    *$method = $sub;
}

sub mock_common {
    &mock_connect;
    &mock_create_table;
    mock_call('close_statement', 'CloseStatementResponse', '{"metadata":{"serverAddress":"c497a18abde6:8765"}}');
    mock_call('close_connection', 'CloseConnectionResponse', '{"metadata":{"serverAddress":"c497a18abde6:8765"}}');
}

sub mock_connect {
    mock_call('open_connection', 'OpenConnectionResponse', '{"metadata":{"serverAddress":"c497a18abde6:8765"}}');
    mock_call('connection_sync', 'ConnectionSyncResponse', '{"connProps":{"autoCommit":true,"transactionIsolation":2,"hasAutoCommit":true,"hasReadOnly":true},"metadata":{"serverAddress":"c497a18abde6:8765"}}');
    mock_call('database_property', 'DatabasePropertyResponse', '{"props":[{"key":{"name":"GET_DATABASE_MAJOR_VERSION"},"value":{"type":"INTEGER","numberValue":4}},{"key":{"name":"GET_DEFAULT_TRANSACTION_ISOLATION"},"value":{"type":"INTEGER","numberValue":2}},{"key":{"name":"GET_NUMERIC_FUNCTIONS"},"value":{"type":"STRING"}},{"key":{"name":"GET_STRING_FUNCTIONS"},"value":{"type":"STRING"}},{"key":{"name":"GET_DRIVER_MINOR_VERSION"},"value":{"type":"INTEGER","numberValue":15}},{"key":{"name":"GET_DRIVER_VERSION"},"value":{"type":"STRING","stringValue":"4.15"}},{"key":{"name":"GET_DATABASE_PRODUCT_VERSION"},"value":{"type":"STRING","stringValue":"4.15"}},{"key":{"name":"AVATICA_VERSION"},"value":{"type":"STRING","stringValue":"1.18.0"}},{"key":{"name":"GET_DRIVER_MAJOR_VERSION"},"value":{"type":"INTEGER","numberValue":4}},{"key":{"name":"GET_SYSTEM_FUNCTIONS"},"value":{"type":"STRING"}},{"key":{"name":"GET_DRIVER_NAME"},"value":{"type":"STRING","stringValue":"PhoenixEmbeddedDriver"}},{"key":{"name":"GET_DATABASE_MINOR_VERSION"},"value":{"type":"INTEGER","numberValue":15}},{"key":{"name":"GET_DATABASE_PRODUCT_NAME"},"value":{"type":"STRING","stringValue":"Phoenix"}},{"key":{"name":"GET_TIME_DATE_FUNCTIONS"},"value":{"type":"STRING"}},{"key":{"name":"GET_S_Q_L_KEYWORDS"},"value":{"type":"STRING"}}],"metadata":{"serverAddress":"c497a18abde6:8765"}}');
}

sub mock_create_table {
    mock_prepare_seq([
        '{"statement":{"connectionId":"35p0fchr4g6az0wwy8l541zl0ys2yh","id":79,"signature":{"sql":"DROP TABLE IF EXISTS TEST","cursorFactory":{"style":"LIST"}}},"metadata":{"serverAddress":"c497a18abde6:8765"}}',
        '{"statement":{"connectionId":"35p0fchr4g6az0wwy8l541zl0ys2yh","id":81,"signature":{"sql":"CREATE TABLE TEST(ID BIGINT PRIMARY KEY, TEXT VARCHAR)","cursorFactory":{"style":"LIST"}}},"metadata":{"serverAddress":"c497a18abde6:8765"}}'
    ]);
    mock_execute_seq([
        '{"results":[{"connectionId":"35p0fchr4g6az0wwy8l541zl0ys2yh","statementId":80,"metadata":{"serverAddress":"c497a18abde6:8765"}}],"metadata":{"serverAddress":"c497a18abde6:8765"}}',
        '{"results":[{"connectionId":"35p0fchr4g6az0wwy8l541zl0ys2yh","statementId":82,"metadata":{"serverAddress":"c497a18abde6:8765"}}],"metadata":{"serverAddress":"c497a18abde6:8765"}}'
    ]);
}

sub mock_prepare_seq {
    my $list = shift;
    mock_call_seq('prepare', 'PrepareResponse', $list);
}

sub mock_execute_seq {
    my $list = shift;
    mock_call_seq('execute', 'ExecuteResponse', $list);
}

sub mock_fetch_seq {
    my $list = shift;
    mock_call_seq('fetch', 'FetchResponse', $list);
}

sub mock_call {
    my ($func, $class, $data) = @_;
    mock_method "Avatica::Client::$func", sub {
        return 1, "Avatica::Client::Protocol::$class"->decode_json($data);
    };
}

sub mock_call_seq {
    my ($func, $class, $data_list) = @_;
    my $count = 0;
    mock_method "Avatica::Client::$func", sub {
        my $data = $data_list->[$count++];
        return 1, "Avatica::Client::Protocol::$class"->decode_json($data);
    };
}

1;
