FROM debian:10

RUN apt-get update
RUN apt-get -y upgrade

RUN apt-get -y                                  \
    install                                     \
    m4                                          \
    make                                        \
    gcc                                         \
    autoconf                                    \
    automake                                    \
    libtool                                     \
    bison                                       \
    flex                                        \
    patch                                       \
    perl                                        \
    pkg-config                                  \
    curl                                        \
    file

RUN curl -L https://raw.githubusercontent.com/tokuhirom/Perl-Build/master/perl-build | perl - --noman 5.10.1 /opt/perl_5.10.1

RUN curl -L https://cpanmin.us | perl - App::cpanminus

CMD ["/bin/bash" ]
