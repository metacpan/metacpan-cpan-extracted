FROM httpd:2.2.34

ENV MOD_PERL_VERSION 2.0.11
ENV MOD_PERL_SHA256SUM ca2a9e18cdf90f9c6023e786369d5ba75e8dac292ebfea9900c29bf42dc16f74
ENV PERL_VERSION 5.28.2

ENV PATH /opt/perl-$PERL_VERSION/bin:$PATH

RUN apt-get update && \
    apt-get install -yq --no-install-recommends perl ca-certificates curl build-essential netbase && \
    curl -sfL https://raw.githubusercontent.com/tokuhirom/Perl-Build/master/perl-build | perl - $PERL_VERSION /opt/perl-$PERL_VERSION/ -Duseshrplib -j "$(nproc)" && \
    curl -sfLO http://apache.org/dist/perl/mod_perl-$MOD_PERL_VERSION.tar.gz && \
    echo "${MOD_PERL_SHA256SUM} *mod_perl-$MOD_PERL_VERSION.tar.gz" | sha256sum -c && \
    tar xzf mod_perl-$MOD_PERL_VERSION.tar.gz && \
    cd mod_perl-$MOD_PERL_VERSION && \
    /opt/perl-$PERL_VERSION/bin/perl Makefile.PL MP_NO_THREADS=1 && \
    make -j "$(nproc)" && \
    make install && \
    cd .. && \
    rm -rf mod_perl-$MOD_PERL_VERSION mod_perl-$MOD_PERL_VERSION.tar.gz && \
    apt-get autoremove -yq && \
    rm -rf /var/lib/apt/lists/*

RUN cpan App::cpanminus && \
    cpanm Apache2::AuthCookie && \
    cpanm Apache2::AuthCookieDBI && \
    rm -rf /tmp/* /root/.cpan /root/.cpanm && \
    mkdir /var/tmp/Apache-AuthCookieDBI

COPY ./ /var/tmp/Apache-AuthCookieDBI

RUN cd /var/tmp/Apache-AuthCookieDBI/ && \
    perl Build.PL && \
    ./Build test

WORKDIR /var/tmp/Apache-AuthCookieDBI

CMD [ "./Build", "test", "--verbose" ]
