# jhthorsen/app-proxyforurl
#
# BUILD: docker build --no-cache --rm -t jhthorsen/app-proxyforurl .
# RUN:   docker run -it --rm -p 8080:3000 jhthorsen/app-proxyforurl
FROM alpine:3.5
MAINTAINER jhthorsen@cpan.org

RUN apk add --no-cache curl openssl perl perl-io-socket-ssl perl-net-ssleay wget \
 && apk add --no-cache --virtual builddeps build-base perl-dev \
 && curl -L https://github.com/jhthorsen/app-proxyforurl/archive/main.tar.gz | tar xvz \
 && curl -L https://cpanmin.us | perl - App::cpanminus \
 && cpanm -M https://cpan.metacpan.org --installdeps ./app-proxyforurl-main \
 && apk del builddeps \
 && rm -rf /root/.cpanm /var/cache/apk/*

ENV MOJO_MODE production
ENV PROXYFORURL_TEMPLATES=/templates

EXPOSE 8080

ENTRYPOINT ["/app-proxyforurl-main/script/proxyforurl", "prefork", "-l", "http://*:8080"]
