# The DBIO test runner: perl plus every DBD and client library of the family,
# so one image runs any driver dist's suite against the cluster databases.
#
#   perl 5.40 (Debian trixie, like the dev box's perl 5.40)
#   DBD::Pg, DBD::mysql, DBD::MariaDB, DBD::SQLite
#   DBD::Oracle        + Oracle Instant Client 23.26 (basic + sdk)
#   DBD::ODBC          + unixODBC, FreeTDS (tdsodbc), registered as 'FreeTDS'
#   DBD::Sybase        + FreeTDS (ct-lib)
#   DBD::DB2           + IBM Db2 clidriver 11.5.9 (odbc_cli)
#   DBD::Firebird      + libfbclient2 (Firebird 3.0 client, speaks to 5.0)
#   DBD::DuckDB        + Alien::DuckDB 0.04 (libduckdb 1.5.3)
#   clickhouse         the ClickHouse client; dbio-clickhouse rides a
#                      MySQL-wire DBD (no native DBD::ClickHouse), so
#                      DBD::mysql/MariaDB above are its Perl way in.
#   Informix runs on the host: DBD::Informix links against the Informix
#                      Client SDK installed there ($INFORMIXDIR), so
#                      dbio-informix's suite runs outside this image.
#
# The family code itself is NOT in the image: run-suite mounts the driver
# checkout and puts the checkouts on PERL5LIB. What is baked in are the
# pure-Perl dependencies (cpanfile next to this file).
#
# Build (throttled -- the build machine is shared; one build at a time):
#   DOCKER_HOST=unix:///var/run/docker.sock \
#   nice -n 19 docker build --memory 4g -t dbio-test-runner:local \
#     -f maint/test-runner/Dockerfile maint/test-runner
# On a host whose default buildx builder cannot boot BuildKit, prefix the
# build with DOCKER_BUILDKIT=0 (see xbin/k8s/pg-ext.Dockerfile).
#
# Run a suite:        maint/test-runner/run-suite DIR [prove args]
# Check the ways:     maint/test-runner/check-ways
#
# XS modules are built with the Perl default flags, never -march=native
# (illegal-instruction trouble on the cluster's older CPUs).

FROM perl:5.40

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        build-essential pkg-config unzip curl ca-certificates \
        libpq-dev libmariadb-dev libmariadb-dev-compat libsqlite3-dev \
        unixodbc unixodbc-dev freetds-dev freetds-bin tdsodbc \
        libaio1t64 firebird-dev libfbclient2 libtommath1 \
        libssl-dev zlib1g-dev libxml2-dev libexpat1-dev; \
    ln -s libaio.so.1t64 /usr/lib/x86_64-linux-gnu/libaio.so.1; \
    rm -rf /var/lib/apt/lists/*

# Oracle Instant Client 23.26, basic + sdk, straight from Oracle (no login).
# The sdk is needed to build DBD::Oracle; both stay in /opt/oracle.
ARG IC=23.26.0.0.0
RUN set -eux; mkdir /tmp/ic; cd /tmp/ic; \
    curl -fsSLO https://download.oracle.com/otn_software/linux/instantclient/2326000/instantclient-basic-linux.x64-${IC}.zip; \
    curl -fsSLO https://download.oracle.com/otn_software/linux/instantclient/2326000/instantclient-sdk-linux.x64-${IC}.zip; \
    mkdir -p /opt/oracle; \
    unzip -q instantclient-basic-linux.x64-${IC}.zip -d /opt/oracle; \
    unzip -qo instantclient-sdk-linux.x64-${IC}.zip -d /opt/oracle; \
    ln -s /opt/oracle/instantclient_23_26 /opt/oracle/ic; \
    echo /opt/oracle/ic > /etc/ld.so.conf.d/oracle.conf; ldconfig; \
    rm -rf /tmp/ic
ENV ORACLE_HOME=/opt/oracle/ic LD_LIBRARY_PATH=/opt/oracle/ic

# IBM Db2 clidriver (odbc_cli) 11.5.9, from IBM's public download site.
RUN set -eux; mkdir -p /opt/ibm; cd /opt/ibm; \
    curl -fsSL https://public.dhe.ibm.com/ibmdl/export/pub/software/data/db2/drivers/odbc_cli/v11.5.9/linuxx64_odbc_cli.tar.gz | tar xz; \
    echo /opt/ibm/clidriver/lib > /etc/ld.so.conf.d/db2.conf; ldconfig
ENV DB2_HOME=/opt/ibm/clidriver IBM_DB_HOME=/opt/ibm/clidriver

# ClickHouse client 25.8.9.20 (LTS), static binary from packages.clickhouse.com.
RUN set -eux; mkdir /tmp/ch; cd /tmp/ch; \
    curl -fsSL https://packages.clickhouse.com/tgz/lts/clickhouse-common-static-25.8.9.20-amd64.tgz | tar xz; \
    install -m 0755 clickhouse-common-static-25.8.9.20/usr/bin/clickhouse /usr/local/bin/clickhouse; \
    ln -s clickhouse /usr/local/bin/clickhouse-client; rm -rf /tmp/ch

# FreeTDS: ODBC driver entry for DBD::ODBC, and the include/lib layout
# DBD::Sybase's Makefile.PL expects under $SYBASE.
RUN set -eux; \
    printf '[FreeTDS]\nDescription=FreeTDS\nDriver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\n' > /etc/odbcinst.ini; \
    mkdir -p /opt/freetds; \
    ln -s /usr/include /opt/freetds/include; \
    ln -s /usr/lib/x86_64-linux-gnu /opt/freetds/lib
ENV SYBASE=/opt/freetds

# The DBDs. Versions float except where a dist pins one (DBD::Pg 3.7.1+,
# DBD::DuckDB 0.16+, Alien::DuckDB 0.04 = libduckdb 1.5.3, DBD::Sybase 1.26+).
# --notest: the suites that matter are the family's own.
RUN cpanm --notest DBD::Pg DBD::SQLite DBD::MariaDB DBD::ODBC
RUN cpanm --notest DBD::mysql || cpanm --notest DBD::mysql@4.052
RUN cpanm --notest DBD::Oracle
RUN cpanm --notest DBD::Sybase
RUN cpanm --notest DBD::DB2
RUN cpanm --notest DBD::Firebird
RUN ALIEN_INSTALL_TYPE=share cpanm --notest Alien::DuckDB@0.04 \
    && cpanm --notest DBD::DuckDB@0.16

COPY cpanfile /tmp/cpanfile
RUN cd /tmp && cpanm --notest --installdeps . \
    && rm -rf /root/.cpanm /tmp/cpanfile

WORKDIR /work
