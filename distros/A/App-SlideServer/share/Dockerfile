FROM alpine:latest

RUN apk add --no-cache perl gcc make musl-dev

RUN apk add --no-cache perl-app-cpanminus perl-mojolicious perl-log-any perl-dev perl-module-build perl-file-pushd

RUN cpanm Linux::Inotify2 App::SlideServer

EXPOSE 80

ENTRYPOINT ["/usr/bin/env"]
CMD ["slide-server","daemon","-m","production","-l","http://*:80"]
