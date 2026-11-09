# The PostgreSQL extension image for DBIO live tests: src.ci/srv/postgres:18.
#
# DBIO::Test::Kubernetes starts it as the 'pg-ext' database (env prefix
# DBIO_TEST_PG_EXT); the dbio-postgresql test pod uses it for pgvector. It is
# PostgreSQL 18 with the three extensions the family's live suites create:
#
#   age      -- dbio-postgresql-age (Cypher), and the AGE + PostGIS layer
#               stacking tests (both extensions on one schema)
#   postgis  -- dbio-postgresql-postgis
#   vector   -- dbio-postgresql loader / Cake tests (pgvector)
#
# pgcrypto and hstore are PostgreSQL contrib and ship with the base image.
#
# Reconstructed 2026-09-26 (core karr k223). The original build recipe was
# lost and the tag had vanished from src.ci. The base is the public
# apache/age image (Debian, PostgreSQL 18 from PGDG + AGE 1.7). Its PGDG apt
# source provides PostGIS and pgvector built for the same server major.
#
# Build and publish (throttled -- the build machine is shared):
#   nice -n 19 docker build -f xbin/k8s/pg-ext.Dockerfile -t src.ci/srv/postgres:18 xbin/k8s
#   docker push src.ci/srv/postgres:18
#
# On a host whose default buildx builder uses the docker-container driver and
# cannot boot BuildKit (crun: "create /sys/fs/cgroup/docker: Permission
# denied"), prefix the build with DOCKER_BUILDKIT=0 for the daemon's builder.
#
# Check the extensions without starting a server:
#   docker run --rm --cpus 0.5 -m 256m --entrypoint sh src.ci/srv/postgres:18 \
#     -c 'ls /usr/share/postgresql/18/extension | grep -E "^(age|postgis|vector)\.control"'

FROM apache/age:latest

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        "postgresql-${PG_MAJOR}-postgis-3" \
        "postgresql-${PG_MAJOR}-pgvector"; \
    rm -rf /var/lib/apt/lists/*
