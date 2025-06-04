FROM perl:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN cpanm -qn App::pepper Term::ReadLine::Gnu
ENTRYPOINT ["/usr/local/bin/pepper"]
