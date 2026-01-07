#!/bin/bash
#
# Reset Redis for PAGI Chat Demo
#
# Clears all chat data (sessions, rooms, messages) for a fresh demo.
# Usage: ./reset-redis.sh [host] [port]
#

REDIS_HOST=${1:-${REDIS_HOST:-localhost}}
REDIS_PORT=${2:-${REDIS_PORT:-6379}}

echo "Resetting Redis at $REDIS_HOST:$REDIS_PORT..."

redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" FLUSHDB

if [ $? -eq 0 ]; then
    echo "Done! Redis cleared for fresh demo."
else
    echo "Error: Could not connect to Redis at $REDIS_HOST:$REDIS_PORT"
    exit 1
fi
