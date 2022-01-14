use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Mock qw/mock_method mock_common mock_prepare_seq mock_execute_seq mock_fetch_seq/;

use DBI;
use DBD::Avatica;

my $is_mock = !($ENV{TEST_ONLINE});
my $url = $ENV{TEST_ONLINE} || 'http://127.0.0.1:8765';

&mock_common if $is_mock;
my $dbh = DBI->connect("dbi:Avatica:adapter_name=phoenix;url=$url") or BAIL_OUT( DBI->errstr );
my $ret = $dbh->do(q{DROP TABLE IF EXISTS TEST});
is $ret, '0E0', 'check drop res';
$ret = $dbh->do(q{CREATE TABLE TEST(ID BIGINT PRIMARY KEY, TEXT VARCHAR)});
is $ret, '0E0', 'check drop res';

subtest 'prepare & execute without params' => sub {
    if ($is_mock) {
        mock_prepare_seq([
            q!{"statement":{"connectionId":"yylc41tx9whb7d7h996rzq8k7q7cv2","id":87,"signature":{"sql":"UPSERT INTO TEST VALUES (1, 'foo')","cursorFactory":{"style":"LIST"}}},"metadata":{"serverAddress":"c497a18abde6:8765"}}!,
            q!{"statement":{"connectionId":"yylc41tx9whb7d7h996rzq8k7q7cv2","id":89,"signature":{"columns":[{"searchable":true,"signed":true,"displaySize":40,"label":"ID","columnName":"ID","tableName":"TEST","readOnly":true,"columnClassName":"java.lang.Long","type":{"id":4294967291,"name":"BIGINT","rep":"PRIMITIVE_LONG"}},{"ordinal":1,"searchable":true,"nullable":1,"displaySize":40,"label":"TEXT","columnName":"TEXT","tableName":"TEST","readOnly":true,"columnClassName":"java.lang.String","type":{"id":12,"name":"VARCHAR","rep":"STRING"}}],"sql":"SELECT * FROM TEST","cursorFactory":{"style":"LIST"}}},"metadata":{"serverAddress":"c497a18abde6:8765"}}!
        ]);
        mock_execute_seq([
            q!{"results":[{"connectionId":"yylc41tx9whb7d7h996rzq8k7q7cv2","statementId":88,"updateCount":1,"metadata":{"serverAddress":"c497a18abde6:8765"}}],"metadata":{"serverAddress":"c497a18abde6:8765"}}!,
            q!{"results":[{"connectionId":"yylc41tx9whb7d7h996rzq8k7q7cv2","statementId":90,"ownStatement":true,"signature":{"columns":[{"searchable":true,"signed":true,"displaySize":40,"label":"ID","columnName":"ID","tableName":"TEST","readOnly":true,"columnClassName":"java.lang.Long","type":{"id":4294967291,"name":"BIGINT","rep":"PRIMITIVE_LONG"}},{"ordinal":1,"searchable":true,"nullable":1,"displaySize":40,"label":"TEXT","columnName":"TEXT","tableName":"TEST","readOnly":true,"columnClassName":"java.lang.String","type":{"id":12,"name":"VARCHAR","rep":"STRING"}}],"cursorFactory":{"style":"LIST"}},"firstFrame":{"done":true,"rows":[{"value":[{"value":[{"type":"LONG","numberValue":1}],"scalarValue":{"type":"LONG","numberValue":1}},{"value":[{"type":"STRING","stringValue":"foo"}],"scalarValue":{"type":"STRING","stringValue":"foo"}}]}]},"updateCount":18446744073709551615,"metadata":{"serverAddress":"c497a18abde6:8765"}}],"metadata":{"serverAddress":"c497a18abde6:8765"}}!
        ]);
    }

    my $sth = $dbh->prepare(q{UPSERT INTO TEST VALUES (1, 'foo')});
    isnt $sth, undef, 'sth is defined';

    $ret = $sth->execute;
    is $ret, 1, 'number of inserted rows';

    $sth = $dbh->prepare(q{SELECT * FROM TEST});
    isnt $sth, undef, 'sth is defined';

    $ret = $sth->execute;
    is $ret, 1, 'execute is successfully';

    my $row = $sth->fetchrow_arrayref;
    is_deeply $row, [1, 'foo'], 'check row';

    $row = $sth->fetchrow_arrayref;
    is $row, undef, 'no more rows';
};

subtest 'prepare & execute with params' => sub {
    if ($is_mock) {
        mock_prepare_seq([
            q!{"statement":{"connectionId":"pwwfyg3517k0pwn9ce0n3k0jpmbthw","id":8,"signature":{"sql":"UPSERT INTO TEST VALUES (?, ?)","parameters":[{"parameterType":4294967291,"typeName":"BIGINT","className":"java.lang.Long","name":"?1"},{"parameterType":12,"typeName":"VARCHAR","className":"java.lang.String","name":"?2"}],"cursorFactory":{"style":"LIST"}}},"metadata":{"serverAddress":"c497a18abde6:8765"}}!,
            q!{"statement":{"connectionId":"pwwfyg3517k0pwn9ce0n3k0jpmbthw","id":9,"signature":{"columns":[{"searchable":true,"signed":true,"displaySize":40,"label":"ID","columnName":"ID","tableName":"TEST","readOnly":true,"columnClassName":"java.lang.Long","type":{"id":4294967291,"name":"BIGINT","rep":"PRIMITIVE_LONG"}},{"ordinal":1,"searchable":true,"nullable":1,"displaySize":40,"label":"TEXT","columnName":"TEXT","tableName":"TEST","readOnly":true,"columnClassName":"java.lang.String","type":{"id":12,"name":"VARCHAR","rep":"STRING"}}],"sql":"SELECT * FROM TEST WHERE ID = ?","parameters":[{"parameterType":4294967291,"typeName":"BIGINT","className":"java.lang.Long","name":"?1"}],"cursorFactory":{"style":"LIST"}}},"metadata":{"serverAddress":"c497a18abde6:8765"}}!
        ]);
        mock_execute_seq([
            q!{"results":[{"connectionId":"pwwfyg3517k0pwn9ce0n3k0jpmbthw","statementId":8,"ownStatement":true,"updateCount":1,"metadata":{"serverAddress":"c497a18abde6:8765"}}],"metadata":{"serverAddress":"c497a18abde6:8765"}}!,
            q!{"results":[{"connectionId":"pwwfyg3517k0pwn9ce0n3k0jpmbthw","statementId":9,"ownStatement":true,"signature":{"columns":[{"searchable":true,"signed":true,"displaySize":40,"label":"ID","columnName":"ID","tableName":"TEST","readOnly":true,"columnClassName":"java.lang.Long","type":{"id":4294967291,"name":"BIGINT","rep":"PRIMITIVE_LONG"}},{"ordinal":1,"searchable":true,"nullable":1,"displaySize":40,"label":"TEXT","columnName":"TEXT","tableName":"TEST","readOnly":true,"columnClassName":"java.lang.String","type":{"id":12,"name":"VARCHAR","rep":"STRING"}}],"sql":"SELECT * FROM TEST WHERE ID = ?","parameters":[{"parameterType":4294967291,"typeName":"BIGINT","className":"java.lang.Long","name":"?1"}],"cursorFactory":{"style":"LIST"}},"firstFrame":{"done":true,"rows":[{"value":[{"value":[{"type":"LONG","numberValue":2}],"scalarValue":{"type":"LONG","numberValue":2}},{"value":[{"type":"STRING","stringValue":"bar"}],"scalarValue":{"type":"STRING","stringValue":"bar"}}]}]},"updateCount":18446744073709551615,"metadata":{"serverAddress":"c497a18abde6:8765"}}],"metadata":{"serverAddress":"c497a18abde6:8765"}}!
        ]);
    }
    my $sth = $dbh->prepare(q{UPSERT INTO TEST VALUES (?, ?)});
    isnt $sth, undef, 'sth is defined';

    $ret = $sth->execute(2, 'bar');
    is $ret, 1, 'number of inserted rows';

    $sth = $dbh->prepare(q{SELECT * FROM TEST WHERE ID = ?});
    isnt $sth, undef, 'sth is defined';

    $ret = $sth->execute(2);
    is $ret, 1, 'execute is successfully';

    my $row = $sth->fetchall_arrayref;
    is_deeply $row, [[2, 'bar']], 'check rows';
};

subtest 'fetch & hash slice result' => sub {
    if ($is_mock) {
        mock_prepare_seq([
            q!{"statement":{"connectionId":"pwwfyg3517k0pwn9ce0n3k0jpmbthw","id":8,"signature":{"sql":"UPSERT INTO TEST VALUES (?, ?)","parameters":[{"parameterType":4294967291,"typeName":"BIGINT","className":"java.lang.Long","name":"?1"},{"parameterType":12,"typeName":"VARCHAR","className":"java.lang.String","name":"?2"}],"cursorFactory":{"style":"LIST"}}},"metadata":{"serverAddress":"c497a18abde6:8765"}}!,
            q!{"statement":{"connectionId":"pwwfyg3517k0pwn9ce0n3k0jpmbthw","id":9,"signature":{"columns":[{"searchable":true,"signed":true,"displaySize":40,"label":"ID","columnName":"ID","tableName":"TEST","readOnly":true,"columnClassName":"java.lang.Long","type":{"id":4294967291,"name":"BIGINT","rep":"PRIMITIVE_LONG"}},{"ordinal":1,"searchable":true,"nullable":1,"displaySize":40,"label":"TEXT","columnName":"TEXT","tableName":"TEST","readOnly":true,"columnClassName":"java.lang.String","type":{"id":12,"name":"VARCHAR","rep":"STRING"}}],"sql":"SELECT * FROM TEST WHERE ID = ?","parameters":[{"parameterType":4294967291,"typeName":"BIGINT","className":"java.lang.Long","name":"?1"}],"cursorFactory":{"style":"LIST"}}},"metadata":{"serverAddress":"c497a18abde6:8765"}}!
        ]);
        mock_execute_seq([
            q!{"results":[{"connectionId":"pwwfyg3517k0pwn9ce0n3k0jpmbthw","statementId":8,"ownStatement":true,"updateCount":1,"metadata":{"serverAddress":"c497a18abde6:8765"}}],"metadata":{"serverAddress":"c497a18abde6:8765"}}!,
            q!{"results":[{"connectionId":"3c2e0sfi3yt05u9r7f3erd3muhrp3a","statementId":109,"ownStatement":true,"signature":{"columns":[{"searchable":true,"signed":true,"displaySize":40,"label":"ID","columnName":"ID","tableName":"TEST","readOnly":true,"columnClassName":"java.lang.Long","type":{"id":4294967291,"name":"BIGINT","rep":"PRIMITIVE_LONG"}},{"ordinal":1,"searchable":true,"nullable":1,"displaySize":40,"label":"TEXT","columnName":"TEXT","tableName":"TEST","readOnly":true,"columnClassName":"java.lang.String","type":{"id":12,"name":"VARCHAR","rep":"STRING"}}],"sql":"SELECT * FROM TEST WHERE ID > ?","parameters":[{"parameterType":4294967291,"typeName":"BIGINT","className":"java.lang.Long","name":"?1"}],"cursorFactory":{"style":"LIST"}},"firstFrame":{"rows":[{"value":[{"value":[{"type":"LONG","numberValue":1}],"scalarValue":{"type":"LONG","numberValue":1}},{"value":[{"type":"STRING","stringValue":"foo"}],"scalarValue":{"type":"STRING","stringValue":"foo"}}]}]},"updateCount":18446744073709551615,"metadata":{"serverAddress":"c497a18abde6:8765"}}],"metadata":{"serverAddress":"c497a18abde6:8765"}}!
        ]);
        mock_fetch_seq([
            q!{"frame":{"rows":[{"value":[{"value":[{"type":"LONG","numberValue":2}],"scalarValue":{"type":"LONG","numberValue":2}},{"value":[{"type":"STRING","stringValue":"bar"}],"scalarValue":{"type":"STRING","stringValue":"bar"}}]}]},"metadata":{"serverAddress":"c497a18abde6:8765"}}!,
            q!{"frame":{"rows":[{"value":[{"value":[{"type":"LONG","numberValue":3}],"scalarValue":{"type":"LONG","numberValue":3}},{"value":[{"type":"STRING","stringValue":"baz"}],"scalarValue":{"type":"STRING","stringValue":"baz"}}]}]},"metadata":{"serverAddress":"c497a18abde6:8765"}}!,
            q!{"frame":{"done":true},"metadata":{"serverAddress":"c497a18abde6:8765"}}!
        ]);
    }
    my $ret = $dbh->do(q{UPSERT INTO TEST VALUES (?, ?)}, undef, 3, 'baz');
    is $ret, 1, 'check upsert';

    # set to fetch 1 row per request
    no warnings 'redefine';
    local *DBD::Avatica::st::FETCH_SIZE = sub () { 1 };

    # result should be 3 rows
    my $rows = $dbh->selectall_arrayref(q{SELECT * FROM TEST WHERE ID > ?}, {Slice => {}}, 0);
    is_deeply $rows, [{'ID' => 1, 'TEXT' => 'foo'}, {'ID' => 2, 'TEXT' => 'bar'}, {'ID' => 3, 'TEXT' => 'baz'}], 'check array of hashes';
};

done_testing;
