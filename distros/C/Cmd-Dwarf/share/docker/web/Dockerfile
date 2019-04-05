FROM perl

RUN apt-get clean
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install postfix libsasl2-modules

# RUN postconf -e smtp_sasl_auth_enable=yes
# RUN postconf -e smtp_sasl_password_maps=static:USERNAME:PASSWORD
# RUN postconf -e smtp_sasl_security_options=noanonymous
# RUN postconf -e smtp_tls_security_level=encrypt
# RUN postconf -e header_size_limit=4096000
# RUN postconf -e relayhost=[161.202.148.160]:587 # smtp.sendgrid.net

RUN mkdir -p /data/www/<APP_NAME>/app
COPY ./app/cpanfile /data/www/<APP_NAME>/app/cpanfile
# COPY ./app/cpanfile.snapshot /data/www/<APP_NAME>/app/cpanfile.snapshot
COPY ./app/Makefile /data/www/<APP_NAME>/app/Makefile

WORKDIR /data/www/<APP_NAME>/app

RUN make carton
COPY ./app /data/www/<APP_NAME>/app
COPY ./htdocs /data/www/<APP_NAME>/htdocs

EXPOSE 11022

CMD postfix start && env PERL5LIB=local/lib/perl5 ./script/start_server.sh -c