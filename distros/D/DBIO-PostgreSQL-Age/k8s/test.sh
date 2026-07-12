#!/usr/bin/env bash
# k8s/test.sh — end-to-end test of DBIO::PostgreSQL::Age against a real
# Apache AGE cluster running in Kubernetes. The deployment uses the same
# image we run locally (apache/age:latest, which ships PG 18 + AGE 1.7), so
# dev parity is real.
#
# Flow:
#   1. Detect kubectl context and warn if it looks like a production cluster.
#   2. Apply the postgres deployment + service.
#   3. Wait until the pod is ready.
#   4. Create dbio_age_test database and enable AGE in it.
#   5. Port-forward 127.0.0.1:5432 -> service:5432 (background).
#   6. Run prove -lr t/ with the right DSN env.
#   7. Always tear down the port-forward, and delete the k8s resources on
#      exit unless KEEP=1 is set (handy for post-mortem inspection).
#
# Usage:
#   k8s/test.sh           # full cycle
#   KEEP=1 k8s/test.sh    # leave cluster resources behind for inspection
#   CONTEXT=kind-db k8s/test.sh   # pin a specific kubectl context

set -euo pipefail

cd "$(dirname "$0")/.."

CONTEXT="${CONTEXT:-}"
KEEP="${KEEP:-}"
LOCAL_PORT="${LOCAL_PORT:-5432}"
K8S_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- kubectl wrapper that pins context if given --------------------------------
K() {
  if [ -n "$CONTEXT" ]; then
    kubectl --context "$CONTEXT" "$@"
  else
    kubectl "$@"
  fi
}

# --- safety: never run against obvious prod contexts --------------------------
current_ctx="$(kubectl config current-context 2>/dev/null || true)"
if printf '%s' "$current_ctx" | grep -Eq '(^|-)(prod|production|staging)(-|$)'; then
  echo "refusing to run against context '$current_ctx' (looks like prod/staging)"
  echo "set CONTEXT=<safe> to override"
  exit 2
fi
echo "==> kubectl context: ${current_ctx:-<none>}"

# --- safety: local port must be free before we deploy anything ----------------
# If LOCAL_PORT is taken, `kubectl port-forward` later fails to bind, the live
# tests skip against a dead socket, and TAP still reports PASS — a false green.
# Fail fast, before spinning up a pod.
if command -v ss >/dev/null 2>&1 && ss -ltn 2>/dev/null | grep -q ":${LOCAL_PORT} "; then
  echo "local port ${LOCAL_PORT} is already in use — set LOCAL_PORT=<free port> and retry"
  exit 1
fi

# --- teardown -----------------------------------------------------------------
POD=""
PF_PID=""
cleanup() {
  rc=$?
  if [ -n "$PF_PID" ]; then
    kill "$PF_PID" 2>/dev/null || true
    wait "$PF_PID" 2>/dev/null || true
  fi
  if [ -z "$KEEP" ]; then
    K delete -f "$K8S_DIR/postgres.yaml" --ignore-not-found >/dev/null 2>&1 || true
    echo "==> k8s resources deleted"
  else
    echo "==> KEEP set — leaving deployment + service in cluster"
  fi
  exit $rc
}
trap cleanup EXIT INT TERM

# --- 1. apply -----------------------------------------------------------------
echo "==> applying k8s/postgres.yaml"
K apply -f "$K8S_DIR/postgres.yaml"

# --- 2. wait for ready --------------------------------------------------------
echo "==> waiting for pod to appear (label app=dbio-age-pg)"
for i in $(seq 1 30); do
  POD="$(K get pod -l app=dbio-age-pg -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  if [ -n "$POD" ]; then break; fi
  sleep 2
done
if [ -z "$POD" ]; then
  echo "pod never appeared; describe deployment:"
  K describe deployment dbio-age-pg || true
  exit 1
fi
echo "==> pod: $POD"

echo "==> waiting for pod to be ready"
K wait --for=condition=ready "pod/$POD" --timeout=180s

# --- 3. wait for postgres inside the pod --------------------------------------
echo "==> waiting for postgres inside the pod"
for i in $(seq 1 30); do
  if K exec "$POD" -- pg_isready -U postgres -q 2>/dev/null; then
    echo "    ready after ${i}*2s"; break
  fi
  sleep 2
done

# --- 4. create db + enable AGE ------------------------------------------------
# CREATE DATABASE cannot run inside an explicit transaction (and DO $$ ...
# END $$; is one), so we issue it as a plain statement and tolerate the
# "already exists" error on re-runs.
echo "==> creating dbio_age_test database"
K exec "$POD" -- psql -U postgres -d postgres \
  -c "CREATE DATABASE dbio_age_test" 2>&1 \
  | grep -v '^CREATE DATABASE' || true

# Force the catalog commit to be visible before we open a new connection.
K exec "$POD" -- psql -U postgres -d postgres -tAc \
  "SELECT pg_sleep(0.3); SELECT 1;" >/dev/null

echo "==> enabling AGE extension"
K exec "$POD" -- psql -U postgres -d dbio_age_test \
  -c "CREATE EXTENSION IF NOT EXISTS age;"

K exec "$POD" -- psql -U postgres -d dbio_age_test -tAc \
  "SELECT extname || ' ' || extversion FROM pg_extension WHERE extname = 'age'" \
  | sed 's/^/    AGE: /'

# --- 5. port-forward ----------------------------------------------------------
echo "==> port-forwarding 127.0.0.1:${LOCAL_PORT} -> dbio-age-pg:5432"
K port-forward "$POD" "${LOCAL_PORT}:5432" >/tmp/dbio-age-pf.log 2>&1 &
PF_PID=$!

# Wait for the forward to be live, and HARD-FAIL if it never comes up. A
# forward that never binds must not fall through to a green run: with no
# reachable DB the live tests skip_all, which TAP would count as success.
forward_ready=""
for i in $(seq 1 15); do
  if pg_isready -h 127.0.0.1 -p "$LOCAL_PORT" -U postgres -q 2>/dev/null; then
    forward_ready=1; echo "    forward ready"; break
  fi
  sleep 1
done
if [ -z "$forward_ready" ]; then
  echo "port-forward to 127.0.0.1:${LOCAL_PORT} never became ready — refusing to run"
  echo "    (a skipped live suite would otherwise be misreported as PASS)"
  echo "--- kubectl port-forward log -------------------------------------------------"
  cat /tmp/dbio-age-pf.log 2>/dev/null || true
  echo "------------------------------------------------------------------------------"
  exit 1
fi

# --- 6. run the perl test suite ----------------------------------------------
echo "==> running prove -lr t/"
DBIO_TEST_PG_DSN="dbi:Pg:dbname=dbio_age_test;host=127.0.0.1;port=${LOCAL_PORT}" \
DBIO_TEST_PG_USER=postgres \
DBIO_TEST_PG_PASS=dbio_age_test \
  prove -lr t/

echo "==> ALL TESTS PASSED against k8s cluster ($current_ctx)"
