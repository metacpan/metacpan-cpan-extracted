FROM perl:5.40-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake pkg-config \
    libssl-dev zlib1g-dev libssh2-1-dev git \
    && rm -rf /var/lib/apt/lists/*

COPY . /tmp/karr-src

# Force Alien::Libgit2 to vendor libgit2 (share build) so the runtime image is
# self-contained — the slim runtime has no system libgit2 to dynamically link.
ENV ALIEN_INSTALL_TYPE=share

RUN cpanm --notest --installdeps /tmp/karr-src \
    && cpanm --notest /tmp/karr-src \
    && rm -rf /tmp/karr-src

FROM perl:5.40-slim AS runtime-base

# git + runtime shared libs the vendored libgit2.so links against
# (OpenSSL for HTTPS, libssh2 for SSH, zlib for compression).
RUN apt-get update && apt-get install -y --no-install-recommends \
    git gosu passwd \
    libssl3 libssh2-1 zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/perl5/site_perl/ /usr/local/lib/perl5/site_perl/
COPY --from=builder /usr/local/bin/ /usr/local/bin/

RUN mkdir -p /home/karr /work

ENV HOME=/home/karr
ENV GIT_AUTHOR_NAME="karr"
ENV GIT_AUTHOR_EMAIL="karr@localhost"
ENV GIT_COMMITTER_NAME="karr"
ENV GIT_COMMITTER_EMAIL="karr@localhost"

WORKDIR /work

FROM runtime-base AS runtime-root

COPY docker/karr-entrypoint.sh /usr/local/bin/karr-entrypoint.sh

RUN chmod +x /usr/local/bin/karr-entrypoint.sh

ENTRYPOINT ["karr-entrypoint.sh"]

FROM runtime-base AS runtime-user

ARG KARR_UID=1000
ARG KARR_GID=1000

RUN groupadd -g ${KARR_GID} karr \
    && useradd -m -d /home/karr -u ${KARR_UID} -g ${KARR_GID} -s /bin/sh karr \
    && chown -R ${KARR_UID}:${KARR_GID} /home/karr /work

USER karr

ENTRYPOINT ["karr"]
