FROM	debian:10

RUN	apt-get update &&                       \
        apt-get -y upgrade &&                   \
        apt-get -y install                      \
            perl                                \
            perl-base                           \
            perl-modules                        \
            cpanminus                           \
            gcc                                 \
            tar                                 \
            curl

RUN 	apt-get install -y make
WORKDIR /tmp

COPY    Alien-XPA-0.08.tar.gz .
RUN	cpanm install Alien-XPA-0.08.tar.gz ; true




