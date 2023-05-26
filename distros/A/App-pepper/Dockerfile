FROM perl:latest
RUN apt-get update
RUN cpanm -n App::pepper Term::ReadLine::Gnu
ENTRYPOINT ["/usr/local/bin/pepper"]
