# Dockerfile for running DBIO tests inside a Kubernetes cluster.
# Used by: xbin/k8s-test --mode cluster
#
# Build:  docker build -t dbic-test:latest .
# Run:    docker run -e DBICTEST_PG_DSN=... -e DBICTEST_MYSQL_DSN=... dbic-test:latest

FROM perl:5.40

# Install database client libraries
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    libpq-dev default-libmysqlclient-dev libsqlite3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

# Install dependencies + database drivers + coverage tools
RUN cpanm --notest --installdeps . \
    && cpanm --notest DBD::Pg DBD::mysql DBD::SQLite Devel::Cover \
    && rm -rf ~/.cpanm

CMD ["prove", "-l", "t/"]
