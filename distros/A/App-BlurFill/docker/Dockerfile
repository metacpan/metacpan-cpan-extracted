FROM perl:5.40-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libfreetype6-dev \
    libgif-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/app-blurfill
COPY . .

RUN cpanm --notest --installdeps . \
    && perl Makefile.PL \
    && make install \
    && rm -rf /root/.cpanm /opt/app-blurfill/blib

WORKDIR /work

LABEL org.opencontainers.image.title="App::BlurFill" \
      org.opencontainers.image.source="https://github.com/davorg-cpan/app-blurfill"

CMD ["blurfill"]
