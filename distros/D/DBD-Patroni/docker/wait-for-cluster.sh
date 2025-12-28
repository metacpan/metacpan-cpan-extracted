#!/bin/bash
set -e

echo "Waiting for Patroni cluster to be ready..."

MAX_ATTEMPTS=60
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    echo "Attempt $ATTEMPT/$MAX_ATTEMPTS..."

    # Try each Patroni endpoint
    for url in $(echo $PATRONI_URLS | tr ',' ' '); do
        RESPONSE=$(curl -s "$url" 2>/dev/null || echo "{}")

        # Check if we have a leader
        LEADER=$(echo "$RESPONSE" | jq -r '.members[]? | select(.role == "leader") | .host' 2>/dev/null || echo "")

        if [ -n "$LEADER" ]; then
            echo "Found leader: $LEADER"

            # Count running members
            RUNNING=$(echo "$RESPONSE" | jq -r '[.members[]? | select(.state == "running")] | length' 2>/dev/null || echo "0")

            if [ "$RUNNING" -ge 2 ]; then
                echo "Cluster is ready with $RUNNING running members"

                # Wait a bit more for database initialization
                sleep 5

                # Verify database is accessible
                if PGPASSWORD=$PGPASSWORD psql -h "$LEADER" -U "$PGUSER" -d "$PGDATABASE" -c "SELECT 1" >/dev/null 2>&1; then
                    echo "Database is accessible"
                    exit 0
                else
                    echo "Database not yet accessible, waiting..."
                fi
            fi
        fi
    done

    sleep 2
done

echo "Timeout waiting for cluster"
exit 1
