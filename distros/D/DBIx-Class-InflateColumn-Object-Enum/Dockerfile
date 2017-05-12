FROM jmmills/dist-zilla
MAINTAINER = Jason M. Mills <jmmills@cpan.org>
WORKDIR /dist
ADD . /dist/
RUN dzil authordeps --missing | cpanm
RUN dzil listdeps | cpanm
ENTRYPOINT ["/usr/bin/perl", "/usr/local/bin/dzil"]
