#!/bin/bash
set -e

TMPDIR=$(mktemp -d)
CH_PORT=19000

cleanup() {
    if [ -n "$CH_PID" ]; then
        kill $CH_PID 2>/dev/null || true
        wait $CH_PID 2>/dev/null || true
    fi
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

# Check if ClickHouse is already running on default port
if clickhouse-client --query 'select 1' >/dev/null 2>&1; then
    echo "Using existing ClickHouse on port 9000"
    CH_PORT=9000
    perl bench/wide_table_benchmark.pl
    exit 0
fi

echo "Starting temporary ClickHouse server..."

mkdir -p "$TMPDIR/tmp" "$TMPDIR/user_files" "$TMPDIR/format_schemas"
cat > "$TMPDIR/config.xml" << EOF
<?xml version="1.0"?>
<clickhouse>
    <logger><level>error</level><console>1</console></logger>
    <tcp_port>$CH_PORT</tcp_port>
    <http_port>19001</http_port>
    <path>$TMPDIR/</path>
    <tmp_path>$TMPDIR/tmp/</tmp_path>
    <user_files_path>$TMPDIR/user_files/</user_files_path>
    <format_schema_path>$TMPDIR/format_schemas/</format_schema_path>
    <users>
        <default>
            <password></password>
            <networks><ip>::/0</ip></networks>
            <profile>default</profile>
            <quota>default</quota>
        </default>
    </users>
    <profiles><default></default></profiles>
    <quotas><default></default></quotas>
</clickhouse>
EOF

clickhouse-server --config-file "$TMPDIR/config.xml" 2>/dev/null &
CH_PID=$!

echo "Waiting for server..."
for i in {1..30}; do
    if clickhouse-client --port $CH_PORT --query 'select 1' >/dev/null 2>&1; then
        echo "Server ready on port $CH_PORT"
        break
    fi
    sleep 0.5
done

CH_PORT=$CH_PORT perl bench/wide_table_benchmark.pl
