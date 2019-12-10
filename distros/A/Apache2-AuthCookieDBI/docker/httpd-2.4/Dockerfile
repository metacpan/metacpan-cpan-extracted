FROM ubuntu

LABEL maintainer="matisse@cpan.org"

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
       apache2 \
       libapache2-mod-perl2 \
       libmodule-build-perl \
       libapache2-authcookie-perl \
       libdbi-perl \
       libdate-calc-perl \
       libcrypt-cbc-perl

COPY ./ /var/tmp/Apache-AuthCookieDBI

RUN cd /var/tmp/Apache-AuthCookieDBI/ && \
    perl Build.PL && \
    ./Build test

WORKDIR /var/tmp/Apache-AuthCookieDBI

CMD [ "./Build", "test", "--verbose" ]
