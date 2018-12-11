# Container for building all dependencies
FROM perl:5.28-slim
MAINTAINER Jose Luis Martinez <jlmartinez@capside.com>

RUN apt-get update ; \
    apt-get install -y build-essential openssl zlib1g-dev libssl-dev ; \
    apt-get clean

COPY cpanfile /root/cpanfile
RUN cpanm -l local --no-man-pages -n --installdeps . ; rm -rf /root/.cpanm

RUN rm -rf /root/local/lib/perl5/x86_64-linux-gnu/.meta/

# Container for the command-line util
FROM perl:5.28-slim
COPY --from=0 /root/local /root/local

RUN apt-get update ; \
    apt-get install -y openssl ; \
    apt-get clean

COPY CloudHealth-CLI-0.01.tar.gz /root/CloudHealth-CLI-0.01.tar.gz
RUN cpanm -n -l local CloudHealth-CLI-0.01.tar.gz

ENV PERL5LIB /root/local/lib/perl5:/root/cloudhealth-api-perl/lib/

ENTRYPOINT [ "/root/local/bin/cloudhealth" ]
