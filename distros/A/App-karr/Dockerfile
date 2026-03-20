FROM perl:5.40-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libssl-dev git \
    && rm -rf /var/lib/apt/lists/*

ARG KARR_TGZ="App-karr.tar.gz"

COPY ${KARR_TGZ} /tmp/karr.tar.gz

RUN tar -xzf /tmp/karr.tar.gz -C /tmp --strip-components=1 \
    && cpanm --notest --installdeps /tmp \
    && cpanm --notest /tmp/karr.tar.gz \
    && rm -rf /tmp/*

FROM perl:5.40-slim

RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/perl5/site_perl/ /usr/local/lib/perl5/site_perl/
COPY --from=builder /usr/local/bin/ /usr/local/bin/

ENV GIT_AUTHOR_NAME="karr"
ENV GIT_AUTHOR_EMAIL="karr@localhost"
ENV GIT_COMMITTER_NAME="karr"
ENV GIT_COMMITTER_EMAIL="karr@localhost"

ENTRYPOINT ["karr"]
