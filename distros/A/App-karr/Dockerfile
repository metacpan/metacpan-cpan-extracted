FROM perl:5.40-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libssl-dev git \
    && rm -rf /var/lib/apt/lists/*

COPY . /tmp/karr-src

RUN cpanm --notest --installdeps /tmp/karr-src \
    && cpanm --notest /tmp/karr-src \
    && rm -rf /tmp/karr-src

FROM perl:5.40-slim AS runtime-base

RUN apt-get update && apt-get install -y --no-install-recommends git gosu passwd \
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
