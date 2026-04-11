#!/bin/bash
# Integration test: Lock server/client protocol via Docker containers
# Run from the repo root: bash t/integration/lock-protocol.sh

# Do not use set -e -- we handle errors explicitly

IMAGE="aep-test"
SOCKET_VOL="/tmp/aep-integration-test"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; ((PASS++)); }
fail() { echo "  FAIL: $1"; ((FAIL++)); }

echo "=== AEP Lock Protocol Integration Tests ==="
echo ""

# Clean up from any previous run
docker rm -f aep-int-server aep-int-db aep-int-app 2>/dev/null || true
sudo rm -rf "$SOCKET_VOL" && mkdir -p "$SOCKET_VOL"

# --- Test 1: Server starts and creates socket ---
echo "[Test 1] Lock server starts and creates socket"
docker run --rm -d --name aep-int-server -v "$SOCKET_VOL:/tmp" \
    "$IMAGE" --lock-server --lock-server-order "db,app" --lock-server-exhaust-action exit \
    >/dev/null 2>&1

sleep 2
if [ -S "$SOCKET_VOL/aep.sock" ]; then
    pass "Socket file created"
else
    fail "Socket file not found"
fi

# --- Test 2: Client connects, receives run, executes command ---
echo "[Test 2] Lock client 'db' connects and receives run signal"
DB_OUTPUT=$(timeout 15 docker run --rm --name aep-int-db -v "$SOCKET_VOL:/tmp" \
    "$IMAGE" --lock-client --lock-id db \
    --command echo --command-args "db-started" \
    --lock-trigger "none:time:1000" --command-norestart 2>&1) || true

echo "$DB_OUTPUT" | grep -q "Received 'run'" && pass "Client received run signal" || fail "Client did not receive run"
echo "$DB_OUTPUT" | grep -q "Starting command: echo" && pass "Client started command" || fail "Client did not start command"
echo "$DB_OUTPUT" | grep -q "Lock trigger fired" && pass "Lock trigger fired" || fail "Lock trigger did not fire"
echo "$DB_OUTPUT" | grep -q "db-started" && pass "Command output captured" || fail "Command output missing"

# --- Test 3: Second client gets its turn after first ---
echo "[Test 3] Lock client 'app' gets run after 'db' completes"

# Check server received trigger_ok and advanced
SERVER_LOGS=$(docker logs aep-int-server 2>&1)
echo "$SERVER_LOGS" | grep -q "trigger success" && pass "Server received trigger_ok from db" || fail "Server did not receive trigger_ok"

APP_OUTPUT=$(timeout 15 docker run --rm --name aep-int-app -v "$SOCKET_VOL:/tmp" \
    "$IMAGE" --lock-client --lock-id app \
    --command echo --command-args "app-started" \
    --lock-trigger "none:time:1000" --command-norestart 2>&1) || true

echo "$APP_OUTPUT" | grep -q "Received 'run'" && pass "Second client received run" || fail "Second client did not receive run"
echo "$APP_OUTPUT" | grep -q "app-started" && pass "Second client command output" || fail "Second client output missing"

# --- Test 4: Standalone command execution ---
echo "[Test 4] Standalone command execution"
STANDALONE=$(docker run --rm "$IMAGE" --command echo --command-args "standalone-test" --command-norestart 2>&1)
echo "$STANDALONE" | grep -q "standalone mode" && pass "Standalone mode entered" || fail "Standalone mode not entered"
echo "$STANDALONE" | grep -q "standalone-test" && pass "Standalone output correct" || fail "Standalone output missing"

# --- Test 5: Command restart ---
echo "[Test 5] Command restart logic"
RESTART=$(docker run --rm "$IMAGE" --command /bin/false --command-restart 2 --command-restart-delay 100 2>&1)
RESTART_COUNT=$(echo "$RESTART" | grep -c "restarting in")
[ "$RESTART_COUNT" -eq 2 ] && pass "Restarted exactly 2 times" || fail "Expected 2 restarts, got $RESTART_COUNT"
echo "$RESTART" | grep -q "max restarts" && pass "Max restarts reached" || fail "Max restarts message missing"

# --- Clean up ---
docker rm -f aep-int-server 2>/dev/null || true
sudo rm -rf "$SOCKET_VOL"

# --- Summary ---
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
