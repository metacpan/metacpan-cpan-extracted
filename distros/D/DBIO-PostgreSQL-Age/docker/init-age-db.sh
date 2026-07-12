#!/bin/bash
# docker/init-age-db.sh — first-start init for the AGE test cluster.
#
# Runs once when the data volume is empty. Creates the dbio_age_test
# database and enables the Apache AGE extension in it. The default
# postgres database is left untouched (pg_cron lives there).
#
# Mounted into the container at /docker-entrypoint-initdb.d/10-age-db.sh
# by docker-compose.yml; the official postgres entrypoint picks it up
# automatically.

set -euo pipefail

psql -v ON_ERROR_STOP=1 -U postgres -d postgres <<'EOSQL'
  -- Dedicated test DB so the live suite can connect by name.
  SELECT 'CREATE DATABASE dbio_age_test'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'dbio_age_test')\gexec
EOSQL

psql -v ON_ERROR_STOP=1 -U postgres -d dbio_age_test <<'EOSQL'
  -- AGE extension lives in shared_preload_libraries? No — it is a normal
  -- extension installed by the image's apt-get step. Just CREATE EXTENSION
  -- here and it is ready for the test suite to create graphs and run
  -- Cypher via ag_catalog.cypher().
  CREATE EXTENSION IF NOT EXISTS age;
EOSQL