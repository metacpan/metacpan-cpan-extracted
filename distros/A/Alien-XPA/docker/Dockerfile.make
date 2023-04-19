FROM	debian:10

RUN	apt-get update &&                       \
        apt-get -y upgrade &&                   \
        apt-get -y install                      \
            perl                                \
            perl-base                           \
            perl-doc                            \
            perl-modules                        \
            cpanminus                           \
            gcc                                 \
            tar                                 \
            curl                                \
	    libterm-readline-gnu-perl           \
	    libwww-perl                         \
 	    make                                \
	    git

# required for podman, but not for docker(?)
ENV	TAR_OPTIONS=--no-same-owner
RUN     cpanm -n Dist::Zilla
WORKDIR /tmp/Alien-XPA
COPY    . .
RUN	cpanm -n --installdeps --with-develop .
RUN	perl Makefile.PL
RUN	make test

