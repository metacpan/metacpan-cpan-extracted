#!/usr/bin/env bash
set -euo pipefail
HOST="${REDIS_HOST:-localhost}"
PORT="${REDIS_PORT:-6379}"
redis-cli -h "$HOST" -p "$PORT" FLUSHDB
echo "Flushed Redis at ${HOST}:${PORT}"
