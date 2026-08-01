ARG APP_BLURFILL_VERSION=0.1.0
FROM davorg/app-blurfill:${APP_BLURFILL_VERSION}

WORKDIR /opt/app-blurfill-web
COPY . .

RUN cpanm --notest --installdeps . \
    && perl Makefile.PL \
    && make install \
    && rm -rf /root/.cpanm /opt/app-blurfill-web/blib

EXPOSE 8080

LABEL org.opencontainers.image.title="App::BlurFill::Web" \
      org.opencontainers.image.source="https://github.com/davorg-cpan/app-blurfill-web"

CMD ["plackup", "-s", "Starman", "-a", "bin/app.psgi", "-o", "0.0.0.0", "-p", "8080"]
