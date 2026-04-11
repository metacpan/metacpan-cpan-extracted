FROM perl:5.38-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc make \
    && rm -rf /var/lib/apt/lists/*

RUN cpanm --notest Carton

WORKDIR /opt/aep

COPY cpanfile cpanfile.snapshot ./
COPY vendor/ vendor/
RUN carton install --cached --deployment

COPY . .

RUN chmod +x bin/aep

ENV PERL5LIB="/opt/aep/lib:/opt/aep/local/lib/perl5"

ENTRYPOINT ["perl", "bin/aep"]
