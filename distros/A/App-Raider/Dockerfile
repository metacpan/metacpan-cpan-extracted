# ------------------------------------------------------------------ builder
FROM perl:5.40-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential libssl-dev libreadline-dev git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Dist::Zilla source trees have no Makefile.PL — build a tarball locally
# with `dzil build` and pass the version as a build arg.
ARG RAIDER_VERSION=0.002
COPY App-Raider-${RAIDER_VERSION}.tar.gz /tmp/

RUN cpanm --notest /tmp/App-Raider-${RAIDER_VERSION}.tar.gz \
    && rm -rf /tmp/App-Raider-*.tar.gz ~/.cpanm

# ------------------------------------------------------------------ runtime-base
FROM perl:5.40-slim AS runtime-base

RUN apt-get update && apt-get install -y --no-install-recommends \
        libreadline8 libssl3 git ca-certificates gosu passwd \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/perl5/site_perl/ /usr/local/lib/perl5/site_perl/
COPY --from=builder /usr/local/bin/                 /usr/local/bin/

RUN mkdir -p /home/raider /work
ENV HOME=/home/raider \
    TERM=xterm-256color
WORKDIR /work

# ------------------------------------------------------------------ runtime-root
# Runs as root. Use for interactive sessions where you want to attach to a
# host project tree and match its ownership via a thin entrypoint.
FROM runtime-base AS runtime-root
ENTRYPOINT ["raider"]

# ------------------------------------------------------------------ runtime-user
# Runs as a non-root user. Build with --build-arg RAIDER_UID=$(id -u) to match
# host uid so files written under /work keep your ownership.
FROM runtime-base AS runtime-user
ARG RAIDER_UID=1000
ARG RAIDER_GID=1000
RUN groupadd -g ${RAIDER_GID} raider \
    && useradd -m -d /home/raider -u ${RAIDER_UID} -g ${RAIDER_GID} -s /bin/sh raider \
    && chown -R ${RAIDER_UID}:${RAIDER_GID} /home/raider /work
USER raider
ENTRYPOINT ["raider"]
