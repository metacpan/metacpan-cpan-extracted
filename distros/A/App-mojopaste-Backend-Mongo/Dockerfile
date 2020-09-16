FROM "jhthorsen/mojopaste"

MAINTAINER sklukin@cpan.org

WORKDIR /app-mojopaste-master

COPY ./lib /app-mojopaste-master/lib

ENV PERLLIB '/app-mojopaste-master/lib'

RUN apk add -U make \
  && cpanm -M https://cpan.metacpan.org Mojolicious::Plugin::Mango --no-wget

