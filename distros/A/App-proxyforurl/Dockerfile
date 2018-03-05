# jhthorsen/app-proxyforurl
#
# BUILD: docker build --no-cache --rm -t jhthorsen/app-proxyforurl .
# RUN:   docker run -it --rm -p 8080:3000 jhthorsen/app-proxyforurl
FROM alpine:3.5
MAINTAINER jhthorsen@cpan.org

RUN apk add -U perl perl-io-socket-ssl \
  && apk add -t builddeps build-base curl perl-dev wget \
  && curl -L https://github.com/jhthorsen/app-proxyforurl/archive/master.tar.gz | tar xvz \
  && curl -L https://cpanmin.us | perl - App::cpanminus \
  && cpanm -M https://cpan.metacpan.org --installdeps ./app-proxyforurl-master \
  && apk del builddeps curl \
  && rm -rf /root/.cpanm /var/cache/apk/*

ENV MOJO_MODE production
EXPOSE 8080

ENTRYPOINT ["/app-proxyforurl-master/script/proxyforurl", "prefork", "-l", "http://*:8080"]
