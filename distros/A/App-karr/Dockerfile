FROM perl:5.40-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake pkg-config \
    libssl-dev zlib1g-dev libssh2-1-dev libffi-dev git \
    && rm -rf /var/lib/apt/lists/*

COPY . /tmp/karr-src

# Install Alien::FFI against the system libffi (libffi-dev above) up front, so it
# links the packaged libffi.so instead of fetching a libffi tarball from a GitHub
# release page — that download is fragile and rate-limited (Alien::Build itself
# warns the release-page negotiator "will typically not work"), and it is what
# broke CI builds intermittently.
RUN ALIEN_INSTALL_TYPE=system cpanm --notest Alien::FFI

# Force Alien::Libgit2 to vendor libgit2 (share build) so the runtime image is
# self-contained — the slim runtime has no system libgit2 to dynamically link.
ENV ALIEN_INSTALL_TYPE=share

RUN cpanm --notest --installdeps /tmp/karr-src \
    && cpanm --notest /tmp/karr-src \
    && rm -rf /tmp/karr-src

FROM perl:5.40-slim AS runtime-base

# git + runtime shared libs: the vendored libgit2.so links against OpenSSL
# (HTTPS), libssh2 (SSH) and zlib (compression); FFI::Platypus now links the
# system libffi (see builder stage), so libffi8 must be present at runtime too.
#
# openssh-client is what the git-CLI fallback forks for an ssh:// remote.
# libssh2 covers the libgit2 path, but the fallback exists precisely for the
# cases libgit2 cannot do -- ssh-config, ProxyCommand -- and without an ssh
# binary it could never take any of them: git answered `cannot run ssh: No such
# file or directory` and the board was simply unreachable.
RUN apt-get update && apt-get install -y --no-install-recommends \
    git gosu passwd openssh-client \
    libssl3 libssh2-1 zlib1g libffi8 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/perl5/site_perl/ /usr/local/lib/perl5/site_perl/
COPY --from=builder /usr/local/bin/ /usr/local/bin/

# /work only. The home directory is created by whoever ends up owning it:
# runtime-user's `useradd -m`, and for runtime-root the entrypoint, which has to
# mkdir it anyway for the uid it is about to drop to. Creating it here just made
# useradd warn about a home it had been told to create.
RUN mkdir -p /work

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
    && chown -R ${KARR_UID}:${KARR_GID} /work

USER karr

ENTRYPOINT ["karr"]
